//
//  IMChat.swift
//  IM
//
//  Created by 林海生 on 2017/5/23.
//  Copyright © 2017年 want. All rights reserved.
//

 
import RealmSwift
import Realm
#if TARGET_OS_IOS
import YYText
#else
import AppKit
#endif

class IMChat: Object {
    
    dynamic var userId: String? = nil         // 谁的对话
    dynamic var chatSendId: String? = nil     // 发送人
    dynamic var chatReceivedId: String? = nil // 接收人

    
    dynamic var nickName: String? = nil //好友姓名
    dynamic var messageContext: String? = nil // 消息内容
    
    dynamic var messgaeContentStr: String = "0" // 消息内容的类型 MessageContentType
    dynamic var fromMe: Bool = false  // 配合UI来使用
    dynamic var messageDownType: Int = 1  //0：下载中ing 1：下载成功。  2：下载失败
    dynamic var messageSendType: Int = 1  //0：上传中ing 1：上传成功。  2：上传失败
    
    #if TARGET_OS_IOS
    var richTextLayout: YYTextLayout?
    var richTextLinePositionModifier: IMYYTextLinePostionModifier?
    #endif
    var richTextAttributedString: NSMutableAttributedString?
    var cellHeight: CGFloat = 0 // 计算的高度存储使用，默认0

    var downType: MessageDownType{
        get{
            switch messageDownType{
            case 0:
                return .Loading
            case 1:
                return .Success
            case 2:
                return .Failed
            default :
                return .Success
            }
        }
    }
    
    var sendType: MessageSendType{
        get{
            switch messageSendType{
            case 0:
                return .Loading
            case 1:
                return .Success
            case 2:
                return .Failed
            default :
                return .Success
            }
        }
    }
    
    var messgaeContentType: MessageContentType{
        get{
            switch messgaeContentStr{
            case "0":
                return .Text
            case "1":
                return .Image
            case  "2":
                return .Voice
            case "3":
                return .System
            case  "4":
                return .File
            case "110":
                return  .Time
            default :
                return .Text
            }
        }

    }
    var imageTag: Int?
    dynamic var date: String? = nil
    dynamic var timeStamp: String? = nil
    
    //----------------------图片model--------------------------
    dynamic var imageOid: String? = "" //图片ftpOid
    dynamic var photoName: String? = nil //图片地址
    dynamic var imageHeight : String? = nil
    dynamic var imageWidth : String? = nil
    dynamic var imageData = NSData()  //图片存放
    
    var localThumbnailImagePath: String? {
        if let theLocalStroeName = photoName{
            let path = ImageFilesManager.cachePathForKey(theLocalStroeName)
            return path
        }else{
            return ""
        }
    }
    
    var loaclPhotoPath: String?{
        if let theLocalStroeName = photoName{
            let photoName = theLocalStroeName.components(separatedBy: "/").last
            //let photoName = theLocalStroeName.components(separatedBy: "/").last()
            let path = ImageFilesManager.getImagePathForPhotoName(photoName!)!
            return path
        }else{
            return ""
        }
    }
    
    var localThumbnailFailPath: String? {
        if let theLocalStroeName = fileName{
            let path = ImageFilesManager.cachePathForKey(theLocalStroeName)
            return path
        }else{
            return ""
        }
    }
    
    //------------------------文件模型-------------------------------
    dynamic var fileSize: String? = nil //文件大小
    dynamic var fileName: String? = nil //文件名称
    dynamic var filePath: String? = nil //ftp下载地址
    dynamic var fileData = NSData()     //文件存放
    dynamic var fileOid: String? = nil  //文件ftpOid
    

    override static func ignoredProperties() -> [String] { //忽略属性，不会存放在数据库中
        return ["richTextLayout","richTextLinePositionModifier",
                "richTextAttributedString","cellHeight","messgaeContentType","startAnimating","loaclPhotoPath"]
    }
    
