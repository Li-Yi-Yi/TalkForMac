//
//  IMChatModel.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

#if TARGET_OS_IOS
import YYText
import UIKit
#else
import AppKit
#endif
import Foundation

/**
 *  聊天model
 */
let kChatSendId: String = "kChatSendId"
let kChatReceivedId: String = "kChatReceivedId"
let kMessageContext: String = "kMessageContext"
let kMessgaeContentType: String = "kMessgaeContentType"
let kFromMe: String = "kFromMe"
let kRichTextLayout: String = "kRichTextLayout"
let kRichTextLinePositionModifier: String = "kRichTextLinePositionModifier"
let kRichTextAttributedString: String = "kRichTextAttributedString"
let kCellHeight: String = "kCellHeight"
let kNickName: String = "kNickName"
let kDate: String = "kDate"
let kTimeStamp: String = "kTimeStamp"
let kimageHeight: String = "kimageHeight"
let KimageWidth: String = "KimageWidth"
let klocalStoreName: String = "localStoreName"
let kphotoFilePath: String = "kphotoFilePath"
let kfilePath: String = "KfilePath"
let KfileName: String = "KfileName"
let kfileSize: String = "KfileSize"
let kDiskImagePath: String = "kDiskImagePath"


class IMChatModel: NSObject, NSCoding {
    
    var chatSendId: String? // 发送人
    var chatReceivedId: String? // 接收人
    var messageContext: String? // 消息内容
    var messgaeContentType: MessageContentType = .Text // 消息内容的类型
    var nickName: String? // 发送人暱稱(姓名)
    // 配合UI来使用
    var fromMe: Bool {
        get{ return self.chatSendId == (IMXMPPManager.sharedXmppManager.username! + "@coop") }
        set{ _ = newValue }
    }
    //var richTextLayout: YYTextLayout?
    //var richTextLinePositionModifier: IMYYTextLinePostionModifier?
    var richTextAttributedString: NSMutableAttributedString?
    var cellHeight: CGFloat = 0 // 计算的高度存储使用，默认0
    
