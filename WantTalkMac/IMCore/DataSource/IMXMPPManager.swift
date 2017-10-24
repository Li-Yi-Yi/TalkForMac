//
//  IMXMPPManager.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

// 
import Dollar
import SwiftyJSON
import Kingfisher
import RealmSwift
import Zip
import XMPPFramework

//import Crashlytics

let SERVER: String = Bundle.main.infoDictionary!["IMXMPPServer"] as! String
let kDomain: String = "coop"
let kShowNewFriendTip: String = "kShowNewFriendTip"
typealias updateBlock = ()->()
typealias updateNewFriendBlock = ()->()
typealias showTipBlock = ()->()
typealias failBlock = (String?)->()
typealias sucessBlock = (IMUserProfile)->()
typealias receiveMsgBlock = (String)->()
typealias groupRefreshBlock = ()->()
typealias notificationBlock = ()->()

typealias sucessLoginedBlock = ()->()
typealias backLoginedBlock = ()->()

// 日记
let kJournalFlag: String = " journal"

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if TARGET_OS_IOS            
            #if arch(i386) || arch(x86_64)
                isSim = true
            #endif
        #endif
        
        return isSim
    }()
}

enum AlertViewTag: Int {
    case roomInvition = 101
}

enum IMConnectionStatus: Int{
    case timeOut = -5
}

enum IMLoginStatus: Int{  //当前登录状态
    case inLogin = 1  //登录界面登录
    case inAutoLogin = 3 //自动登录
    case inBackground = 5 //后台返回进行连接
}

@objc protocol IMChatDelegate {
    @objc optional func newBuddyOnline(buddyName: String) -> Void
    @objc optional func buddyWentOffLine(buddyName: String) -> Void
    @objc optional func deleteBuddy(buddyName: String) -> Void
    @objc optional func didDisconnect() -> Void
}

@objc protocol IMMessageDelegate {
    @objc optional func newMessageReceived(message: IMChat?, isSingleChat: Bool) -> Void
}
@objc protocol IMRoomMessageDelegate {
    @objc optional func newRoomMessageReceived(message: IMChat?, isGroupChat: Bool) -> Void
    @objc optional func roomMessageDidSend(roomId: String!, message: String!) -> Void
}

@objc protocol IMMessagListDelegate {
    @objc optional func updateMessageListReceived() -> Void
}

protocol IMStreamConnectDelegate : NSObjectProtocol{
    func streamConnectChanged(_ status: IMConnectionStatus) -> Void
}

protocol IMXMPPManagerMUCDelegate : NSObjectProtocol{
    func didUpdateRoomList(ServiceName: String?, rooms: [IMRoom]?) -> Void
    func didUpdateRoomLisFail() -> Void
    func didUpdateServerFail() -> Void
}

protocol IMRoomDelegate : NSObjectProtocol{
    func didJoinRoom(room: IMRoom) -> Void
    func didLeaveRoom(room: IMRoom) -> Void
    func didUpdateRoom() -> Void
}
class IMXMPPManager: NSObject, XMPPStreamDelegate, XMPPRosterDelegate,/*UIAlertViewDelegate,*/XMPPReconnectDelegate, XMPPRoomDelegate, XMPPMUCDelegate {
    /**
     *  流
     */
    var xmppStream: XMPPStream?
    
    /**
     *  好友花名册
     */
    var xmppRoster: XMPPRoster?
    var rosterStorage: XMPPRosterCoreDataStorage?
    
    /**
     *  断开网络，自动连接
     */
    var xmppReconnect: XMPPReconnect?
    
    /**
     *  心跳机制
     */
    
    var reconnectCuont: Int = 0 //重连次数
    var pingTimeoutCount: Int = 0 //ping超时次数
    var xmppAutoPing: XMPPAutoPing?
    private var reconnectTimer: DispatchSourceTimer?
    
    
    /**
     *  消息归档
     */
    var messageArchiving: XMPPMessageArchiving?
    var managedObjectContext: NSManagedObjectContext?
    var messageStorage: XMPPMessageArchivingCoreDataStorage?
    
    /**
     *  协议
     */
    weak var chatDelegate: IMChatDelegate?
    weak var messageDelegate: IMMessageDelegate?
    weak var messageListDelegate: IMMessagListDelegate?
    weak var roomMessageDelegate: IMRoomMessageDelegate?
    weak var streamConnectDelegate: IMStreamConnectDelegate?
    
    /**
     *  用户名
     */
    var username: String?
    
    /**
     *  密码
     */
    var password: String?
    
    /**
     *  用户名的中文名字
     */
    var userChineseName: String?
    
    /**
     *  PC 删除好友
     */
    var pcDeleteFriendName: String?
    
    /**
     *  登录失败回调
     */
    var failHandler: failBlock?
    
    /**
     *  登录成功回调
     */
    var successHandler: sucessBlock?
    
    /**
     *  成功登陆后的回调
     */
    var sucessLoginedHandle: sucessLoginedBlock?
    
    
    /**
     *  后台返回重新登录的回调
     */
    var backLoginHandle: backLoginedBlock?
    
    /**
     *  登录后好友的状态状态发生变化
     */
    var updateHandler: updateBlock?
    
    /**
     *  有好友申请刷新好友列表
     */
    var updateNewFriendListHandler: updateNewFriendBlock?
    
    /**
     *  有好友申请刷新提示View
     */
    var showTipHandler: showTipBlock?
    
    /**
     *  从后台返回前台时、或者第一次登录时，显示正在加载。。。
     */
    var receiveHandler: receiveMsgBlock?
 
    /**
     *  从后台返回前台时、或者第一次登录时，显示正在加载。。。
     */
    var invitationHandler: notificationBlock?
    
    /**
     *  群聊成员离开或加入时更新群列表
     */
    var groupRefreshHandler: groupRefreshBlock?
    //已经在邀请页面(防止在邀请页面两次点击导致没有返回按钮)
    var isOnAddFriend = false
    
    /**
     *  判断是否添加好友
     */
    var isAgreeApplied = false
    
    /**
     *  判断是否添加好友，刷新好友在线
     */
    var isAgreeAppliedUpdateOnline = false
    
    /**
     *  断开网络自动连接
     */
    var noNetWork = false
    
    
    //
    var loginStatus = IMLoginStatus.inLogin //默认为登录页进行登录
    
    
    /**
     *  是否开着stream
     */
    var isOpen: Bool = false
    
    var presence: XMPPPresence?
    
    /**
     *  是否已经获取好友列表
     */
    var isGetAllFriends = false
    
    /**
     *  是否是移动分组
     */
    var isMovingGroup = false
    
    /**
     *  当前移动的 friend
     */
    var currentMovingFriend: IMFriend?
    
    /**
     *  当前移动的分组
     */
    var currentMovingGroup = [IMFriend]()
    
    /**
     *  是否从后台进入前台
     */
    var isLoginedBackground: Bool = false
    
    //单聊的消息队列
    let messageQueue = DispatchQueue(label: "com.donwloadFile.com")
    let downImageQueue = DispatchQueue(label: "com.downImage.com", qos: .default)
    
    //群聊的消息队列
    let messageMUCQueue = DispatchQueue(label: "com.MucDonwloadFile.com")
    
    /**
     *  群聊
     */
    var xmppMUC = XMPPMUC(dispatchQueue: DispatchQueue.main)
    var roomList = [String]()
    var currentActiveRooms = [XMPPRoom]()
    let timeStampFormat: DateFormatter = DateFormatter()
    var offlineInterval: Int = 0
    
    /**
     *  Delegate
     */
    weak var mucDelegate: IMXMPPManagerMUCDelegate?
    weak var roomDelegate: IMRoomDelegate?
    
    lazy var sessionManager: IMSessionManager = {
        let session = IMSessionManager.sharedSessionManager
        return session
    }()
    
    // MARK: 单例
    static let sharedXmppManager: IMXMPPManager = { IMXMPPManager() }()
    
    lazy var friendsManager: IMFriendsManager = {
        let session = IMFriendsManager.sharedFriendManager
        return session
    }()
    