    //文本存储
    convenience init(sendId: String?, receivedId receivedIdStr: String?, messageContext messageContextStr: String?, date: String? = "") {  // 初始化
        self.init()
        self.chatSendId = sendId
        self.chatReceivedId = receivedIdStr
        self.messageContext = messageContextStr
        self.messgaeContentStr = "0"
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    //图片存储
    #if TARGET_OS_IOS
    convenience init(sendId: String?, receivedId: String?, filePath: String?,imageOid: String?,imagewidth: CGFloat?,imageHeight: CGFloat?,downLaodType: MessageDownType,image: UIImage, date: String? = "") {
        self.init()
        self.chatSendId = sendId
        self.messageContext = "[图片]"
        self.chatReceivedId = receivedId
        
        self.photoName = filePath
        self.imageOid = imageOid
        self.messgaeContentStr = "1"
        self.messageDownType = Int(downLaodType.rawValue)
        self.nickName = ""
        self.imageWidth = String.init(format: "%.2f",imagewidth!)
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.date = date
        self.timeStamp = date
        self.imageData = UIImagePNGRepresentation(image)! as NSData
    }
    #else
    convenience init(sendId: String?, receivedId: String?, filePath: String?,imageOid: String?,imagewidth: CGFloat?,imageHeight: CGFloat?,downLaodType: MessageDownType,image: NSImage, date: String? = "") {
        self.init()
        self.chatSendId = sendId
        self.messageContext = "[图片]"
        self.chatReceivedId = receivedId
        
        self.photoName = filePath
        self.imageOid = imageOid
        self.messgaeContentStr = "1"
        self.messageDownType = Int(downLaodType.rawValue)
        self.nickName = ""
        self.imageWidth = String.init(format: "%.2f",imagewidth!)
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.date = date
        self.timeStamp = date
        
        let cgimage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let rep : NSBitmapImageRep! = NSBitmapImageRep(cgImage: cgimage!)
        self.imageData = rep.representation(using: .PNG, properties: [:])! as NSData
        
    }
    #endif
    
    //文件存储
    convenience init(sendId: String?, receivedId: String?,fileSize: String? ,fileName: String? ,filePath: String?,fileOid: String?, date: String? = "") {
        self.init()
        self.chatSendId = sendId
        self.messageContext = "[文件]"
        self.chatReceivedId = receivedId
        self.fileSize = fileSize
        self.fileName = fileName
        self.filePath = filePath
        self.messgaeContentStr = "4"
        self.fileOid = fileOid
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    convenience init(sendId: String?, receivedId: String?, messageContextFile: String?, date: String? = "") {
        self.init()
        self.chatSendId = sendId
        self.chatReceivedId = receivedId
        self.messageContext = messageContextFile
        self.messgaeContentStr = "1"
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    
    // 自定义发送文本的 chatModel
    convenience init(text: String, receivedId: String?, date: String? = "") {
        self.init()
        self.messageContext = text
        self.messgaeContentStr = "0"
        self.chatReceivedId = receivedId
        self.chatSendId = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    //自定义发送图片的 ChatModel
    #if TARGET_OS_IOS
    convenience init(imageUrl: String, receivedId: String?,imageHeight: CGFloat?, imageWidth: CGFloat?,photoName: String?,image: UIImage, date: String? = "") {
        self.init()
        self.messageContext = "[图片]"
        self.messgaeContentStr = "1"
        self.chatSendId = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId
        self.nickName = ""
        self.date = date
        self.timeStamp = date
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.imageWidth = String.init(format: "%.2f", imageWidth!)
        self.photoName = photoName
        self.chatReceivedId = receivedId
        self.imageData = UIImagePNGRepresentation(image)! as NSData
    }
    #else
    convenience init(imageUrl: String, receivedId: String?,imageHeight: CGFloat?, imageWidth: CGFloat?,photoName: String?,image: NSImage, date: String? = "") {
        self.init()
        self.messageContext = "[图片]"
        self.messgaeContentStr = "1"
        self.chatSendId = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId
        self.nickName = ""
        self.date = date
        self.timeStamp = date
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.imageWidth = String.init(format: "%.2f", imageWidth!)
        self.photoName = photoName
        self.chatReceivedId = receivedId
        
        let cgimage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let rep : NSBitmapImageRep! = NSBitmapImageRep(cgImage: cgimage!)
        self.imageData = rep.representation(using: .PNG, properties: [:])! as NSData
        
    }
    #endif
    /**
     *  得到cell的高度
     */
    func chatCellHeight(model: IMChat, isGroupChat: Bool) -> CGFloat {
        #if TARGET_OS_IOS
        let type = model.messgaeContentType
        switch type {
        case .Text:  // 文字
            return IMChatTextCell.layoutHeight(model: model, isGroupChat: isGroupChat)
        case .Image :
            return TSChatImageCell.layoutHeight(model, isGroupChat: isGroupChat)
        case .System: // 系统
            return IMSystemMessageCell.layoutHeight(model: model)
        case .File: //文件
            var height = CGFloat(108.0)
            if isGroupChat {
                height += 10.0.Sh()  //增加姓名高度
            }
            return height
        default:
            return IMChatTextCell.layoutHeight(model: model, isGroupChat: isGroupChat)
        }
        #else
        #endif
        return 45.0
    }
    
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    func getCurrentDate() -> String {
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return dateFormatter.string(from: date)
    }
    
    func getTimeStamp() -> String {
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return dateFormatter.string(from: date)
    }
    
}
