//
//  IMSessionManager.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

 
import SwiftyJSON
#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

// 登出通知
let LCNotificationLogout: NSNotification.Name = NSNotification.Name(rawValue: "LCNotificationLogout")

// 登入页面通知
let LCNotificationGoToLoginVC: NSNotification.Name = NSNotification.Name(rawValue: "LCNotificationGoToLoginVC")

let kAuthUsernameKey: String = "auth_username";
let kAuthPasswordKey: String = "auth_password";
let kAuthUserKey: String = "auth_user";
let kMessageListKey: String = "kMessageListKey";
let kNotFriendName: String = "kNotFriendName";

class IMSessionManager: NSObject {

    var loggedIn: Bool = false // 是否登录
    var username: String?  // 用户id
    var password: String? // 用户名密码
    var userDefaults: UserDefaults?
    var currentUserProfile: IMUserProfile?
    var friendsGroup = [IMGroup]() // 好友分组数组
    var testIdGroup = [IMFriend]() //验证好友分组 (当离线时 被删除好友，会导致自己好友列表还存在好友，用于存放临时好友进行验证。)
    var statusArray = [IMFriendStatus]() // 好友在线状态数组
    var newFriendArray = [IMFriendStatus]() // 申请添加好友数组
    var isNotChatVCKeyboard = false // 键盘是否是聊天键盘
    var userAvatarURL: String!
    
//    var friendAll = [IMFriend]()
    
    // MARK: @单例
    static let sharedSessionManager: IMSessionManager  = { IMSessionManager() }()
    
    override init() { // 初始化
        super.init()

        userDefaults = UserDefaults.standard
        
        userAvatarURL = Bundle.main.infoDictionary!["IMUserAvatar"] as! String
        username = userDefaults!.string(forKey: kAuthUsernameKey)
        let pass = userDefaults!.string(forKey: kAuthPasswordKey)
        if  pass != nil {
            password = AESHelper.aes128Decrypt(pass, withKey: IMTokenManager.sharedTokenManager.getUUID())
        }
        let userProfile: Data? = userDefaults!.object(forKey: kAuthUserKey) as! Data?
        if userProfile != nil {
            currentUserProfile = NSKeyedUnarchiver.unarchiveObject(with: userProfile!) as! IMUserProfile?
        }
        loggedIn = (username != nil && password != nil)
    }
    
    // 登录
    func login(userProfile: IMUserProfile) {
        self.loggedIn = true
        self.username = userProfile.userId
        self.password = userProfile.password
        self.currentUserProfile = userProfile
        
        self.userDefaults!.set(self.username, forKey: kAuthUsernameKey)
        self.userDefaults!.set(AESHelper.aes128Encrypt(self.password, withKey: IMTokenManager.sharedTokenManager.getUUID()), forKey: kAuthPasswordKey)
        let data = NSKeyedArchiver.archivedData(withRootObject: self.currentUserProfile!)
        self.userDefaults!.set(data, forKey: kAuthUserKey)
    }
    
    // 登出
    func logout() {
        IMObjectManager.sharedObjectManager.taskToLogout(userID: IMSessionManager.sharedSessionManager.username!, token: IMTokenManager.sharedTokenManager.token).continueWith { (task) in
            if task.error != nil {
               print("登出失败")
            }else{
                print("登出成功")
            }
        }
        #if TARGET_OS_IOS
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
        #else
            let appdelegate = NSApplication.shared().delegate as! AppDelegate
        #endif
        appdelegate.isFirstLogin = true
        self.loggedIn = false
        self.username = nil
        self.password = nil
        self.currentUserProfile = nil
        IMTokenManager.sharedTokenManager.token = nil
        self.userDefaults!.removeObject(forKey: kAuthUsernameKey)
        self.userDefaults!.removeObject(forKey: kAuthPasswordKey)
        self.userDefaults!.removeObject(forKey: kAuthUserKey)
        self.userDefaults!.removeObject(forKey: kAuthToken)
        self.friendsGroup.removeAll()
        self.statusArray.removeAll()
        self.newFriendArray.removeAll()
        IMXMPPManager.sharedXmppManager.isGetAllFriends = false
        IMXMPPManager.sharedXmppManager.teardownXmppStream()
        IMXMPPManager.sharedXmppManager.loginStatus = .inLogin
        NotificationCenter.default.post(name: LCNotificationLogout, object: nil, userInfo: nil)
        NotificationCenter.default.post(name: IMNotificationTabBarItemUnreadMessage, object: nil, userInfo: ["unReadMesNum": "0"])
    }

    // 同意后得到好友的状态
    func isOnlineWithFriendId(friendId: String) -> Bool {
        if self.statusArray.isEmpty {
            return false
        }
        for item in self.statusArray {
            if item.userId == friendId {
                return item.isOnline
            }
        }
        return false
    }
    
    // 新朋友申请添加为好友
    func addNewFriend(newFriend: IMFriendStatus)->Bool {
        if self.newFriendArray.isEmpty {
            self.newFriendArray.append(newFriend)
            return true
        }
        var flag = false
        for item in self.newFriendArray {
            if newFriend.userId ==  item.userId && (newFriend.isApplyAdded == item.isApplyAdded) {
                flag = false
                break
            } else {
                flag = true
            }
        }
        if flag {
            self.newFriendArray.insert(newFriend, at: 0)
        }
        return flag
    }
    
    // 同意对方添加好友后，修改状态
    func reviseNewFriendStatus(newFriendId: String?, statusString: String?) {
        for item in self.newFriendArray {
            if newFriendId == item.userId {
                item.isApplyAdded = false
                item.applyString = statusString
                if statusString == "已拒绝"{
                    item.isFinishAdded = true
                }
                return
            }
        }
    }
    
    func finishNewFriendStatus(newFriendId: String) {
        for item in self.newFriendArray {
            if newFriendId == item.userId {
                return
            }
        }
    }
}