    // 登录方法
    func loginWithuserName(userName: String?, password: String?, isLogined: Bool)  {
        guard let _ = userName else {
            return
        }
        IMXCGLoggerManager.sharedLogManager.logInstall(id: userName!)
        // !! IMProgressHUD.im_showWithStatus(string: nil)
        self.username = userName
        self.password = password
        
        let apnsToken: String;
        if Platform.isSimulator {
            apnsToken = "IPHONE_SIMULATOR";
        } else {
            apnsToken = (UserDefaults.standard.string(forKey: kAPNSToken) != nil) ? UserDefaults.standard.string(forKey: kAPNSToken)! : "NaN"
        }
        
        let date  = Date()
        // 登录Push接口
        IMObjectManager.sharedObjectManager.taskToLogin(userID: self.username!, password: self.password!, deviceID: IMTokenManager.sharedTokenManager.getUUID(), type: "macOS", msgUID: apnsToken, token: "").continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            
            let timeInterval = Date().timeIntervalSince(date)
            var timeIntervalStr = "\(Date().description)：\(timeInterval)"
            
            if task.error != nil {
                strongSelf.userChineseName = strongSelf.username
                // !! IMProgressHUD.im_showWarningWithStatus(string: (task.error!.localizedDescription))
                if isLogined { // 退出
                    strongSelf.sessionManager.logout()
                }
            } else {
                strongSelf.userChineseName = task.result?["name"]
                // 连接
                if !strongSelf.connect() {
                
                    //_ = UIApplication.shared.keyWindow!.rootViewController!.taskToShowPrompt(prompt: "服务器连接失败")
                    // !! IMProgressHUD.im_showWarningWithStatus(string: "openfile服务器连接失败")
                    
                    log.error("openfile服务器连接失败")
                }
                
                log.info("openfile连接成功")
                //UMSAgent.bindUserIdentifier(strongSelf.username!)
                //压缩文档
                let path = IMZipManager.sharedZipManager.zipLogFil(userId: strongSelf.username!)
                guard let _ = path else{
                    return
                }
                
                //连接日志ftp
                if (task.result?["count"]) == "1"{
                    let ftpStatusTure = IMUpLoadFileManager.sharedFileManager.checkLogFtpStatus()
                    let isUpFile = IMUpLoadFileManager.sharedFileManager.uploadFile(fileName: path!.components(separatedBy: "/").last!, filePath: path!)
                    if ftpStatusTure == true && isUpFile == true{
                        IMZipManager.sharedZipManager.deleteUnTadayLog()
                        IMZipManager.sharedZipManager.deleteZipFile()
                    }else{
                        IMZipManager.sharedZipManager.deleteZipFile()
                    }
                }
            }
            
            if timeInterval > 5 { // 网络超过5秒 存入本地日记中，做记录
                // 内网10.1.0.125 // 外网 210.22.188.74
                if IMTokenManager.sharedTokenManager.getIPAddressFromDNSQuery(url: "push.want-want.com") != nil { // 得到DNSQuery 的 IP 地址
                    timeIntervalStr = "\(IMTokenManager.sharedTokenManager.getIPAddressFromDNSQuery(url: "push.want-want.com")!)\(timeIntervalStr)"
                } else  {
                    timeIntervalStr = "没有连网\(timeIntervalStr)"
                }
                
                var journalArray = UserDefaults.standard.array(forKey: kJournalFlag)
                if journalArray != nil {
                    if journalArray!.count > 10 {
                        journalArray!.remove(at: 0)
                    }
                    journalArray!.append(timeIntervalStr)
                } else {
                    journalArray = Array(arrayLiteral: timeIntervalStr)
                }
                
                UserDefaults.standard.set(journalArray, forKey: kJournalFlag)
            }
        }
    }
    
    // 设置
    private func setupStream() -> Void {
        self.xmppStream = XMPPStream()
        #if TARGET_OS_IPHONE
        self.xmppStream!.enableBackgroundingOnSocket = true
        #endif
        xmppStream!.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.rosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
        // 初始化好友列表
        self.xmppRoster = XMPPRoster(rosterStorage: rosterStorage, dispatchQueue: DispatchQueue.main)
        // 将好友列表在通道上激活
        self.xmppRoster!.activate(self.xmppStream)
        self.xmppRoster!.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster!.autoAcceptKnownPresenceSubscriptionRequests = true
        self.messageStorage = XMPPMessageArchivingCoreDataStorage.sharedInstance()
        
        // 初始化消息归档对象
        self.messageArchiving = XMPPMessageArchiving(messageArchivingStorage: messageStorage, dispatchQueue: DispatchQueue.main)
        // 激活
        self.messageArchiving!.activate(self.xmppStream)
        // 被管理对象上下文 存成属性 方便使用
        self.managedObjectContext = self.messageStorage!.mainThreadManagedObjectContext;
        
        // autoReconnect 自动连接，当网路被断开了，自动连接上去，并且将上一次信息加上去
        self.xmppReconnect = XMPPReconnect()
        self.xmppReconnect!.activate(self.xmppStream!)
        self.xmppReconnect!.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //心跳机制
        self.xmppAutoPing = XMPPAutoPing()
        self.xmppAutoPing?.pingInterval = 20.0 //频率20s
        self.xmppAutoPing?.respondsToQueries = true
        self.xmppAutoPing?.activate(self.xmppStream)
        self.xmppAutoPing?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //設置群聊
        self.activeXMPPMUC()
        self.timeStampFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    }
    
    // 上线
    private func goOnline() -> Void {
        // 生成状态元素
        let presence: XMPPPresence = XMPPPresence(type: "available")
        self.xmppStream!.send(presence)
    }
    
    // 下线
    private func goOffline() -> Void {
        let presence: XMPPPresence = XMPPPresence(type: "unavailable")
        self.xmppStream?.send(presence)
    }
    
    // MARK: 连接
    // 是否连接
    func connect() -> Bool {
        if (self.xmppStream == nil) {
            self.setupStream()
        }
        guard self.username != nil && self.password != nil else {
            return false
        }
        if (self.username!.isEmpty || self.password!.isEmpty ) {
            return false
        }
        
        // 从本地取得用户名， 密码和服务器地址
        if (self.xmppStream!.isConnected() || self.xmppStream!.isConnecting()) {
            // 断开
            self.disconnect()
        }
        
        //设置用户
        let myJid: XMPPJID = XMPPJID(user: self.username, domain: kDomain, resource: "WantTalk")
        self.xmppStream!.myJID = myJid;
        //设置服务器
        self.xmppStream!.hostName = SERVER;
        //连接服务器
        do {
            try self.xmppStream!.connect(withTimeout: 5)
            print("Connection success")
            return true
        } catch let error {
            print("\(error) :connection is fail----------")
            log.error("\(error)")
            return false
        }
    }
    
    // 断开连接
    func disconnect() -> Void {
        self.goOffline()
        self.xmppStream?.disconnect()
    }
    
    // MARK: XMPPStreamDelegate
    // 断开连接成功
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) -> Void {
        print("-----------xmppStreamDidDisconnect")
        
        if self.noNetWork{
            self.xmppReconnect?.manualStart()
            self.noNetWork = false
        }
        #if TARGET_OS_IOS
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        #else
        let appdelegate = NSApplication.shared().delegate as! AppDelegate
        #endif
        guard appdelegate.isFirstLogin == true else{
            return
        }
        
        switch self.loginStatus {
        case .inLogin:
            // !! IMProgressHUD.im_showWarningWithStatus(string: "openfile连接失败")
            log.debug("手动登录openfile连接失败")
            return
        case .inAutoLogin:
            // !! IMProgressHUD.im_showWarningWithStatus(string: "openfile连接失败")
            log.debug("自动登录openfile连接失败")
            self.streamConnectDelegate?.streamConnectChanged(IMConnectionStatus.timeOut)
            return
        default:
            return
        }
    }
    
    func xmppStreamWasTold(toDisconnect sender: XMPPStream!) {
        print("-----------xmppStreamWasToldtoDisconnect")
    }
    
    // 连接超时
    func xmppStreamConnectDidTimeout(_ sender: XMPPStream) -> Void {
        // !! IMProgressHUD.im_showWarningWithStatus(string: "openfile连接超时")
        log.debug("openfile连接超时")
        if !self.sessionManager.loggedIn {
            self.streamConnectDelegate?.streamConnectChanged(IMConnectionStatus.timeOut)
        }
    }
    
    // 连接服务器
    func xmppStreamDidConnect(_ sender: XMPPStream) -> Void {
        self.isOpen = true
        //验证密码
        do {
            try self.xmppStream!.authenticate(withPassword: self.password)
        } catch let error {
            print("\(error) :connection is fail----------")
            log.debug("\(error) :connection is fail----------")
        }
    }
    
    // 验证通过
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) -> Void {
        self.successHandler?(IMUserProfile(id: self.username, password: self.password))
        // 登錄Crashlytics使用者身份
        #if TARGET_OS_IOS
            let appdelegate = UIApplication.shared.delegate as? AppDelegate
        #else
            let appdelegate = NSApplication.shared().delegate as? AppDelegate
        #endif
        //验证密码成功,进行判断是否在其他设备登录(只在 登录界面、自动登录 登录成功执行)
        if appdelegate?.isFirstLogin == true{
            IMObjectManager.sharedObjectManager.LoginIsOnline(userID: self.username!).continueWith{ [weak self, weak appdelegate] (task) in
                guard let strongSelf = self else { return }
                guard let app = appdelegate else { return }
                if task.error != nil {
                } else {
                    if task.result == true{
                        // 判斷是否是主動斷線
                        strongSelf.disconnect()
                        strongSelf.xmppReconnect?.manualStart() //手动启动重连
                    }else{
                        strongSelf.goOnline()
                        //查詢所有群
                        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: "\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)+lastLoginDate")
                        strongSelf.fetchGroupChatList()
                    }
                }
                app.isFirstLogin = false
            }
        }else{
            self.goOnline()
            //查詢所有群
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: "\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)+lastLoginDate")
            self.fetchGroupChatList()
        }
    }
    
    // 验证不通过
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: XMLElement) -> Void {
        print(error.description)
        // !! IMProgressHUD.im_showWarningWithStatus(string: "用户名或密码错误")
        if self.failHandler != nil {
            self.failHandler!("用户名或密码错误")
        }
    }
    
    // 收到的一个错误信息
    func xmppStream(_ sender: XMPPStream!, didReceiveError error: XMLElement!) {
        for node in error.children! {
            if node.name == "conflict" {
            }
        }
    }
    
    // 收到好友状态
    func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        // 取得好友状态
        let presenceType = presence.type()
        // 当前用户
        let userId = sender.myJID.user
        // 在线用户
        
        guard let presenceFromUser = presence.from()?.user, presenceFromUser != "" else {
            return
        }
        
        if (!(presenceFromUser == userId)) {
            // 在线状态
            if presenceType == "unavailable" || presenceType == "available"{
            }else if presenceType == "unsubscribe"{
                self.xmppRoster?.removeUser(presence.from())
            }else{
            }
        }
    }
    
    func xmppStream(_ sender: XMPPStream!, willReceive message: XMPPMessage!) -> XMPPMessage! {
        //开始旋转
        self.receiveHandler?("1")
        print(message)
        return message
    }
    
    // MARK: XMPPMesageDelegate
    // 收到消息
    func xmppStream(_ sender: XMPPStream, didReceive message:XMPPMessage) -> Void {
        if let type: String = message.attribute(forName: "type")?.stringValue{
            if type == "groupchat"{ return }
        }
        //        <message xmlns="jabber:client" type="chat" to="00320559@coop" from="00316406@coop/WantTalk"><body>22</body></message>
        var dstPath = ""
        var fileNameoid = ""
        var fileName: String!
        var fileoid: String!
        var fileSize: Float!
        var chatModel: IMChat!
        let body: String! = message.body()
        self.messageQueue.async(flags: .barrier) {
            //判断发送过来的是图片/文件 xml中有subject 节点代表就是发送的图片/文件
            if let subJect: String = message.elements(forName: "subject").first?.stringValue {
                if let from: String = message.attribute(forName: "from")?.stringValue {
                    //json转换字典
                    let messageDict = subJect.getDictionaryFromJSONString(jsonString: subJect)
                    if messageDict.object(forKey: "fileSize") != nil {
                        fileName = String(format: "%f_timeInterval", Date().timeIntervalSince1970 * 1000)+(messageDict["fileName"] as! String) //文件名
                        fileoid =  messageDict["oid"] as! String //oid
                        fileSize = messageDict["fileSize"] as! Float //文件大小
                        
                        //如果大于10M 则拒绝下载 去PC端下载
                        if fileSize > 10 {
                            let chatModel = IMChat(sendId: from.components(separatedBy: "/").first, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, fileSize: String(format: "%.2f",fileSize) , fileName: fileName, filePath: dstPath,fileOid: "/home/imuser/"+fileoid)
                            chatModel.date = body.components(separatedBy: "_MSG").last?.substringRange(start: 0, end: 19)
                            // 存入本地
                            IMMessageManager.sharedMessageManager.asyncAddOffLineMessage(message: chatModel, isOwn: false, callback: { (realm, error) in
                            })
                            return
                        }
                        
                        //文件类型
                        if messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                            //文件存储的路径
                            dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                            //sftp文件地址
                            fileNameoid = "/home/imuser/"+fileoid
                            log.info("\(from.components(separatedBy: "/").first!)单聊收到文件： \(body)")
                        } else {//图片类型
                            //图片存储的路径
                            dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                            fileNameoid = "/home/imuser/"+fileoid
                            log.info("单聊收到图片 ==> 发送人\(from.components(separatedBy: "/").first!)  图片信息： \(body) ,oid: \(fileoid)")
                        }
                    } else {
                        //pc 和 安卓发过来的消息subject节点都可以转换成json 上面是判断文件这里判断图片
                        if messageDict.object(forKey: "fileName") != nil {
                            fileName = messageDict["fileName"] as! String //文件名
                            fileoid = messageDict["oid"] as! String //oid
                        } else {//苹果发送过来的不能序列化,自己手动解析
                            let fixcharacterOne = CharacterSet(charactersIn: "}")
                            let fixcharactertwo = CharacterSet(charactersIn: "{")
                            let newSubject = subJect.trimmingCharacters(in: fixcharacterOne).trimmingCharacters(in: fixcharactertwo).components(separatedBy: ",")
                            //取到文件名和oid
                            fileName = newSubject.first?.components(separatedBy: ":").last
                            fileoid = newSubject.last?.components(separatedBy: ":").last
                        }
                        //设置保存路径
                        dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                        fileNameoid = "/home/imuser/"+fileoid
                    }
                    
                    //  get size of the chatter VC (17.09.12)
                    let appdelegate = NSApplication.shared().delegate as! AppDelegate
                    let chatterSize = appdelegate.getChatterSize()
                    
                    //判断字典中是否含有filesSize字段 表示发送的是文件
                    if messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                        
                        if fileName.lowercased().hasSuffix(".png") ||  fileName.lowercased().hasSuffix(".jpg"){
                            

                            let image = NSColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: chatterSize.width/2, height: chatterSize.height/2))
                            
                            chatModel = IMChat(sendId: from.components(separatedBy: "/").first, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, filePath: dstPath, imageOid: fileNameoid, imagewidth: image!.size.width, imageHeight: image!.size.height,downLaodType: .Loading,image: image!)
                        }else{
                            chatModel = IMChat(sendId: from.components(separatedBy: "/").first, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, fileSize: String(format: "%.2f",fileSize), fileName: fileName, filePath: dstPath,fileOid: fileNameoid)
                        }
                        chatModel.messageDownType = 0
                    } else {//发送的是图片
                        let image = NSColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: chatterSize.width/2, height: chatterSize.height/2))
                        
                        chatModel = IMChat(sendId: from.components(separatedBy: "/").first, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, filePath: dstPath, imageOid: fileNameoid, imagewidth: image!.size.width, imageHeight: image!.size.height,downLaodType: .Loading,image: image!)
                        chatModel.messageDownType = 0
                    }
                    chatModel.date = body.components(separatedBy: "_MSG").last?.substringRange(start: 0, end: 19)
                    
                    log.info("单聊收到图片、文件 ==> 发送人\(from.components(separatedBy: "/").first!)  图片信息: \(body!),oid: \(fileoid)")
                    // 存入本地
                    IMMessageManager.sharedMessageManager.asyncAddOffLineMessage(message: chatModel, isOwn: false, callback: { (realm, error) in
                        self.receiveHandler?("1")
                    })
                    
                    //串行、异步执行
                    self.downImageQueue.async(flags: .barrier) {
                        print("当前线程，%@",Thread.current)
                        //线程挂起
                        self.downImageQueue.suspend()
                        let ftpStatusIsTrue = IMUpLoadFileManager.sharedFileManager.checkFtpStatus()
                        //检查文件是否下载完成
                        let isDonwFile = IMUpLoadFileManager.sharedFileManager.downLoadFileForName(fileName: fileNameoid,localFilePath:dstPath)
                        //线程释放
                        
                        self.downImageQueue.resume()
                        print("完成下载")
                        DispatchQueue.main.async {
                            print("进入主线程")
                            if isDonwFile == true && ftpStatusIsTrue == true {
                                if !messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                                    let image = NSImage(contentsOfFile: dstPath)!//UIImage(contentsOfFile: dstPath)!
                                    let realm = try! Realm()
                                    try! realm.write {
                                        chatModel.imageData = image.png! as NSData //UIImagePNGRepresentation(image)! as NSData
                                        chatModel.imageWidth = String.init(format: "%.2f",image.size.width)
                                        chatModel.imageHeight = String.init(format: "%.2f",image.size.height)
                                        chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                    }
                                }else{
                                    if fileName.lowercased().hasSuffix(".png") || fileName.lowercased().hasSuffix(".jpg") {
                                        let image = NSImage(contentsOfFile: dstPath)! //UIImage(contentsOfFile: dstPath)!
                                        let realm = try! Realm()
                                        try! realm.write {
                                            chatModel.imageData = image.png! as NSData//UIImagePNGRepresentation(image)! as NSData
                                            chatModel.imageWidth = String.init(format: "%.2f",image.size.width)
                                            chatModel.imageHeight = String.init(format: "%.2f",image.size.height)
                                            chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                        }
                                    }else{
                                        let data = NSData(contentsOf:  NSURL(fileURLWithPath: dstPath) as URL)
                                        let realm = try! Realm()
                                        try! realm.write {
                                            chatModel.fileData = data!
                                            chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                        }
                                    }
                                }
                            }else{
                                if !messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                                    let realm = try! Realm()
                                    try! realm.write {
                                        chatModel.messageDownType = Int(MessageDownType.Failed.rawValue)
                                        let image = NSImage(named: "loadImageError")!//UIImage(named: "loadImageError")!
                                        chatModel.imageWidth = String.init(format: "%.2f",image.size.width)
                                        chatModel.imageHeight = String.init(format: "%.2f",image.size.height)
                                        
                                        chatModel.imageData = image.png! as NSData//UIImagePNGRepresentation(image)! as NSData
                                    }
                                }else{
                                    let realm = try! Realm()
                                    try! realm.write {
                                        chatModel.messageDownType = Int(MessageDownType.Failed.rawValue)
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            switch chatModel.messgaeContentType {
                            case .Image:
                                let fileManager = FileManager.default
                                //删除存放在沙盒中的缓存文件
                                //我接收的
                                if let patch = chatModel.photoName {
                                    if fileManager.fileExists(atPath: patch) {
                                        try! fileManager.removeItem(atPath: patch)
                                    }
                                }
                            case.File:
                                let fileManager = FileManager.default
                                //删除存放在沙盒中的缓存文件
                                //我接收的
                                if let patch = chatModel.fileName {
                                    if fileManager.fileExists(atPath: patch) {
                                        try! fileManager.removeItem(atPath: patch)
                                    }
                                }
                            default:
                                return
                            }
                        }
                    }
                }
            } else {
                //接收到的是普通的文字信息
                if let body = body{
                    if let msg: String = body.components(separatedBy: "_MSG").first {
                        if let from: String = message.attribute(forName: "from")?.stringValue {
                            chatModel = IMChat(sendId: from.components(separatedBy: "/").first, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, messageContext: msg)
                            log.info("单聊收到文字 ==> 发送人\(from.components(separatedBy: "/").first!) ==> 消息时间：\(body.components(separatedBy: "_MSG").last == nil ? "" : body.components(separatedBy: "_MSG").last!)")
                        }
                    }
                }
                if chatModel == nil {return}
                if body == nil{
                    chatModel.date = ""
                }else{
                    chatModel.date = body.components(separatedBy: "_MSG").last?.substringRange(start: 0, end: 19)
                }
                IMMessageManager.sharedMessageManager.asyncAddOffLineMessage(message: chatModel!, isOwn: false, callback: { (realm, error) in
                    self.receiveHandler?("1")
                })
                return
            }

        }
    }
    
    // 发送消息成功
    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
        if let _ = message.elements(forName: "subject").first?.stringValue {
            if let to: String = message.attribute(forName: "to")?.stringValue {
                if let mesg = message.body() {
                    IMTokenManager.sharedTokenManager.localPath = mesg.components(separatedBy: "_MSG").first
                    let model = IMChat(sendId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId, receivedId: to.components(separatedBy: "/").first, messageContextFile: IMTokenManager.sharedTokenManager.localPath)
                    model.date = model.getCurrentDate()
                    if let type: String = message.attribute(forName: "type")?.stringValue{
                        if type == "groupchat"{ // 和安卓同意Push消息内容
                            self.roomMessageDelegate?.roomMessageDidSend!(roomId: to, message: "群新消息")
                            return
                        }
                    }
                    // 发送消息通知
                    IMObjectManager.sharedObjectManager.taskToPushMessage(userID: to.components(separatedBy: "/").first!.components(separatedBy: "@").first!, message: "\(self.userChineseName!)给你发消息了").continueWith { (task) in
                    }
                    return
                }
            }
        }
        if let _ = message.body() {
            if let to: String = message.attribute(forName: "to")?.stringValue {
                if let type: String = message.attribute(forName: "type")?.stringValue{
                    if type == "groupchat"{ // 和安卓同意Push消息内容
                        self.roomMessageDelegate?.roomMessageDidSend!(roomId: to, message: "群新消息")
                        return
                    }
                }
                // 发送消息通知
                IMObjectManager.sharedObjectManager.taskToPushMessage(userID: to.components(separatedBy: "/").first!.components(separatedBy: "@").first!, message: "\(self.userChineseName!)给你发消息了").continueWith { (task) in
                }
            }
        }
    }
    
    // 发送消息失败
    func xmppStream(_ sender: XMPPStream!, didFailToSend message: XMPPMessage!, error: Error!) {
        let msg: String = message.body()
        log.error("消息发送失败：\(error)")
        print("消息发送失败：-----%@", msg)
    }
    
    // MARK: XMPPRosterDelegate
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster!, withVersion version: String!) -> Void {
        //type = 1 1为正常接收消息  0为重新登录后启动 收取中。。提示
        self.receiveHandler?("1")
        IMFriendsManager.sharedFriendManager.testIdGroup.removeAll()
        IMFriendsManager.sharedFriendManager.deleteAllGroup()
        print("开始获取好友 %s, %d", #function, #line)
    }
    
    // 获取好友结束
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster!) {
        print("获取好友结束 %s, %d", #function, #line)
        // !! IMProgressHUD.im_dismiss()
        self.friendsManager.deleteNoneFriend()
        self.isGetAllFriends = true
        
        if self.updateHandler != nil {
            self.updateHandler!()
        }
        if self.loginStatus == .inBackground{
            self.backLoginHandle?()
        }else{
            if self.sucessLoginedHandle != nil {
                self.sucessLoginedHandle!()
            }
        }
        self.loginStatus = .inBackground
    }
    
    // 一次获取一个好友
    private func xmppRoster(_ sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) -> Void {
        print("获取好友 %s %d", #function, #line)
        print("好友信息 %@", item)
        // 只展示互粉 和 to 的好友
        let subscription: String? = item.attribute(forName: "subscription")?.stringValue
        let jidString = item.attribute(forName: "jid")?.stringValue
        let name = item.attribute(forName: "name")?.stringValue
        let groupName: DDXMLElement? = item.elements(forName: "group").first
        if (subscription == "both") {
            let friend = IMFriend2(id: jidString!, nickName: name)
            self.friendsManager.addFriendAndGroup(friend: friend, groupName: groupName?.stringValue)
        }else if (subscription == "from") || (subscription == "to"){
            let goupName = groupName?.stringValue == nil ? "我的好友" : groupName?.stringValue
            let groupArr: [Any] = goupName == "我的好友" ? ["我的好友"] : [goupName!]
            let nickName = name == nil ? jidString?.components(separatedBy: "@coop").first! : name
            let friendJid: XMPPJID = XMPPJID(user: jidString, domain: kDomain, resource: "iOS")
            self.xmppRoster!.addUser(friendJid, withNickname: nickName, groups: groupArr, subscribeToPresence: true)
        }
    }
    
    // 非好友的状态及本地删除，删除后刷新页面UI
    func xmppRoster(_ sender: XMPPRoster!, didReceiveRosterPush iq: XMPPIQ!) -> Void {
        print("--------------\(iq.xmlString)")
        let query: XMLElement? = iq.elements(forName: "query").first
        let item: XMLElement? = query!.elements(forName: "item").first
        let subscription = item!.attribute(forName: "subscription")?.stringValue
        let jidString = item!.attribute(forName: "jid")?.stringValue
        let ask = item!.attribute(forName: "ask")?.stringValue
        if subscription == "to" {
            self.pcDeleteFriendName = jidString
        }
        if (subscription == "none" || subscription == "remove") {
            
            if subscription == "none"  && ask == nil {
                if self.pcDeleteFriendName == jidString {
                    self.removeFriendWithFriendName(friendName: jidString!)
                    self.pcDeleteFriendName = nil
                }
            }
        }
        if subscription == "from" { // 对方关注我
            // 对方请求添加我为好友且我已同意
            self.isAgreeAppliedUpdateOnline = true
        }
    }
    
    // 收到好友请求
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence:XMPPPresence) -> Void {
        self.presence = presence
        self.friendRequest(id: presence.from().user)
    }
    
    func friendRequest(id: String){
        /*
        let notification: LNNotification = LNNotification(message: "你有新的好友请求", title: "通知")
        notification.defaultAction = LNNotificationAction(title: "View", handler: { [weak self](action) in
            guard let strongSelf = self else{ return}
            if !strongSelf.isOnAddFriend {
                strongSelf.invitationHandler?()
            }
        })*/
        // 网络请求查询名字
        IMObjectManager.sharedObjectManager.taskToFetchFriendDetail(id: id).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                let newFriend = IMFriendStatus(id: id, isApplyAdded: true)
                UserDefaults.standard.set(true, forKey: "\(kShowNewFriendTip)\(strongSelf.username!)")
                if IMSessionManager.sharedSessionManager.addNewFriend(newFriend: newFriend){
                        //LNNotificationCenter.default().present(notification, forApplicationIdentifier: "imMsg")
                    print("notification ")
                }
            } else {
                let newFriend = IMFriendStatus(id: id, isApplyAdded: true)
                newFriend.nickName = task.result!.first!.name
                UserDefaults.standard.set(true, forKey: "\(kShowNewFriendTip)\(strongSelf.username!)")
                if IMSessionManager.sharedSessionManager.addNewFriend(newFriend: newFriend){
                            //LNNotificationCenter.default().present(notification, forApplicationIdentifier: "imMsg")
                    print("notification ")
                }
            }
            strongSelf.showTipHandler?()
            strongSelf.updateNewFriendListHandler?()
        }
    }
    
    // MARK: XMPPReconnectDelegate 动态重连
    func xmppReconnect(_ sender: XMPPReconnect!, shouldAttemptAutoReconnect connectionFlags: SCNetworkReachabilityFlags) -> Bool {
        self.reconnectCuont += 1
        if self.reconnectCuont < 5{
            
        }else if self.reconnectCuont >= 5 && self.reconnectCuont <= 10{
            self.resSetupReconnectTimerWithTimerInterval(interval: 9.0)
        }else if self.reconnectCuont >= 10 && self.reconnectCuont <= 15{
            self.resSetupReconnectTimerWithTimerInterval(interval: 15.0)
        }else{
            self.reconnectImmediately()
        }
        
        return true
    }
    
    func resSetupReconnectTimerWithTimerInterval(interval: TimeInterval){
        guard let reconnect = self.xmppReconnect, reconnect.reconnectDelay <= TimeInterval(0.0) && reconnect.reconnectTimerInterval <= TimeInterval(0.0) else {
            return
        }
        
        reconnect.reconnectTimerInterval = interval
        self.reconnectTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    }
    
    //新一轮自动连接初始化
    func reconnectImmediately(){
        self.xmppReconnect?.reconnectTimerInterval = 3.0
        self.reconnectCuont = 0
        self.xmppReconnect?.stop()
        self.xmppReconnect?.manualStart()
    }
    
    func xmppReconnect(_ sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkReachabilityFlags) {
        print("%u", connectionFlags) // 断开连接
        self.noNetWork = true
    }