    var date: String?
    var timeStamp: String?
    ///----------------------图片model--------------------------
    var photoFilePath: String?
    var imageHeight : String?
    var imageWidth : String?
    var imageId : String?
    var originalURL : String?
    var thumbURL : String?
    var imageTag: Int?
    var localStoreName: String?  //拍照，选择相机的图片的临时名称
    var DiskImageName: String? //文件存储在沙盒中的目录
    #if TARGET_OS_IOS
    var localThumbnailImage: UIImage? {  //从 Disk 加载出来的图片
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
            return UIImage(contentsOfFile: path!)
        } else {
            return nil
        }
    }
    #else
    var localThumbnailImage: NSImage? {  //从 Disk 加载出来的图片
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
            return NSImage(contentsOfFile: path!)
        } else {
            return nil
        }
    }
    #endif
    
    //取出图片KingFisherDisk路径
    var localThumbnailImagePatch: String? {  //从 Disk 加载出来的图片路径
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
            return path
        } else {
            return nil
        }
    }
    
    //------------------------文件模型-------------------------------
    var fileSize: String? //文件大小
    var fileName: String? //文件名称
    var filePath: String?//文件存储路径
    
    //文本存储
    init(sendId: String?, receivedId receivedIdStr: String?, messageContext messageContextStr: String?, date: String? = "") {
        super.init()
        self.chatSendId = sendId
        self.chatReceivedId = receivedIdStr
        self.messageContext = messageContextStr
        self.messgaeContentType = .Text
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    //图片存储
    init(sendId: String?, receivedId: String?, filePath: String?,imagewidth: CGFloat?,imageHeight: CGFloat?,distImageName: String?, date: String? = "") {
        super.init()
        self.chatSendId = sendId
        self.messageContext = "[图片]"
        self.chatReceivedId = receivedId
        self.photoFilePath = filePath
        self.messgaeContentType = .Image
        self.nickName = ""
        self.DiskImageName = distImageName
        self.imageWidth = String.init(format: "%.2f",imagewidth!)
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.date = date
        self.timeStamp = date
    }
    
    //文件存储
    init(sendId: String?, receivedId: String?,fileSize: String? ,fileName: String? ,filePath: String?, date: String? = "") {
        super.init()
        self.chatSendId = sendId
        self.messageContext = "[文件]"
        self.chatReceivedId = receivedId
        self.fileSize = fileSize
        self.fileName = fileName
        self.filePath = filePath
        self.messgaeContentType = .File
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    
    init(sendId: String?, receivedId: String?, messageContextFile: String?, date: String? = "") {
        super.init()
        self.chatSendId = sendId
        self.chatReceivedId = receivedId
        self.messageContext = messageContextFile
        self.messgaeContentType = .Image
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    
    // 自定义发送文本的 chatModel
    init(text: String, receivedId: String?, date: String? = "") {
        super.init()
        self.messageContext = text
        self.messgaeContentType = .Text
        self.chatReceivedId = receivedId
        self.chatSendId = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId
        self.nickName = ""
        self.date = date
        self.timeStamp = date
    }
    
    //自定义发送图片的 ChatModel
    init(imageUrl: String, receivedId: String?,imageHeight: CGFloat?, imageWidth: CGFloat?,localStoreName: String?, date: String? = "") {
        super.init()
        self.messageContext = "[图片]"
        self.messgaeContentType = .Image
        self.chatSendId = IMSessionManager.sharedSessionManager.currentUserProfile!.jidId
        self.nickName = ""
        self.date = date
        self.timeStamp = date
        self.imageHeight = String.init(format: "%.2f",imageHeight!)
        self.imageWidth = String.init(format: "%.2f", imageWidth!)
        self.localStoreName = localStoreName
        self.chatReceivedId = receivedId
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(chatSendId, forKey: kChatSendId)
        aCoder.encode(chatReceivedId, forKey: kChatReceivedId)
        aCoder.encode(messageContext, forKey: kMessageContext)
        aCoder.encode(messgaeContentType.rawValue, forKey: kMessgaeContentType)
        aCoder.encode(fromMe, forKey: kFromMe)
        #if TARGET_OS_IOS
        aCoder.encode(richTextLayout, forKey: kRichTextLayout)
        aCoder.encode(richTextLinePositionModifier, forKey: kRichTextLinePositionModifier)
        #endif
        aCoder.encode(richTextAttributedString, forKey: kRichTextAttributedString)
        aCoder.encode(Float(cellHeight), forKey: kCellHeight)
        aCoder.encode(nickName, forKey: kNickName)
        aCoder.encode(date, forKey: kDate)
        aCoder.encode(timeStamp, forKey: kTimeStamp)
        aCoder.encode(imageHeight,forKey: kimageHeight)
        aCoder.encode(imageWidth,forKey: KimageWidth)
        aCoder.encode(localStoreName,forKey: klocalStoreName)
        aCoder.encode(photoFilePath,forKey: kphotoFilePath)
        aCoder.encode(filePath,forKey: kfilePath)
        aCoder.encode(fileName,forKey: KfileName)
        aCoder.encode(fileSize,forKey: kfileSize)
        aCoder.encode(DiskImageName,forKey: kDiskImagePath)
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        chatSendId = aDecoder.decodeObject(forKey: kChatSendId) as! String?
        chatReceivedId = aDecoder.decodeObject(forKey: kChatReceivedId) as! String?
        messageContext = aDecoder.decodeObject(forKey: kMessageContext) as! String?
        messgaeContentType = MessageContentType(rawValue: aDecoder.decodeObject(forKey: kMessgaeContentType) as! String)!
        fromMe = aDecoder.decodeBool(forKey: kFromMe)
        #if TARGET_OS_IOS
        richTextLayout = aDecoder.decodeObject(forKey: kRichTextLayout) as! YYTextLayout?
        richTextLinePositionModifier = aDecoder.decodeObject(forKey: kRichTextLinePositionModifier) as! IMYYTextLinePostionModifier?
        #endif
        richTextAttributedString = aDecoder.decodeObject(forKey: kRichTextAttributedString) as! NSMutableAttributedString?
        cellHeight = CGFloat(aDecoder.decodeFloat(forKey: kCellHeight))
        nickName = aDecoder.decodeObject(forKey: kNickName) as! String?
        date = aDecoder.decodeObject(forKey: kDate) as! String?
        timeStamp = aDecoder.decodeObject(forKey: kTimeStamp) as! String?
        imageHeight = aDecoder.decodeObject(forKey: kimageHeight) as! String?
        imageWidth = aDecoder.decodeObject(forKey: KimageWidth) as! String?
        localStoreName = aDecoder.decodeObject(forKey: klocalStoreName) as! String?
        photoFilePath = aDecoder.decodeObject(forKey: kphotoFilePath) as! String?
        filePath = aDecoder.decodeObject(forKey: kfilePath) as! String?
        fileName = aDecoder.decodeObject(forKey: KfileName) as! String?
        fileSize = aDecoder.decodeObject(forKey: kfileSize) as! String?
        DiskImageName = aDecoder.decodeObject(forKey: kDiskImagePath) as! String?
        
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
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss:SSS"
        return dateFormatter.string(from: date)
    }
    
    //单聊
    func chatToMessageList()->IMMessageList{
        var id: String?
        if fromMe{
            id = "\(self.chatReceivedId!)+\(self.self.chatSendId!)"
        }else{
            id = "\(self.chatSendId!)+\(self.chatReceivedId!)"
        }
        let messageList = IMMessageList(id: id, message: self.messageContext)
        messageList.date = self.date
        return messageList
    }

}
