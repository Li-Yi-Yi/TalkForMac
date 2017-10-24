//
//  IMObjectManager.swift
//  IM
//
//  Created by 刘表聪 on 16/11/23.
//  Copyright © 2016年 want. All rights reserved.
//

 
import Alamofire
import BoltsSwift
import SwiftyJSON

let kErrorDomain = "com.want"

/**
 *  负责一切网络通讯等工作
 */
class IMObjectManager: NSObject {
    
    private var baseURLString: String!
    private var token: String!
    // MARK: @单例
    static let sharedObjectManager: IMObjectManager  = { IMObjectManager() }()

    func baseSet() {
        self.baseURLString = Bundle.main.infoDictionary!["IMBaseURL"] as! String
//        self.baseURLString = "http://10.0.13.101:8080"
//        self.baseURLString = "http://10.0.26.229:8080"
        self.token = UserDefaults.standard.string(forKey: kAuthToken)
    }
    
    // 登录
    func taskToLogin(userID: String, password: String, deviceID: String, type: String, msgUID: String, token: String) -> Task<Dictionary<String, String>> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Dictionary<String, String>>()
        let parameters: Parameters = ["userId": userID,
                                      "pwd": password,
                                      "deviceId": deviceID,
                                      "osType": type,
                                      "msgUid": msgUID,
                                      "token": token]
        
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/login")
        let alamofire = Alamofire.SessionManager.default
        
        alamofire.session.configuration.timeoutIntervalForRequest = 5 //设置5秒超时
        alamofire.session.configuration.timeoutIntervalForResource = 5
        //alamofire.request(URLString, method: .post, parameters: parameters).responseString(completionHandler:{ (responseString) in
        //    print("\n\n Login Response: \(responseString)")
        //})
        
        alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString] )
                    completionSource.set(error: error)
                    log.error("登录 接口 ==> 失败 \(value)")
                } else {
                    let token: String = data["data"]["token"].stringValue
                    let name: String = data["data"]["name"].stringValue
                    let count: String = data["data"]["count"].stringValue
                    UserDefaults.standard.set(token, forKey: kAuthToken)
                    IMTokenManager.sharedTokenManager.token = token
                    let dic = ["name": name,"count": count]
                    log.info("登录 接口 ==> 成功")
                    completionSource.set(result: dic)
                }
                break
            case .failure(let error):
                if error._code == NSURLErrorTimedOut {
                    print("服务器连接超时")
                    let Error = NSError(domain: kErrorDomain, code: 1001, userInfo: [NSLocalizedDescriptionKey: "连接超时，请稍后重试"])
                    completionSource.set(error: Error)
                    log.error("登录 接口 ==> 失败 超时")
                    break
                }else{
                    print("服务器网络错误")
                    let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                    
                    log.error("登录 接口 ==> 失败\(error)")
                    completionSource.set(error: Error)
                    break
                }
            }
            
            
        })
        
        return completionSource.task
    }
    
    // 登出
    func taskToLogout(userID: String, token: String?) -> Task<Bool> {
        self.baseSet()
        let completionSource = TaskCompletionSource<Bool>()
        let parameters: Parameters = ["userId": userID,
                                      "token": token == nil ? "" :  token!]

        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/logout")
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    log.error("退出登录 接口 ==> 失败\(value)")
                    completionSource.set(error: error)
                } else {
                    log.info("退出登录 接口 ==> 成功")
                    completionSource.set(result: true)
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                log.error("登录 接口 ==> 失败 \(error)")
                completionSource.set(error: Error)
                break
            }
        })
        return completionSource.task
    }
    
    func LoginIsOnline(userID: String)-> Task<Bool>{ //是否在其他设备登录
        self.baseSet()
        let completionSource = TaskCompletionSource<Bool>()
        let parameters: Parameters = ["jid": userID + "@coop",
                                      "type": "text"]
        
        let URLString = "http://coop.want-want.com:9090/plugins/presence/status"
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseString(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                if value.contains("Unavailable"){//离线
                    completionSource.set(result: false)
                } else { //在线

                    completionSource.set(result: true)
                }
                log.info("外挂接口是否在其他设备登录 接口 ==>  成功 \(value)")
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                completionSource.set(error: Error)
                log.error("外挂接口是否在其他设备登录 接口 ==> 失败 \(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 根据工号和姓名查询员工
    func taskToFetchSearchFriends(name: String, id: String) -> Task<[IMFriendDetail]> {
        
        self.baseSet()
        
        let completionSource = TaskCompletionSource<[IMFriendDetail]>()

        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/getEmpList")
        let parameters: Parameters = ["empName": name, "empId": id, "token": self.token!]
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    log.error("根据工号和姓名查询员工 接口 ==> 失败 \(value)")
                    completionSource.set(error: error)
                } else {
                    let array = data["data"]["empList"].arrayValue
                    var friends = [IMFriendDetail]()
                    for item in array {
                        let friendDetail = IMFriendDetail(name: item["empName"].stringValue, id: item["empId"].stringValue, orgnization: item["orgName"].stringValue)
                        friends.append(friendDetail)
                    }
                    log.info("根据工号和姓名查询员工 接口 ==> 成功")
                    completionSource.set(result: friends)
                }
            case .failure(let error):
                 let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                log.error("根据工号和姓名查询员工 接口 ==> 失败 \(error)")
                completionSource.set(error: Error)
                break
            }
        })
        return completionSource.task
    }
    
    // 员工详情
    func taskToFetchFriendDetail(id: String) -> Task<[IMFriendDetail]> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<[IMFriendDetail]>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/getEmpInfo")
        let parameters: Parameters = ["userId": id, "token": self.token!]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("员工详情 接口 ==> 失败 \(value)")
                } else {
                    if data["data"].arrayValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无该员工信息"])
                        completionSource.set(error: error)
                        log.error("员工详情 接口 ==> 失败 \(value) 无该员工消息")
                    } else {
                        let deatils = data["data"].arrayValue.map({ (friendDetail) -> IMFriendDetail in
                            return IMFriendDetail(name: friendDetail["empName"].stringValue, id: friendDetail["empId"].stringValue, position: friendDetail["jobName"].stringValue, post: friendDetail["posName"].stringValue, phoneNumber: friendDetail["empPhoneExt"].stringValue, charge: friendDetail["directorEmpName"].stringValue, orgnization: friendDetail["orgName"].stringValue, email: friendDetail["empEmail"].stringValue, gender: friendDetail["empGender"].stringValue)
                        })
                        completionSource.set(result: deatils)
                        log.info("员工详情 接口 ==> 成功")
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(002)"])
                completionSource.set(error: Error)
                log.error("员工详情 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 员工详情
//    func taskToFetchFriendDetail(id: String) -> Task<IMFriendDetail> {
//        self.baseSet()
//        
//        let completionSource = TaskCompletionSource<IMFriendDetail>()
//        
//        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/getEmpInfo")
//        let parameters: Parameters = ["empId": id, "token": self.token!]
//        
//        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
//            switch response.result {
//            case .success(let value):
//                let data = JSON(value)
//                if  data["code"].intValue != 0 {
//                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
//                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
//                    completionSource.set(error: error)
//                    log.error("员工详情 接口 ==> 失败 \(value)")
//                } else {
//                    if data["data"].dictionaryValue.isEmpty {
//                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无该员工信息"])
//                        completionSource.set(error: error)
//                        log.error("员工详情 接口 ==> 失败 \(value) 无该员工消息")
//                    } else {
//                        let friend = IMFriendDetail(name: data["data"]["empName"].stringValue, id: data["data"]["empId"].stringValue, position: data["data"]["jobName"].stringValue, post: data["data"]["posName"].stringValue, phoneNumber: data["data"]["empPhoneExt"].stringValue, charge: data["data"]["directorEmpName"].stringValue, orgnization: data["data"]["orgName"].stringValue, email: data["data"]["empEmail"].stringValue, gender: data["data"]["empGender"].stringValue)
//                        completionSource.set(result: friend)
//                        log.info("员工详情 接口 ==> 成功")
//                    }
//                }
//                break
//            case .failure(let error):
//                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(002)"])
//                completionSource.set(error: Error)
//                log.error("员工详情 接口 ==> 失败\(error)")
//                break
//            }
//        })
//        return completionSource.task
//    }
    
    //员工性别
    func taskToFetchFriendGender(id: String) -> Task<String> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<String>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/getGender")
        let parameters: Parameters = ["userIdList": id, "token": self.token!]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("员工性别 接口 ==> 失败 \(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        completionSource.set(result: "1") //默认显示旺仔
                        log.error("员工性别 接口 ==> 成功  无该员工消息(离职人员)")
                    } else {
                        let gender = data["data"].dictionaryValue[id]?.stringValue
                        completionSource.set(result: gender!)
                        log.info("员工性别 接口 ==> 成功")
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(002)"])
                completionSource.set(error: Error)
                log.error("员工性别 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    
    // 通知推送
    func taskToPushMessage(userID: String, message: String) -> Task<Bool> {
        self.baseSet()

        let completionSource = TaskCompletionSource<Bool>()
        
        var contentArray = [Any!]()
        contentArray.append(["userId": userID, "title": "你有新信息","msg": message, "customField": ["userFrom": IMSessionManager.sharedSessionManager.username!, "silentPush":"1"]])
        
        let dict = ["pushKey": "imMsg",
                    "contents": contentArray] as [String : Any]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let jsonString: String = String(data: jsonData, encoding: .utf8)!
        let parameters: Parameters = ["params": jsonString,
                                      "wmbWord": "wantW@NT"]
        let URLString = self.baseURLString + ("/IMMobi/bdm/sendNotification")
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("通知推送 接口 ==> 失败\(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "push消息失败"])
                        completionSource.set(error: error)
                        log.error("通知推送 接口 ==> 失败\(value)")
                    } else {
                        completionSource.set(result: true)
                        log.info("通知推送 接口 ==> 成功")
                    }
                }
                break
            case .failure(let error):
                print(response)
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                completionSource.set(error: Error)
                log.error("通知推送 接口 ==> 失败 \(error)")
                break
            }
        })
        return completionSource.task
    }

    // 群聊通知推送
    func taskToPushRoomMessage(membersID: [String], message: String, title: String, pushKey: String, silentPush: Bool) -> Task<Bool> {
        self.baseSet()
        let completionSource = TaskCompletionSource<Bool>()
        
        let silent = silentPush == true ? "1" : "0"

        var contentArray = [Any!]()
        for memberId in membersID {
            contentArray.append(["userId": memberId,"title": title, "msg": message, "customField": ["userFrom": IMSessionManager.sharedSessionManager.username!, "silentPush":silent]])
        }
        let dict = ["pushKey": pushKey,
                    "contents": contentArray] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let jsonString: String = String(data: jsonData, encoding: .utf8)!
        let parameters: Parameters = ["params": jsonString,
                                      "wmbWord": "wantW@NT"]
        let URLString = self.baseURLString + ("/IMMobi/bdm/sendNotification")
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("群聊通知推送 接口 ==> 失败 \(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "push消息失败"])
                        log.error("群聊通知推送 接口 ==> 失败 \(value)")
                        completionSource.set(error: error)
                    } else {
                        log.info("群聊通知推送 接口 ==> 成功")
                        completionSource.set(result: true)
                    }
                }
                break
            case .failure(let error):
                print(response)
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                log.error("群聊通知推送 接口 ==> 失败 \(error)")
                completionSource.set(error: Error)
                break
            }
        })
        return completionSource.task
    }
    
    // 添加好友推送
    func taskToPushAddFriend(userID: String, message: String) -> Task<Bool> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Bool>()
        
        let dict = ["pushKey": "addFriend",
                    "contents": [["userId": userID, "title": "你有新信息", "msg": message, "customField": ["userFrom": IMSessionManager.sharedSessionManager.username!]]]] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let jsonString: String = String(data: jsonData, encoding: .utf8)!
        let parameters: Parameters = ["params": jsonString,
                                      "wmbWord": "wantW@NT"]
        let URLString = self.baseURLString + ("/IMMobi/bdm/sendNotification")
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("添加好友推送 接口 ==> 失败 \(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "push消息失败"])
                        completionSource.set(error: error)
                        log.error("添加好友推送 接口 ==> 失败 \(value)")
                    } else {
                        log.info("添加好友推送 接口 ==> 成功")
                        completionSource.set(result: true)
                    }
                }
                break
            case .failure( _):
                print(response)
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                completionSource.set(error: Error)
                log.error("添加好友推送 接口 ==> 失败")
                break
            }
        })
        return completionSource.task
    }
    
    // 進入群聊
    func taskToJoinGroupChat(userID: String, roomJID: String, nickName: String, token: String) -> Task<Bool> {
        self.baseSet()
        let lowerRoomId = roomJID.lowercased()
        let completionSource = TaskCompletionSource<Bool>()
        let parameters: Parameters = ["userId": userID,
                                      "roomId": lowerRoomId,
                                      "userChatName":nickName,
                                      "token": token]
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/groupChat/login")
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: data["msg"].stringValue])
                    completionSource.set(error: error)
                    log.error("進入群聊 接口 ==> 失败 \(value)")
                    
                } else {
                    log.info("進入群聊 接口 ==> 成功")
                    completionSource.set(result: true)
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "系统异常"])
                completionSource.set(error: Error)
                log.error("進入群聊 接口 ==> 失败 \(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 离开群聊
    func taskToLeaveGroupChat(userID: String, roomJID: String, token: String) -> Task<Bool> {
        self.baseSet()
        let lowerRoomId = roomJID.lowercased()
        let completionSource = TaskCompletionSource<Bool>()
        let parameters: Parameters = ["userId": userID,
                                      "roomId": lowerRoomId,
                                      "token": token]
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/groupChat/logout")
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: data["msg"].stringValue])
                    log.error("离开群聊 接口 ==> 失败 \(value)")
                    completionSource.set(error: error)
                } else {
                    log.info("离开群聊 接口 ==> 成功")
                    completionSource.set(result: true)
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "系统异常"])
                completionSource.set(error: Error)
                log.error("离开群聊 接口 ==> 失败 \(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 取得群列表 
    func taskToFetchGroupChatList(id: String) -> Task<Dictionary<String, JSON>> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Dictionary<String, JSON>>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/groupChat/getChatRooms2")
        let parameters: Parameters = ["userId": id,
                                      "token": token]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                //print("data === \(data)")
                if  data["code"].intValue != 0 {
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: data["msg"].stringValue])
                    completionSource.set(error: error)
                    log.error("取得群列表 接口 ==> 失败 \(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无参加群"])
                        log.error("取得群列表 接口 ==> 失败 \(value)")
                        completionSource.set(error: error)
                    } else {
//                        let interval = Int(data["data"]["offlineInterval"].stringValue)!/1000
//                        print("fetch Interval=================\(interval)")
//                        IMXMPPManager.sharedXmppManager.offlineInterval = interval
                        let array: [String : JSON] = data["data"]["roomIdList"].dictionaryValue
                        log.info("取得群列表 接口 ==> 成功")
                        completionSource.set(result: array)
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "系统异常"])
                log.error("取得群列表 接口 ==> 失败 \(error)")
                completionSource.set(error: Error)
                
                break
            }
        })
        return completionSource.task
    }
    
    // 取得群名單
    func taskToFetchGroupChatMembers(roomId: String) -> Task<[JSON]> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<[JSON]>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/groupChat/getChatUsers")
        let parameters: Parameters = ["roomId": roomId,
                                      "token": token]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                //print("data = \(data)")
                if  data["code"].intValue != 0 {
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: data["msg"].stringValue])
                    completionSource.set(error: error)
                    log.error("取得群名單 接口 ==> 失败 \(value)")
                } else {
                    
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无参加群"])
                        log.error("取得群名單 接口 ==> 失败 \(value)")
                        completionSource.set(error: error)
                    } else {
                        log.info("取得群名單 接口 ==> 成功")
                        let array = data["data"]["userList"].arrayValue
                        completionSource.set(result: array)
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络异常"])
                completionSource.set(error: Error)
                log.error("取得群名單 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }

    // 登錄離線時間
    func taskToWriteOnChangeTime(roomId: String) -> Task<Bool> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Bool>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/groupChat/writeOnChangeTime")

        var userName: String
        if IMSessionManager.sharedSessionManager.username != nil {
            userName = IMSessionManager.sharedSessionManager.username!
        }else{
            userName = ""
        }
        
        let parameters: Parameters = ["userId": userName,
                                      "roomId": roomId,
                                      "token": token]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                //print("data = \(data)")
                if  data["code"].intValue != 0 {
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: data["msg"].stringValue])
                    completionSource.set(error: error)
                    log.error("登錄離線時間 接口 ==> 失败\(value)")
                } else {
                    
                    if !data["data"].boolValue {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无参加群"])
                        log.error("登錄離線時間 接口 ==> 失败\(value)")
                        completionSource.set(error: error)
                    } else {
                        completionSource.set(result: data["data"].boolValue)
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "系统异常"])
                completionSource.set(error: Error)
                log.error("登錄離線時間 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 取得裝置類型(OSType)
    func taskToGetOSTypeFromId(userId :String) -> Task<Bool> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Bool>()
                
        let URLString = "http://coop.want-want.com:9090/plugins/presence/status"
        
        let parameters: Parameters = ["jid": userId+"@coop", "type": "text"]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseString(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                if value.contains("??"){//PC登录中不可以邀请
                    log.error("取得裝置類型(OSType) 接口 ==> 失败\(value)")
                    completionSource.set(result: false)
                } else { //可以邀请
                    log.info("取得裝置類型(OSType) 接口 ==> 成功")
                    completionSource.set(result: true)
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "系统异常"])
                completionSource.set(error: Error)
                log.error("取得裝置類型(OSType) 接口 ==> 失败\(error)")

                break
            }
        })
        return completionSource.task
    }

    // 检查版本更新
    func taskToCheckVersion(userId: String, envType: String) -> Task<IMVersion> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<IMVersion>()
        let URLString = self.baseURLString + ("/IMMobi/bdm/getVersion")
        let parameters: Parameters = ["osType": "iOS", "envType": envType, "userId": userId, "wmbWord": "wantW@NT"]
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("检查版本更新 接口 ==> 失败  \(value)")
                } else {
                    
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "无该员工信息"])
                         log.error("检查版本更新 接口 ==> 失败  \(value)")
                        completionSource.set(error: error)
                    } else {
                        
                        let downURL: String = data["data"]["downloadUrl"].stringValue
                        let version: String = data["data"]["version"].stringValue
                        let versionModel = IMVersion(version: version, url: downURL)
                        completionSource.set(result: versionModel)
                    }
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                completionSource.set(error: Error)
                log.error("检查版本更新 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 查询组织树
    func taskToFetchOrgnization(orgId: String, orgName: String) -> Task<[IMOrgnization]> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<[IMOrgnization]>()
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/getOrgTree")
        
        let parameters: Parameters = ["orgId": orgId, "orgName": orgName, "token": self.token];
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if  data["code"].intValue != 0 {
                    let errorString = (data["msg"].stringValue == "验证无效") ? "网络错误，请稍后重试(001)" : data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("查询组织树 接口 ==> 失败\(value)")
                } else {
                    let empListArray = data["data"]["empList"].arrayValue
                    let orgListArray = data["data"]["orgList"].arrayValue
                    var orgnizations = [IMOrgnization]()
                    for item in empListArray {
                        let employee = IMOrgnization(name: item["empName"].stringValue, id: item["empId"].stringValue, orgnization: "")
                        orgnizations.append(employee)
                    }
                    for item in orgListArray {
                        if item["orgId"].stringValue == "00000000" || item["orgName"].stringValue == "空部门" {
                            continue
                        }
                        let orgnization = IMOrgnization(department: item["orgName"].stringValue, departmentId: item["orgId"].stringValue)
                        orgnizations.append(orgnization)
                    }
                    log.info("查询组织树 接口 ==> 成功")
                    completionSource.set(result: orgnizations)
                }

                break
            case .failure(_):
                let error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey : "网络错误，请稍后重试(001)"])
                completionSource.set(error: error)
                log.error("查询组织树 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    /// 文件转换oid
    ///
    /// - Parameters:
    ///   - senderId: 发送方userid
    ///   - receiverId: 接收方userid
    ///   - fileName: 文件名
    ///   - token: pushtoken
    /// - Returns: 返回结果集
    func getFileByOid(senderId: String,receiverId: String, fileName: String) -> Task<IMOidModel> {
        self.baseSet()
        let completionSource = TaskCompletionSource<IMOidModel>()
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/setFileName")
        let parameters: Parameters = ["sender": senderId, "receiver": receiverId, "fileName": fileName, "token": self.token]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: {(response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if data["code"].intValue != 0 {
                    let errorString = "转换失败"
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("文件转换oid 接口 ==> 失败\(value)")
                } else {
                    if data["data"].dictionaryValue.isEmpty {
                        let error = NSError(domain: kErrorDomain, code: 11111, userInfo: [NSLocalizedDescriptionKey: "转换失败"])
                        completionSource.set(error: error)
                        log.error("文件转换oid 接口 ==> 失败\(value)")
                    } else {
                        let oid: String = data["data"]["oid"].stringValue
                        let oidModel = IMOidModel(oid: oid)
                        completionSource.set(result: oidModel)
                    }
                }
                break
            case .failure(let error):
                print("\(error)")
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(001)"])
                completionSource.set(error: Error)
                 log.error("文件转换oid 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
    
    // 清理未读数
    func taskToClearUnread(id: String,count: Int) -> Task<Bool> {
        self.baseSet()
        
        let completionSource = TaskCompletionSource<Bool>()
        
        let URLString = self.baseURLString + ("/IMMobi/iwm/userInfo/clearUnread")
        let parameters: Parameters = ["userId": id, "token": self.token!,"count": "\(count)"]
        
        Alamofire.request(URLString, method: .post, parameters: parameters).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                
                if  data["code"].intValue != 0 {
                    let errorString = data["msg"].stringValue
                    let error = NSError(domain: kErrorDomain, code: Int(data["code"].stringValue)!, userInfo: [NSLocalizedDescriptionKey: errorString])
                    completionSource.set(error: error)
                    log.error("清理未读数 接口 ==> 失败 \(value)")
                } else {
                    log.info("清理未读数 接口 ==> 成功")
                }
                break
            case .failure(let error):
                let Error = NSError(domain: kErrorDomain, code: 999, userInfo: [NSLocalizedDescriptionKey: "网络错误，请稍后重试(002)"])
                completionSource.set(error: Error)
                log.error("清理未读数 接口 ==> 失败\(error)")
                break
            }
        })
        return completionSource.task
    }
}

extension SessionManager{
    class func timOut5SessionManager() -> SessionManager{
        let defaultTimeOut5: SessionManager = {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
            configuration.timeoutIntervalForRequest = 5
            return SessionManager(configuration: configuration)
        }()
        return defaultTimeOut5
    }
    
}