#if TARGET_OS_IOS
    func xmppStream(_ sender: XMPPStream!, socketWillConnect socket: GCDAsyncSocket!) {
        CFReadStreamSetProperty(socket.readStream() as! CFReadStream!, CFStreamPropertyKey(rawValue: kCFStreamNetworkServiceType), kCFStreamNetworkServiceTypeVoIP)
        CFWriteStreamSetProperty(socket.writeStream() as! CFWriteStream!, CFStreamPropertyKey(rawValue: kCFStreamNetworkServiceType), kCFStreamNetworkServiceTypeVoIP)
    }
#endif
    // MARK: 心跳机制delegate XMPPAutoPingDelegate
    func xmppAutoPingDidReceivePong(_ sender: XMPPAutoPing!) {
        if self.pingTimeoutCount > 0{
            pingTimeoutCount = 0
        }
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive iq: XMPPIQ!) -> Bool {
        return true
    }
    
    func xmppAutoPingDidTimeout(_ sender: XMPPAutoPing!) {
        self.pingTimeoutCount += 1
        if self.pingTimeoutCount >= 2 {
            self.xmppStream?.disconnect()
        }
    }
    
    // 聊天室
    // MARK: XMPPRoomDelegate
    // 群聊: 收到消息
    func xmppRoom(_ sender: XMPPRoom!, didReceive message: XMPPMessage!, fromOccupant occupantJID: XMPPJID!) {
        // 寫入TimeStamp到本地
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: "\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)+lastTimeStamp")
        
        // 用戶姓名
        let senderName = occupantJID.full().components(separatedBy: "/")[1]
        let roomName = occupantJID.full().components(separatedBy: "@conference.coop")[0]
        
        //回到主线程,如果自己是发言,则返回
        //群聊有个问题,就是每次我发言的时候,也会走到收到消息的方法,接收到自己刚才发送的图片消息,我发消息给我自己.
        IMObjectManager.sharedObjectManager.taskToWriteOnChangeTime(roomId: roomName+"@conference.coop").continueWith { (task) in
            if task.error != nil {
            } else {
                if task.result! {
                    print("===taskToWriteOnChangeTime")
                }
            }
        }
        
        guard senderName != self.userChineseName else{
            self.receiveHandler?("1")
            return
        }
        guard let id = senderName.components(separatedBy: "(").last?.substringLast(), id != self.username else{
            self.receiveHandler?("1")
            return
        }
        
        // 姓名變成帶有NB的工號處理
        if senderName.contains("NB") {
            var name: String?
            let pureUserId = senderName.components(separatedBy: "NB").first!
            name = UserDefaults.standard.string(forKey: pureUserId)
            if name != nil && !name!.isEmpty {
                self.configureMsgWithSenderName(message: message, senderName: name!,roomName: roomName)
            }else{
                IMObjectManager.sharedObjectManager.taskToFetchSearchFriends(name: "", id: pureUserId).continueWith {[weak self](task) in
                    guard let strongSelf = self else {return}
                    if task.error != nil {
                        strongSelf.configureMsgWithSenderName(message: message, senderName: pureUserId,roomName: roomName)
                    } else {
                        if !task.result!.isEmpty {
                            let nickName = task.result?.first?.name
                            UserDefaults.standard.set(nickName!, forKey: pureUserId)
                            strongSelf.configureMsgWithSenderName(message: message, senderName: nickName!,roomName: roomName)
                        }else{
                            strongSelf.configureMsgWithSenderName(message: message, senderName: pureUserId,roomName: roomName)
                        }
                    }
                }
            }
        }else{
            self.configureMsgWithSenderName(message: message, senderName: senderName,roomName: roomName)
        }
    }
    
    // 处理收到的信息
    func configureMsgWithSenderName(message: XMPPMessage, senderName: String,roomName: String) {
        print(message)
 
        var isOwn = false
        var fileNameoid = ""
        var fileName: String!
        var fileoid: String!
        var fileSize: Float!
        var dstPath = ""
        var chatModel: IMChat!
        let body: String! = message.body()
        let occupantJid = message.attribute(forName: "from")?.stringValue?.components(separatedBy: "/").first!
        
        let myJid = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!
        
        messageMUCQueue.async(flags: .barrier) {
            if let subJect: String = message.elements(forName: "subject").first?.stringValue {
                if let _ = message.attribute(forName: "from")?.stringValue {
                    //json转换字典
                    let messageDict = subJect.getDictionaryFromJSONString(jsonString: subJect)
                    if messageDict.object(forKey: "fileSize") != nil {
                        fileName = String(format: "%f_timeInterval", Date().timeIntervalSince1970 * 1000)+(messageDict["fileName"] as! String) //文件名
                        fileoid = messageDict["oid"] as! String //oid
                        fileSize = messageDict["fileSize"] as! Float //文件大小
                        //文件类型
                        if messageDict.allKeys.contains(where: { String(describing: $0) == "filesSize"}) {
                            dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                            fileNameoid = "/home/imuser/"+fileoid
                        } else {//图片类型
                            dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                            fileNameoid = "/home/imuser/"+fileoid
                        }
                    } else {
                        //pc 和 安卓发过来的消息subject节点都可以转换成json 上面是判断文件这里判断图片
                        if messageDict.object(forKey: "fileName") != nil {
                            fileName = messageDict["fileName"] as! String //文件名
                            fileoid = messageDict["oid"] as! String //oid
                            log.info("群聊收到文件： \(body)")
                        } else {
                            let fixcharacterOne = CharacterSet(charactersIn: "}")
                            let fixcharactertwo = CharacterSet(charactersIn: "{")
                            let newSubject = subJect.trimmingCharacters(in: fixcharacterOne).trimmingCharacters(in: fixcharactertwo).components(separatedBy: ",")
                            //取到文件名和oid
                            fileName = newSubject.first?.components(separatedBy: ":").last
                            fileoid = newSubject.last?.components(separatedBy: ":").last
                            log.info("群聊收到图片： \(body),oid: \(fileoid)")
                        }
                        //设置保存路径
                        dstPath = ImageFilesManager.getImagePathForPhotoName(fileName)!
                        fileNameoid = "/home/imuser/"+fileoid
                    }
                    
                    //  get size of the chatter VC (17.09.12)
                    let appdelegate = NSApplication.shared().delegate as! AppDelegate
                    let chatterSize = appdelegate.getChatterSize()
                    
                    
                    //判断字典中是否含有filesSize字段 表示发送的是文件
                    if messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                        var sendId = ""
                        var receiveId = ""
                        if isOwn == true {
                            sendId = myJid
                            receiveId = occupantJid!
                        }else{
                            sendId = occupantJid!
                            receiveId = myJid

                        }
                        
                        if fileName.lowercased().hasSuffix(".png") ||  fileName.lowercased().hasSuffix(".jpg"){
                            let image = NSColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: chatterSize.width, height: chatterSize.height))//UIColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: UIScreen.width/2, height: UIScreen.height/2))
                            chatModel = IMChat(sendId: sendId, receivedId: receiveId, filePath: dstPath, imageOid: fileNameoid, imagewidth: image?.size.width, imageHeight: image?.size.height, downLaodType: .Loading, image: image!)
                        }else{
                             chatModel = IMChat(sendId: sendId, receivedId: receiveId, fileSize: String(format: "%.2f",fileSize), fileName: fileName, filePath: dstPath,fileOid: fileNameoid)
                        }
                        chatModel.nickName? = senderName
                        log.info("群聊收到文件： \(body)")
                    } else {//发送的是图片
                        let image = NSColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: chatterSize.width, height: chatterSize.height))//UIColor.white.getImageBy(rect: CGRect(x: 0, y: 0, width: UIScreen.width/2, height: UIScreen.height/2))
                        if isOwn == true {
                            chatModel = IMChat(sendId: myJid, receivedId: occupantJid, filePath: dstPath, imageOid: fileNameoid, imagewidth: image?.size.width, imageHeight: image?.size.height, downLaodType: .Loading, image: image!)
                        }else{
                            chatModel = IMChat(sendId: occupantJid, receivedId: myJid, filePath: dstPath, imageOid: fileNameoid, imagewidth: image?.size.width, imageHeight: image?.size.height, downLaodType: .Loading, image: image!)
                        }
                        chatModel.nickName? = senderName
                        
                        log.info("群聊收到图片： \(body),oid: \(fileoid)")

                    }
                    chatModel.messageDownType = 0
                    if  body.components(separatedBy: "_MSG").count < 2{
                        chatModel.date = ""
                    }else{
                        chatModel.date = body.components(separatedBy: "_MSG").last?.substringRange(start: 0, end: 19)
                    }
                    //串行、异步执行在下图片，并且更新数据
                    self.downImageQueue.async(flags: .barrier) {
                        print("当前线程，%@",Thread.current)
                        self.messageMUCQueue.suspend()
                        let ftpStatusIsTrue = IMUpLoadFileManager.sharedFileManager.checkFtpStatus()
                        let isDonwFile = IMUpLoadFileManager.sharedFileManager.downLoadFileForName(fileName: fileNameoid, localFilePath:
                            dstPath)
                        self.messageMUCQueue.resume()
                        
                        print("finish downLoad Image")
                        
                        DispatchQueue.main.async {
                            print("In  main thread")
                            isOwn = senderName == self.userChineseName ? true : false
                            if isDonwFile == true && ftpStatusIsTrue == true {
                                //判断字典中是否含有filesSize字段 表示发送的是文件
                                if messageDict.allKeys.contains(where: { String(describing: $0) == "fileSize"}) {
                                    if fileName.lowercased().hasSuffix(".png") ||  fileName.lowercased().hasSuffix(".jpg"){
                                        let image = NSImage(contentsOfFile: dstPath)!//UIImage(contentsOfFile: dstPath)!
                                        let realm = try! Realm()
                                        try! realm.write {
                                            chatModel.imageData = image.png! as NSData//UIImagePNGRepresentation(image)! as NSData
                                            chatModel.imageWidth = String.init(format: "%.2f",image.size.width)
                                            chatModel.imageHeight = String.init(format: "%.2f",image.size.height)
                                            chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                        }
                                    }else{
                                        let realm = try! Realm()
                                        try! realm.write {
                                            chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                        }
                                    }
                                } else {//发送的是图片
                                    let image = NSImage(contentsOfFile: dstPath)!//UIImage(contentsOfFile: dstPath)!
                                    let realm = try! Realm()
                                    try! realm.write {
                                        chatModel.imageData = image.png! as NSData//UIImagePNGRepresentation(image)! as NSData
                                        chatModel.imageWidth = String.init(format: "%.2f",image.size.width)
                                        chatModel.imageHeight = String.init(format: "%.2f",image.size.height)
                                        chatModel.messageDownType = Int(MessageDownType.Success.rawValue)
                                    }
                                }
                            }else{
                                let errImage = NSImage(named: "loadImageError")!//UIImage(named: "loadImageError")
                                let realm = try! Realm()
                                try! realm.write {
                                    chatModel.messageDownType = Int(MessageDownType.Failed.rawValue)
                                    chatModel.imageData = errImage.png! as NSData//UIImagePNGRepresentation(errImage!)! as NSData
                                    chatModel.imageWidth = String.init(format: "%.2f",(errImage.size.width))
                                    chatModel.imageHeight = String.init(format: "%.2f",(errImage.size.height))
                                }
                            }
                            
                            switch chatModel.messgaeContentType {
                            case .Image:
                                let fileManager = FileManager.default
                                //删除存放在沙盒中的缓存文件
                                //我接收的
                                if let patch = chatModel.photoName {
                                    if fileManager.fileExists(atPath: patch) {
                                        try! fileManager.removeItem(atPath: patch)
                                    }
                                }
                            case.File:
                                let fileManager = FileManager.default
                                //删除存放在沙盒中的缓存文件
                                //我接收的
                                if let patch = chatModel.fileName {
                                    if fileManager.fileExists(atPath: patch) {
                                        try! fileManager.removeItem(atPath: patch)
                                    }
                                }
                            default:
                                return
                            }
                        }
                    }
                }
            } else {
                if let msg: String = body.components(separatedBy: "_MSG").first {
                    log.info("收到\(senderName) \(roomName) 群聊文字消息  ==> 时间\(body.components(separatedBy: "_MSG").last == nil ? "" :  body.components(separatedBy: "_MSG").last!)")
                    if let from: String = message.attribute(forName: "from")?.stringValue {
                        let occupantJid = from.components(separatedBy: "/").first!
                        let myJid = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!
                        
                        if senderName == self.userChineseName {
                            // 自己發言
                            chatModel = IMChat(sendId: myJid, receivedId: occupantJid, messageContext: msg)
                            chatModel.nickName? = senderName
                            isOwn = true
                        } else {
                            // 對方發言
                            chatModel = IMChat(sendId: occupantJid, receivedId: myJid, messageContext: msg)
                            chatModel.nickName? = senderName
                            if msg.hasPrefix("【"){
                                //加入群更新列表
                                if msg.hasSuffix("】进入聊天室") ||  msg.hasSuffix("】進入聊天室")  || msg.hasSuffix("】has joined the room") || msg.hasSuffix("】离开聊天室") ||  msg.hasSuffix("】離開聊天室") || msg.hasSuffix("】has left the room"){
                                    self.groupRefreshHandler?()
                                    if msg.contains("(") && msg.contains(")"){
                                        let last = chatModel.messageContext?.components(separatedBy: ")").last
                                        let first = chatModel.messageContext?.components(separatedBy: "(").first
                                        chatModel.messageContext = first! + last!
                                    }
                                    chatModel.messgaeContentStr = "3"
                                }
                            }
                            isOwn = false
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                chatModel.date = body.components(separatedBy: "_MSG").last?.substringRange(start: 0, end: 19)
                // 存入本地
                IMMessageManager.sharedMessageManager.addOffLineMessage(message: chatModel, isOwn: isOwn,roomName: roomName)
                self.receiveHandler?("1")
            }
        }
    }
    
    func xmppRoomDidCreate(_ sender: XMPPRoom!) {
        print("已創建群聊: \(sender.roomJID.user!)")
        sender.configureRoom(usingOptions: nil)
        sender.fetchConfigurationForm()
    }
    
    // 已加入聊天室
    func xmppRoomDidJoin(_ sender: XMPPRoom!) {
        if self.checkRoomExist(roomJid: sender.roomJID) == nil {
            print("新的群聊: \(sender.roomJID.user)")
            self.currentActiveRooms.append(sender)
        }
        // 未註冊群or新群
        if $.contains(self.roomList, value: sender.roomJID.bare()) == false {
            self.roomList.append(sender.roomJID.bare())
            self.registGroupChat(roomJid: sender.roomJID.bare())
        }
        self.roomDelegate?.didJoinRoom(room: IMRoom(jid: sender.roomJID))
        print("已進入群聊: \(sender.roomJID.user)")
    }
    // 已離開聊天室
    func xmppRoomDidLeave(_ sender: XMPPRoom!) {
        print("已離開群聊: \(sender.roomJID.user) 存活:\(self.currentActiveRooms.count)")
        sender.removeDelegate(self, delegateQueue: DispatchQueue.main)
        sender.deactivate()
        let room = self.checkRoomExist(roomJid: sender.roomJID)
        if room != nil {
            if self.currentActiveRooms.contains(room!) {
                self.currentActiveRooms = $.remove(self.currentActiveRooms, value: room!)
            }
        }
        self.roomDelegate?.didLeaveRoom(room: IMRoom(room: sender))
        if self.sessionManager.loggedIn{
            self.messageListDelegate?.updateMessageListReceived?()
        }
        print("已離開群聊: \(sender.roomJID.user) 存活:\(self.currentActiveRooms.count)")
    }
    
    
    func xmppRoom(_ sender: XMPPRoom!, didConfigure iqResult: XMPPIQ!) {
        print("設定群聊成功")
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didEditPrivileges iqResult: XMPPIQ!) {
        print(iqResult)
    }
    
    // 群聊: 成員更動
    func xmppRoom(_ sender: XMPPRoom!, occupantDidUpdate occupantJID: XMPPJID!, with presence: XMPPPresence!) {
        print("\(occupantJID) - \(presence.status()) ")
    }
    // 群聊: 成員加入
    func xmppRoom(_ sender: XMPPRoom!, occupantDidJoin occupantJID: XMPPJID!, with presence: XMPPPresence!) {
        /*
         let name = occupantJID!.full().components(separatedBy: "/")[1]
         let occupantJid = occupantJID!.full().components(separatedBy: "/")[0]
         if name.characters.count >= 8 {
         IMObjectManager.sharedObjectManager.taskToFetchSearchFriends(name: "", id: name).continueWith { [weak self](task) in
         guard let strongSelf = self else { return }
         if task.error != nil {
         } else {
         if !task.result!.isEmpty {
         let userName = task.result?.first?.name
         UserDefaults.standard.set(userName, forKey: name)
         let chatModel: IMChatModel
         chatModel = IMChatModel(sendId: occupantJid, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile?.jidId!, messageContext: "*\(userName!)已加入群聊*")
         chatModel.messgaeContentType = .System
         if strongSelf.roomMessageDelegate != nil {
         strongSelf.roomMessageDelegate!.newRoomMessageReceived?(message: chatModel, isGroupChat: true)
         }
         }
         }
         }
         }else{
         let chatModel: IMChatModel
         chatModel = IMChatModel(sendId: occupantJid, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile?.jidId!, messageContext: "*\(name)已加入群聊*")
         chatModel.messgaeContentType = .System
         if self.roomMessageDelegate != nil {
         self.roomMessageDelegate!.newRoomMessageReceived?(message: chatModel, isGroupChat: true)
         }
         }
         */
    }
    // 群聊: 成員離開
    func xmppRoom(_ sender: XMPPRoom!, occupantDidLeave occupantJID: XMPPJID!, with presence: XMPPPresence!) {
        /*
         let name = occupantJID!.full().components(separatedBy: "/")[1]
         let occupantJid = occupantJID!.full().components(separatedBy: "/")[0]
         if name.characters.count >= 8 {
         // 收到工號離開群聊
         IMObjectManager.sharedObjectManager.taskToFetchSearchFriends(name: "", id: name).continueWith { [weak self](task) in
         guard let strongSelf = self else { return }
         if task.error != nil {
         } else {
         if !task.result!.isEmpty {
         let userName = task.result?.first?.name
         UserDefaults.standard.set(userName, forKey: name)
         let chatModel: IMChatModel
         chatModel = IMChatModel(sendId: occupantJid, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile?.jidId!, messageContext: "*\(userName!)已离开群聊*")
         chatModel.messgaeContentType = .System
         if strongSelf.roomMessageDelegate != nil {
         strongSelf.roomMessageDelegate!.newRoomMessageReceived?(message: chatModel, isGroupChat: true)
         }
         }
         }
         }
         }else{
         let chatModel: IMChatModel
         chatModel = IMChatModel(sendId: occupantJid, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile?.jidId!, messageContext: "*\(name)已离开群聊*")
         chatModel.messgaeContentType = .System
         if self.roomMessageDelegate != nil {
         self.roomMessageDelegate!.newRoomMessageReceived?(message: chatModel, isGroupChat: true)
         }
         }
         */
    }
    
    public func xmppRoom(_ sender: XMPPRoom!, didFetchMembersList items: [Any]!) {
        print("成員名單: \(items)")
        /*
         var array = [IMFriend]()
         for item in items {
         let jid = item as! XMPPJID
         let id = jid.full().components(separatedBy: "/")[0]
         let name = jid.full().components(separatedBy: "/")[1]
         array.append(IMFriend(id: id, nickName: name, group: ""))
         }
         self.roomDelegate?.didFetchRoomMembers(members: array)
         */
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didFetchConfigurationForm configForm: XMLElement!) {
    
        let newform = self.configureRoomWithXML(configForm: configForm.copy() as! DDXMLElement)
        sender.configureRoom(usingOptions: newform?.copy() as! XMLElement)
    }
    
    func configureRoomWithXML(configForm: DDXMLElement!) -> DDXMLElement! {
        
        let newConfig: DDXMLElement = configForm.copy() as! DDXMLElement
        
        let fields: Array? = newConfig.elements(forName: "field")
        
        for field: DDXMLElement in fields! {
            let v = field.attribute(forName: "var")?.stringValue
            // 設定為固定群
            if v == "muc#roomconfig_persistentroom" {
                field.removeChild(at: 0)
                field.addChild(DDXMLElement.element(withName: "value", stringValue: "1") as! DDXMLNode)
            }
            // 開放所有人邀請成員
            if v == "muc#roomconfig_allowinvites" {
                field.removeChild(at: 0)
                field.addChild(DDXMLElement.element(withName: "value", stringValue: "1") as! DDXMLNode)
            }
            // 開放所有人可加入
            if v == "muc#roomconfig_membersonly" {
                field.removeChild(at: 0)
                field.addChild(DDXMLElement.element(withName: "value", stringValue: "0") as! DDXMLNode)
            }
            /*
             // 設定成需要密碼
             if v == "muc#roomconfig_passwordprotectedroom" {
             field.removeChild(at: 0)
             field.addChild(XMLElement.element(withName: "value", stringValue: "1") as! DDXMLNode)
             }
             // 密碼
             if v == "muc#roomconfig_roomsecret" {
             field.removeChild(at: 0)
             field.addChild(XMLElement.element(withName: "value", stringValue: "999") as! DDXMLNode)
             }
             */
        }
        
        return newConfig
        
    }
    
    // 群聊
    // MARK: XMPPMUCDelegate
    
    // 收到加入聊天室邀請
    func xmppMUC(_ sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {
        let x = message.elements(forName: "x").first
        let invite = x?.elements(forName: "invite").first
        let invitorJid = invite?.attribute(forName: "from")?.stringValue
        
        if invitorJid == nil || invitorJid?.isEmpty == true {
            return
        }
        
        let invitorId = invitorJid!.components(separatedBy: "@").first
        let reason = invite?.elements(forName: "reason").first?.stringValue
        
        
        guard IMXMPPManager.sharedXmppManager.roomList.filter({return $0.components(separatedBy: "@").first! == roomJID.user}).count == 0 else{
            return
        }
        print("Notification \(reason)")
        /*
        let notification: LNNotification = LNNotification(message: reason, title: "通知")

        notification.defaultAction = LNNotificationAction(title: "View", handler: { [weak self](action) in
            guard let strongSelf = self else{ return}
            if !strongSelf.isOnAddFriend {
                strongSelf.invitationHandler?()
            }
        })
        */
        print("收到 \(roomJID.user) 邀請")
        
        IMObjectManager.sharedObjectManager.taskToFetchSearchFriends(name: "", id: invitorId!).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            let messagesData: Data? = UserDefaults.standard.object(forKey: strongSelf.sessionManager.username!+"@room") as! Data? //群聊邀请
            
            let roomName = roomJID.user!
            let room = IMRoomStatus(roomName: roomName)
            
            if task.error != nil {
                if messagesData != nil {
                    var roomArray: [IMRoomStatus] = NSKeyedUnarchiver.unarchiveObject(with: messagesData!) as! [IMRoomStatus]
                    
                    var hasRoom = false
                    for room in roomArray{
                        if room.roomName == roomJID.user! && room.statusStr == "0"{
                            hasRoom = true
                            break
                        }
                    }
                    if !hasRoom{ //不存在相同群聊邀请 就进行添加
                        roomArray.append(room)
                        let data = NSKeyedArchiver.archivedData(withRootObject: roomArray)
                        UserDefaults.standard.set(data, forKey: strongSelf.sessionManager.username!+"@room")
                    }
                }else{
                    var roomArray = [IMRoomStatus]()
                    roomArray.append(room)
                    let roomData = NSKeyedArchiver.archivedData(withRootObject: roomArray)
                    UserDefaults.standard.set(roomData, forKey: strongSelf.sessionManager.username!+"@room")
                }
            } else {
                print(task.result!)
                if messagesData != nil {
                    var roomArray: [IMRoomStatus] = NSKeyedUnarchiver.unarchiveObject(with: messagesData!) as! [IMRoomStatus]
                    var hasRoom = false
                    for room in roomArray{
                        if room.roomName == roomJID.user! && room.statusStr == "0"{
                            hasRoom = true
                            break
                        }
                    }
                    if !hasRoom{ //不存在相同群聊邀请 就进行添加
                        roomArray.append(room)
                        let data = NSKeyedArchiver.archivedData(withRootObject: roomArray)
                        UserDefaults.standard.set(data, forKey: strongSelf.sessionManager.username!+"@room")
                    }
                }else{
                    var roomArray = [IMRoomStatus]()
                    roomArray.append(room)
                    let roomData = NSKeyedArchiver.archivedData(withRootObject: roomArray)
                    UserDefaults.standard.set(roomData, forKey: strongSelf.sessionManager.username!+"@room")
                }
            }
            
            //LNNotificationCenter.default().present(notification, forApplicationIdentifier: "imMsg")
            print("notification ")
            //新的朋友显示红点
            UserDefaults.standard.set(true, forKey: "\(kShowNewFriendTip)\(strongSelf.username!)")
            strongSelf.showTipHandler?()
            strongSelf.updateNewFriendListHandler?()
        }
    }
    
    func xmppMUC(_ sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitationDecline message: XMPPMessage!) {
        print("didReceiveInvitationDecline \(roomJID) msg: \(message.body())")
    }
    // 取得服務列表
    func xmppMUC(_ sender: XMPPMUC!, didDiscoverServices services: [Any]!) {
        print(services)
    }
    // 取得房間列表
    func xmppMUC(_ sender: XMPPMUC!, didDiscoverRooms rooms: [Any]!, forServiceNamed serviceName: String!) {
        
        var array = [IMRoom]()
        if rooms != nil {
            for element in rooms {
                let jidString: String? = (element as! XMLElement).attribute(forName: "jid")!.stringValue
                let name: String? = (element as! XMLElement).attribute(forName: "name")!.stringValue
                let room: IMRoom? = IMRoom(roomName: name!, jid: XMPPJID(string: jidString!), password: nil)
                array.append(room!)
            }
        }else{
            print("No Rooms in Service: \(serviceName)")
        }
        
        if self.mucDelegate != nil {
            self.mucDelegate?.didUpdateRoomList(ServiceName: serviceName, rooms: array)
        }else{
            print("No Delegate")
        }
    }
    
    func xmppMUC(_ sender: XMPPMUC!, failedToDiscoverRoomsForServiceNamed serviceName: String!, withError error: Error!) {
        print(error.localizedDescription)
        self.mucDelegate?.didUpdateRoomLisFail()
    }
    func xmppMUCFailed(toDiscoverServices sender: XMPPMUC!, withError error: Error!) {
        print(error.localizedDescription)
        self.mucDelegate?.didUpdateRoomLisFail()
    }
    
    /*
    // MARK: UIAlertViewDelegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch alertView.tag {
        //收到群聊邀請 tag = 101
        case AlertViewTag.roomInvition.rawValue:
            if buttonIndex == 1 {
                let roomJid = alertView.title
                let jidString = roomJid + "@conference.coop"
                self.joinRoom(RoomJid: XMPPJID(string: jidString))
            }
        default:
            break
        }
    }
    */
    // 删除好友
    func removeFriendWithFriendName(friendName: String) -> Void {
        IMFriendsManager.sharedFriendManager.removeFriendBy(id: friendName.components(separatedBy: "@coop").first!)
        let friendJid = XMPPJID(string: friendName)
        self.xmppRoster!.removeUser(friendJid)
    }
    
    // 添加好友
    func addFriendWithUserId(userId: String?, friendName: String, groupName: String?) {
        let nickName: String? = friendName.isEmpty ? nil : friendName
        let groupArray: Array? = groupName == "我的好友" ? ["我的好友"] : [groupName!]
        let friendJid: XMPPJID = XMPPJID(user: userId, domain: kDomain, resource: "iOS")
        self.xmppRoster!.addUser(friendJid, withNickname: nickName, groups: groupArray, subscribeToPresence: true)
    }
    
    // 同意添加好友
    func agreeAddNewFriendWithUserId(friendName: String?) {
        let model = IMChat(text: "我们已经是好友了。", receivedId: (friendName! + "@coop"))
        self.sendMessage(chatModel: model)
    }
    
    // 拒绝添加好友
    func rejectAddNewFriendWithUserId(friendName: String?) {
        let friendJid = XMPPJID(user: friendName!, domain: kDomain, resource: "iOS")
        self.xmppRoster!.rejectPresenceSubscriptionRequest(from: friendJid)
        self.removeFriendWithFriendName(friendName: "\(friendName!)@coop")
    }
    
    func getCurrentDate() -> String { //后缀添加时间
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return dateFormatter.string(from: date)
    }
    
    // 发送消息
    func sendMessage(chatModel: IMChat) {
        // XMPPFramework 主要是通过kissXML 来生XML 文件
        // 生成<body>文档
        let body: XMLElement = XMLElement.element(withName: "body") as! XMLElement
        body.stringValue = chatModel.messageContext! + "_MSG" + self.getCurrentDate()
        
        // 生成XML 消息文档
        let mes: XMLElement = XMLElement.element(withName: "message") as! XMLElement
        
        // 消息类型
        mes.addAttribute(withName: "type", stringValue: "chat")
        // 发送给谁
        mes.addAttribute(withName: "to", stringValue: chatModel.chatReceivedId!)
        // 由谁发送
        mes.addAttribute(withName: "from", stringValue: chatModel.chatSendId!)
        
        // 组合
        mes.addChild(body)
        
        // 发送消息
        self.xmppStream!.send(mes)
        
    }
    
    /// 发送文件图片方法
    ///
    /// - Parameter chatModel: model
    func sendFileMessage(chatReceivedId: String,chatSendId: String , fileName: String, oid: String,filepath: String) {
        // XMPPFramework 主要是通过kissXML 来生XML 文件
        // 生成<body>文档
        let body: XMLElement = XMLElement.element(withName: "body") as! XMLElement
        // _MSG加时间用于 显示发送时间  加+"[!]" +oid 为配合pc使用
        body.stringValue = "\(fileName).jpg" + "_MSG" + self.getCurrentDate() + "[!]" + oid
        
        IMTokenManager.sharedTokenManager.localPath = filepath
        
        let subject: XMLElement = XMLElement.element(withName: "subject") as! XMLElement
        subject.stringValue = "{fileName:\(fileName).jpg,oid:\(oid)}"
        
        // 生成XML 消息文档
        let mes: XMLElement = XMLElement.element(withName: "message") as! XMLElement
        // 消息类型
        mes.addAttribute(withName: "type", stringValue: "chat")
        // 发送给谁
        mes.addAttribute(withName: "to", stringValue: chatReceivedId)
        // 由谁发送
        mes.addAttribute(withName: "from", stringValue: chatSendId)
        
        // 组合
        mes.addChild(subject)
        mes.addChild(body)
        // 发送消息
        self.xmppStream!.send(mes)
    }
    
    // 发送消息 - 群聊
    func sendRoomFile(chatReceivedId: String, fileName: String, oid: String, filepath: String) {
        IMTokenManager.sharedTokenManager.localPath = filepath
        
        let reciver: XMPPJID = XMPPJID(string: chatReceivedId)
        
        let msg = XMPPMessage(type: "groupchat", to: reciver)
        
        let subject: XMLElement = XMLElement.element(withName: "subject") as! XMLElement
        subject.stringValue = "{fileName:\(fileName).jpg,oid:\(oid)}"
        
        let body: XMLElement = XMLElement.element(withName: "body") as! XMLElement
        body.stringValue = "\(fileName).jpg" + "_MSG" + self.getCurrentDate() + "[!]" + oid
        
        msg?.addChild(subject)
        msg?.addChild(body)
        
        if let room = self.checkRoomExist(roomJid: reciver) {
            room.send(msg)
        }else{
            print("房間不存在")
        }
    }
    
    // 发送消息 - 群聊
    func sendRoomMessage(chatModel: IMChat) {
        let reciver: XMPPJID = XMPPJID(string: chatModel.chatReceivedId!)
        let msg = XMPPMessage(type: "groupchat", to: reciver)
        msg?.addBody(chatModel.messageContext! + "_MSG" + self.getCurrentDate())
        
        if let room = self.checkRoomExist(roomJid: reciver) {
            room.send(msg)
        }else{
            print("房間不存在")
        }
    }
    
    // 销毁调用
    func teardownXmppStream() {
        //離開群聊
        //if self.currentActiveRooms.count>0 {self.leaveAllRooms()}
        self.roomList.removeAll()
        
        // 删除代理
        self.goOffline()
        self.xmppStream?.removeDelegate(self)
        self.xmppRoster?.removeDelegate(self)
        self.messageArchiving?.removeDelegate(self)
        self.xmppReconnect?.removeDelegate(self)
        self.xmppAutoPing?.deactivate()
        self.xmppAutoPing?.removeDelegate(self)
        self.xmppMUC?.removeDelegate(self)
        
        // 取消激活
        self.messageArchiving?.deactivate()
        self.xmppRoster?.deactivate()
        self.xmppReconnect?.deactivate()
        self.xmppMUC?.deactivate()
        
        // 置空
        self.messageArchiving = nil
        self.xmppReconnect = nil
        self.xmppAutoPing = nil
        self.xmppStream = nil
        self.xmppRoster = nil
        self.rosterStorage = nil
        self.messageStorage = nil
        self.managedObjectContext = nil
        self.roomDelegate = nil
    }
    
    // MARK: 群聊
    //-----------------------------------------------------------------------------
    // 啟動群聊接口
    func activeXMPPMUC() -> Void {
        if self.xmppMUC?.xmppStream == nil {
            self.xmppMUC?.activate(self.xmppStream!)
            self.xmppMUC?.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
    }
    
    // 群聊邀請其他成員
    func inviteFriends (roomJid: XMPPJID, friends: [IMFriend2]?) {
        if let room = self.checkRoomExist(roomJid: roomJid) {
            for friend in friends! {
                let userJid = friend.jidId!
                /*
                 //設定成員權限(管理者)
                 let uuid = room.editPrivileges([XMPPRoom.item(withAffiliation: "member", jid: XMPPJID(string: userJid))])
                 print("editPrivileges:\(uuid!)")
                 */
                let roomName = roomJid.user
                let userId = userJid.components(separatedBy: "@").first!
                room.inviteUser(XMPPJID(string: userJid), withMessage: "\(self.userChineseName!)邀请您加入\(roomName ?? "")群")
                IMObjectManager.sharedObjectManager.taskToPushMessage(userID: userId, message: "\(self.userChineseName!)邀请您加入\(roomName ?? "")群").continueWith { (task) in
                }
            }
        }
    }
    // 創建群聊
    func createRoom(RoomSubject subject: String,date: String = "0") {
        let jidString = "\(subject)@conference.coop"
        let roomMemoryStorage = XMPPRoomMemoryStorage()
        let roomJID = XMPPJID(string: jidString)
        let room = XMPPRoom(roomStorage: roomMemoryStorage, jid: roomJID, dispatchQueue: DispatchQueue.main)
        room?.activate(self.xmppStream!)
        room?.addDelegate(self, delegateQueue: DispatchQueue.main)
        let name = self.userChineseName! + "(\(self.username!))"
        room?.join(usingNickname: name, history: getOfflineIntervalXML(roomJid: jidString,date: date), password: nil)
    }
    
    // 加入群聊
    func joinRoom(RoomJid roomJid: XMPPJID,date: String = "0"){
        //已加入過的群聊
        if self.checkRoomExist(roomJid: roomJid) != nil {
            print("已加入過的群聊: \(roomJid)")
            self.roomDelegate?.didJoinRoom(room: IMRoom(jid: roomJid))
            return
        }
        if roomJid.user != nil {
            print("準備加入新群聊: \(roomJid.user!)")
            self.createRoom(RoomSubject: roomJid.user,date: date)
        }
    }
    
    // 離開群聊
    func leaveRoom(RoomJid roomJid: XMPPJID){
        print(roomJid)
        if let room = self.checkRoomExist(roomJid: roomJid) {
            self.graintRoomOwner(room: room)
        }else{
            if self.messageListDelegate != nil {
                self.messageListDelegate!.updateMessageListReceived?()
            }
        }
    }
    // 取得已加入過的群聊
    func fetchGroupChatList() {
        IMObjectManager.sharedObjectManager.taskToFetchGroupChatList(id: self.username!).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                
            } else {
                
                if !task.result!.isEmpty {
                    strongSelf.roomList.removeAll()
                    // 加入參加過的群
                    for dic in task.result! {
                        if !strongSelf.checkTextSufficientComplexity(text: dic.key) && !dic.key.contains(" ") {
                                // 已是app專用群
                                
                                // 檢查手動移除flag
                                let removeId = "\(dic.key)+\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)"
                                let remove: Bool? = UserDefaults.standard.object(forKey: "remove-\(removeId)-") as! Bool?
                                if remove == nil {
                                    // 增加手動移除flag
                                    UserDefaults.standard.set(false, forKey: "remove-\(removeId)-")
                                }
                                
                                if dic.key.contains("@conference.coop") {
                                    DispatchQueue.main.async {
                                        strongSelf.joinRoom(RoomJid: XMPPJID(string: "\(dic.key)"),date: dic.value.stringValue)
                                    }
                                    strongSelf.roomList.append(dic.key)
                                }
                        }
                    }
                }else{
                    // 群聊名單為空 清除所以紀錄
                    if let groupChats = IMMessageManager.sharedMessageManager.getGroupMessageList(){
                        for item in groupChats {
                            let group = item as! IMMessageList2
                            IMMessageManager.sharedMessageManager.deleteMessageList(id: group.userId!)
                        }
                    }
                }
                
                if let groupChats = IMMessageManager.sharedMessageManager.getGroupMessageList(){
                    var keys = [String]()
                    for dic in task.result!{
                        keys.append(dic.key)
                    }
                    
                    for groupChat in groupChats{
                        let groupCharId = (groupChat as! IMMessageList2).userId!
                        //群聊紀錄
                        if groupCharId == "coop"{    //系統訊息
                            continue
                        }
                        //删除已经退群的聊天记录
                        if !$.contains(keys, value: groupCharId.components(separatedBy: "+").first!){
                            IMMessageManager.sharedMessageManager.deleteMessageList(id: groupCharId)
                        }
                    }
                }
                
            }
        }
    }
    // 更新加入過的群聊
    func updateGroupChatList() {
        IMObjectManager.sharedObjectManager.taskToFetchGroupChatList(id: self.username!).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                strongSelf.roomDelegate?.didUpdateRoom()
            } else {
                if !task.result!.isEmpty {
                    var prepareToJoin =  Dictionary<String, JSON>()    //待加入的群聊
                    var prepareToLeave =  [String]()   //待退出的群聊
                    for dic in task.result! {
                        if !$.contains(strongSelf.roomList, value: dic.key){
                            if !strongSelf.checkTextSufficientComplexity(text: dic.key) && !dic.key.contains(" ") {
                                    prepareToJoin[dic.key] = dic.value
                            }
                        }
                    }
                    var keys = [String]()
                    for dic in task.result!{
                        keys.append(dic.key)
                    }
                    
                    for roomId in strongSelf.roomList {
                        if !$.contains(keys, value: roomId){
                            if !strongSelf.checkTextSufficientComplexity(text: roomId) && !roomId.contains(" "){
                                prepareToLeave.append(roomId)
                            }
                        }
                    }
                    
                    for leaveId in prepareToLeave {
                        
                        if leaveId.contains("@conference.coop") {
                            strongSelf.leaveRoom(RoomJid: XMPPJID(string: "\(leaveId)"))
                        } else {
                            strongSelf.leaveRoom(RoomJid: XMPPJID(string: "\(leaveId)@conference.coop"))
                        }
                        
                        let id = "\(leaveId)+\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)"
                        
                        IMMessageManager.sharedMessageManager.deleteMessageList(id: id)
                    }
                    //加入群聊
                    for dic in prepareToJoin {
                        if dic.key.contains("@conference.coop") {
                            strongSelf.joinRoom(RoomJid: XMPPJID(string: "\(dic.key)"), date: dic.value.stringValue)
                        } else {
                            strongSelf.joinRoom(RoomJid: XMPPJID(string: "\(dic.key)@conference.coop"), date: dic.value.stringValue)
                        }
                    }
                    
                    //更新群聊名單
                    strongSelf.roomList.removeAll()
                    for dic in task.result! {
                        if !strongSelf.checkTextSufficientComplexity(text: dic.key) && !dic.key.contains(" ") {
                                // 只加入app專用
                                strongSelf.roomList.append(dic.key)
                        }
                    }
                }else{
                    // 群聊名單為空 清除所以紀錄
                    if let groupChats = IMMessageManager.sharedMessageManager.getGroupMessageList(){
                        for item in groupChats {
                            let group = item as! IMMessageList2
                            IMMessageManager.sharedMessageManager.deleteMessageList(id: group.userId!)
                        }
                    }
                }
            }
        }
    }
    
    // 註冊群聊Jid(後台)
    func registGroupChat(roomJid: String!) {
        IMObjectManager.sharedObjectManager.taskToJoinGroupChat(userID: self.username!, roomJID: roomJid!, nickName: self.userChineseName! ,token: IMTokenManager.sharedTokenManager.token!).continueWith{ [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                // !! IMProgressHUD.im_showErrorWithStatus(string: "登录群聊失败")
            } else {
                if task.result == true {
                    print("註冊群聊成功")
                    // 顯示在消息列表
                    strongSelf.showRoomOnMessageList(roomJid: roomJid!)
                    // 取得成員列表
                    IMObjectManager.sharedObjectManager.taskToFetchGroupChatMembers(roomId: roomJid!).continueWith { (task) in
                        
                        if task.error != nil {
                            // !! IMProgressHUD.im_showErrorWithStatus(string: "获取群成员列表失败")
                        } else {
                            let roomName = roomJid.components(separatedBy: "@conference.coop").first!
                            
                            var membersId = [String]()
                            for member in task.result! {
                                if member["userId"].stringValue != IMXMPPManager.sharedXmppManager.username! {
                                    membersId.append(member["userId"].stringValue)
                                }
                            }
                            // 發送push通知
                            IMObjectManager.sharedObjectManager.taskToPushRoomMessage(membersID: membersId, message: "【\(IMXMPPManager.sharedXmppManager.userChineseName!)】进入聊天室", title: roomName+"__群信息", pushKey: "roomInOut", silentPush: true).continueWith { (task) in
                            }
                        }
                    }
                    
                }else{
                    // !! IMProgressHUD.im_showErrorWithStatus(string: "登录群聊失败")
                    print("註冊群聊失敗")
                }
            }
        }
    }
    
    // 註銷群聊(後台)
    func resignGroupChat(roomJid: String!) {
        IMObjectManager.sharedObjectManager.taskToLeaveGroupChat(userID: self.username!, roomJID: roomJid!, token: IMTokenManager.sharedTokenManager.token!).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                // !! IMProgressHUD.im_showErrorWithStatus(string: "注销群聊失败")
            } else {
                if task.result == true {
                    print("註銷群聊成功")
                    for (index, item) in strongSelf.roomList.enumerated() {
                        if item == roomJid! {
                            strongSelf.roomList.remove(at: index)
                            break;
                        }
                    }
                    let id = "\(roomJid!)+\(strongSelf.username! + "@coop")"
                    IMMessageManager.sharedMessageManager.deleteMessageList(id: id)
                }else{
                    // !! IMProgressHUD.im_showErrorWithStatus(string: "注销群聊失败")
                    print("註銷群聊失敗")
                }
            }
        }
    }
    
    // 註銷群聊並通知(後台)
    func resignGroupChat(roomJid: String!, membersId: [String]) {
        IMObjectManager.sharedObjectManager.taskToLeaveGroupChat(userID: self.username!, roomJID: roomJid!, token: IMTokenManager.sharedTokenManager.token!).continueWith { [weak self](task) in
            guard let strongSelf = self else { return }
            if task.error != nil {
                // !! IMProgressHUD.im_showErrorWithStatus(string: "注销群聊失败")
            } else {
                if task.result == true {
                    print("註銷群聊成功")
                    for (index, item) in strongSelf.roomList.enumerated() {
                        if item == roomJid! {
                            strongSelf.roomList.remove(at: index)
                            break;
                        }
                    }
                    let roomName = roomJid.components(separatedBy: "@conference.coop").first!
                    
                    // 發送群聊退群push
                    IMObjectManager.sharedObjectManager.taskToPushRoomMessage(membersID: membersId, message: "【\(IMXMPPManager.sharedXmppManager.userChineseName!)】离开聊天室", title: roomName+"__群信息", pushKey: "roomInOut", silentPush: true).continueWith { (task) in
                        
                    }

                    let id = "\(roomJid!)+\(strongSelf.username! + "@coop")"
                    IMMessageManager.sharedMessageManager.deleteMessageList(id: id)
                    
                }else{
                    // !! IMProgressHUD.im_showErrorWithStatus(string: "注销群聊失败")
                    print("註銷群聊失敗")
                }
            }
        }
    }
    
    // 取得離線時間
    func getOfflineIntervalXML(roomJid: String,date offleaveDate: String = "0") -> XMLElement? {
        self.offlineInterval = Int(offleaveDate)! / 1000
        // 用戶主動刪除flag
        let removeId = "\(roomJid)+\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)"
        let remove = UserDefaults.standard.object(forKey: "remove-\(removeId)-") as! Bool?
        
        let history = XMLElement(name: "history")
        let offLineMessages = IMMessageManager.sharedMessageManager.getLocalOffLineMessage(friendId: removeId)
        
        if (offLineMessages.count == 0) && remove == nil {
            // 未加入群 or 主動離開 不取得歷史消息
            history.addAttribute(withName: "maxchars", stringValue: "0")
        }else{
            // 已加入過群 or 在列表被用戶刪除
            /*
             用戶Jid+lastLogDateData: 登入成功時間
             用戶Jid+lastTimeStamp  : 最後一筆消息時間
             */
            if let lastLogDateData = UserDefaults.standard.value(forKey: "\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)+lastLoginDate") {
                let logDate = NSKeyedUnarchiver.unarchiveObject(with: lastLogDateData as! Data) as! Date
                if let lastTimeStamp = UserDefaults.standard.value(forKey: "\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)+lastTimeStamp"){
                    /*
                     本地離線時間：最後一筆信息時間 - 登入成功時間
                     外掛離線時間：self.offlineInterval
                     使用比較近的時間取得歷史信息
                     */
                    let date = NSKeyedUnarchiver.unarchiveObject(with: lastTimeStamp as! Data) as! Date
                    let interval = Int(logDate.timeIntervalSince(date)) < self.offlineInterval ? Int(logDate.timeIntervalSince(date)) : self.offlineInterval
                    history.addAttribute(withName: "seconds", stringValue: "\(interval)")
                }else{
                    history.addAttribute(withName: "seconds", stringValue: "\(self.offlineInterval)")
                }
            }else{
                history.addAttribute(withName: "seconds", stringValue: "\(self.offlineInterval)")
            }
        }
        return history
    }
    
    // 取得線上服務器列表
    func discoverAllServices() {
        self.xmppMUC?.discoverServices()
    }
    // 取得群聊列表
    func discoverAllRooms(){
        self.xmppMUC?.discoverRooms(forServiceNamed: "conference.coop") //公開房間
    }
    
    // 取得存活的群聊
    func checkRoomExist(roomJid: XMPPJID) -> XMPPRoom? {
        if self.currentActiveRooms.count == 0 { return nil }
        let room = self.currentActiveRooms.filter{ $0.roomJID.user == roomJid.user }.first
        if room != nil {
            return room!
        }else{
            return nil
        }
    }
    
    func showRoomOnMessageList(roomJid: String) {
        var exist : Bool = false
        if let objects = IMMessageManager.sharedMessageManager.getGroupMessageList() {
            for item in objects {
                let list = item as! IMMessageList2
                let listId = list.userId!.components(separatedBy: "+").first!
                if listId == roomJid{
                    exist = true
                }
            }
        }
        
        let removeId = "\(roomJid)+\(IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!)"
        let remove: Bool? = UserDefaults.standard.object(forKey: "remove-\(removeId)-") as! Bool?
        
        if exist == false && remove != false {  // 未存在且未移除
            let chatModel: IMChat
            chatModel = IMChat(sendId: roomJid, receivedId: IMSessionManager.sharedSessionManager.currentUserProfile!.jidId!, messageContext: "你已加入群聊")
            chatModel.messgaeContentStr = "3"
            chatModel.date = chatModel.getCurrentDate()
            IMMessageManager.sharedMessageManager.addOffLineMessage(message: chatModel, isOwn: false,roomName: roomJid.components(separatedBy: "@conference.coop")[0])
            let string = "【\(IMXMPPManager.sharedXmppManager.userChineseName!)】进入聊天室"
            let model = IMChat(text: string, receivedId: roomJid)
            model.nickName = IMXMPPManager.sharedXmppManager.userChineseName
            model.date = model.getCurrentDate()
            model.messgaeContentStr = "3"
            IMXMPPManager.sharedXmppManager.sendRoomMessage(chatModel: model)
        }
    }
    
    func leaveAllRooms() {
        //離開所有群聊
        for room in self.currentActiveRooms {
            room.leave()
        }
        self.currentActiveRooms.removeAll()
    }
    
    func graintRoomOwner(room: XMPPRoom) {
        IMObjectManager.sharedObjectManager.taskToFetchGroupChatMembers(roomId: room.roomJID.bare()).continueWith {(task) in
            if task.error != nil {
                
            } else {
                if !task.result!.isEmpty {
                    for user in task.result! {
                        room.editPrivileges([XMPPRoom.item(withAffiliation: "owner", jid: XMPPJID(string: user["userId"].stringValue + "@coop"))])
                    }
                    if (task.result?.count)! == 1 && (task.result?.first?["userId"].stringValue)! == self.username{
                        room.destroy()
                    }else{
                        room.leave() //离开聊天室
                    }
                }else{
                    room.destroy() //为空的时候解散聊天室
                }
            }
        }
    }
    
    // 判斷大寫A-Z
    func checkTextSufficientComplexity(text : String) -> Bool{
        let capitalLetterRegEx  = ".*[A-Z]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
        let capitalresult = texttest.evaluate(with: text)
        return capitalresult
    }
    
}
extension NSColor {
    func getImageBy(rect: CGRect) -> NSImage! {
        
        // create a CIImage filled with this color and cropped to rect.size
        let ciimage = CIImage(color: CIColor(cgColor: self.cgColor))
        let cii2 = ciimage.cropping(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        
        // create a CIContext to create CGImage from the cropped CIImage
        let context = CIContext(options: nil)
        let cgimage = context.createCGImage(ciimage, from: cii2.extent)
        
        // construct a NSImage by cgimage
        let image: NSImage = NSImage(cgImage: cgimage! , size: rect.size)
        
        return image
    }
}
/*
extension UIColor{
    func getImageBy(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(self.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}
*/
