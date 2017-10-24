//
//  IMMessageManager.swift
//  IM
//
//  Created by 林海生 on 2017/5/23.
//  Copyright © 2017年 want. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class IMMessageManager: NSObject {
    
    let realm = try! Realm()
    // MARK: @单例
    static let sharedMessageManager: IMMessageManager  = { IMMessageManager() }()
    
    //异步存入数据库(异步线程中执行数据库操作时使用)
    func asyncAddOffLineMessage(message: IMChat, isOwn: Bool,roomName: String? = nil,callback: @escaping (RealmSwift.Realm?, Error?) -> Swift.Void){
         Realm.asyncOpen { (realm, error) in
            if let realm = realm {
                self.addOffLineMessage(message: message, isOwn: isOwn,roomName: roomName)
                callback(realm, nil)
            } else if let error = error {
                callback(nil, error)
                // 处理打开 Realm 时所发生的错误
            }
        }
    }
    
    //离线消息存入本地
    func addOffLineMessage(message: IMChat, isOwn: Bool,roomName: String? = nil){
        message.fromMe = isOwn
        let userId = message.fromMe ? message.chatReceivedId :message.chatSendId
        let myId =  message.fromMe ? message.chatSendId :message.chatReceivedId
        let id = "\(userId!)+\(myId!)"
        message.userId = id
        var hasFriend = true
        let friendPredicate = NSPredicate(format: "userId = %@", id.components(separatedBy: "@coop").first!)
        let friend = realm.objects(IMFriend2.self).filter(friendPredicate)
        
        if roomName == nil{
            //单聊则在好友中查询name
            if friend.count > 0{
                if friend.first!.myId == IMSessionManager.sharedSessionManager.username!{
                     message.nickName = friend.first?.nickName == nil ? "" : friend.first!.nickName!
                }else{
                    hasFriend = false
                    message.nickName = id.components(separatedBy: "@coop").first!
                }
            }else{ //不存在数据库暂时显示为id
                hasFriend = false
                message.nickName = id.components(separatedBy: "@coop").first!
            }
        }

        let predicate = NSPredicate(format: "userId = %@", id)
        //查询当前帐号下，是否存在消息
        let oldObject = realm.objects(IMMessageList2.self).filter(predicate)
        if oldObject.count > 0{
            do{
                try realm.write { //更新聊天列表的数据
                    realm.add(message)
                    oldObject.first?.recentMessage = message.messageContext!
                    oldObject.first?.date = message.date!
                    oldObject.first?.timeStamp = message.date!
                    oldObject.first?.nickName = message.nickName!
                    if roomName != nil{
                        oldObject.first?.nickName = roomName!
                    }
                    if oldObject.first!.isShowTip && !message.fromMe{
                        oldObject.first?.unreadMesNumber += 1
                    }else{
                        oldObject.first?.unreadMesNumber = 0
                    }
                }
            }catch{
                log.error("新消息添加--Realm数据库报错")
            }
        }else{
            //不存在聊天列表则新增聊天列表
            let messageList = IMMessageList2(userId: id, message: message.messageContext,nickName: message.nickName!)
            messageList.date = message.date!
            messageList.timeStamp = message.date!
            if !message.fromMe{
                messageList.unreadMesNumber = 1
            }
            if roomName != nil{ //为群聊时，名称为 roomName
                messageList.nickName = roomName!
                messageList.isGroupChat = true
            }
            do{
                try realm.write {
                    
                    realm.add(message)
                    realm.add(messageList, update: true)
                }
            }catch{
                log.error("消息列表更新--Realm数据库报错")
            }
        }
        
        if !hasFriend{
            IMObjectManager.sharedObjectManager.taskToFetchFriendDetail(id: userId!.components(separatedBy: "@").first!).continueWith { (task) in //调用接口修改姓名
                if task.error == nil {
                    let friend = IMFriend2(id: task.result!.first!.id!+"@coop", nickName: (task.result!.first!.name)!)
                    friend.name = (task.result!.first!.name)!
                    IMFriendsManager.sharedFriendManager.addfriend(friend: friend,isInterim: true) //用户信息存储。
                }
            }
        }
    }
    
    //修改消息状态(发送)
    func updateSendImageType(type: Int, predicate: NSPredicate){
        let realm = try! Realm()
        let objects = realm.objects(IMChat.self).filter(predicate)
        if objects.count > 0{
            do{
                try realm.write {
                    objects.first!.messageSendType = type
                }
            }catch{
                log.error("图片状态更新--Realm数据库报错")
            }
        }
    }
    
    //获取本地离线消息
    func getLocalOffLineMessage(friendId: String)-> Results<IMChat>{
        let realm = try! Realm()
        let predicate = NSPredicate(format: "userId = %@", friendId)
        let objects = realm.objects(IMChat.self).filter(predicate)
        return objects
    }
    
    //修改分组名
    func updateNickName(friendId: String,nickName: String){
        let predicate = NSPredicate(format: "userId = %@", "\(friendId)@coop+\(IMSessionManager.sharedSessionManager.username!)@coop")
        let messageLists = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        
        if messageLists.count > 0{
            do{
                let realm = try Realm()
                realm.beginWrite()
                (messageLists.first as! IMMessageList2).nickName = nickName
                try realm.commitWrite()
            }catch{
                log.error("修改分组名--Realm数据库报错")
            }
        }
    }
    
    //删除对应对话
    func deleteMsg(id: String, chat: IMChat){
        let predicate = NSPredicate(format: "userId = %@", id)
       
        let messageLists = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        let chats = IMRealmUtil.findObjects(predicate: predicate, object: IMChat.self)
        if messageLists.count > 0{
            let realm = try! Realm()
            let messagelist = (messageLists.first) as! IMMessageList2
            if chats.count == 1{ //只有一条时
                do {
                    try realm.write {
                   realm.delete(chat)
                   messagelist.recentMessage = ""
                    }
                }catch{
                    log.error("删除消息1--Realm数据库报错")
                }
                return
            }
            
            for (index,item) in chats.enumerated(){
                let localChat = item as! IMChat
                if localChat.messageContext == chat.messageContext! && localChat.date == chat.date!{
                    switch chat.messgaeContentType {
                    case .Image:
                        if localChat.photoName != chat.photoName{
                            break
                        }
                    case .File:
                        if localChat.fileName != chat.fileName{
                            break
                        }
                    default:
                        break
                    }
                    do {
                        try realm.write {
                            if index == chats.count-1 {
                            messagelist.recentMessage = (chats[index-1] as! IMChat).messageContext!
                            realm.delete(chat)
                            }else{
                                realm.delete(chat)
                            }
                        }
                    }catch{
                        log.error("删除消息2--Realm数据库报错")
                    }
                    return
                }
            }
        }
    }
    
    //删除消息列表
    func deleteMessageList(id: String){
        let realm = try! Realm()
        let predicate = NSPredicate(format: "userId = %@", id)
        let objects = realm.objects(IMMessageList2.self).filter(predicate)
        let chats = realm.objects(IMChat.self).filter(predicate)
        
        guard objects.count > 0 else {
            return
        }
        Realm.asyncOpen(callback: { (realm, error) in
            if let realm = realm{
                do{
                    try realm.write {
                        if chats.count > 0{
                            realm.delete(chats)
                        }
                        realm.delete(objects)
                    }
                }catch{
                    log.error("删除对话--Realm数据库报错")
                }
            }
        })
    }

    //未读数归零
    func unReadToZero(id: String){
        let predicate = NSPredicate(format: "userId = %@", id)
        let objects = realm.objects(IMMessageList2.self).filter(predicate)
        guard objects.count > 0 else {
            return
        }
        do{
            try realm.write {
                objects.first?.unreadMesNumber = 0
                objects.first?.isShowTip = false
            }
        }catch{
            log.error("删除对话--Realm数据库报错")
        }
    }
    
    func showTip(id: String){
        let predicate = NSPredicate(format: "userId = %@", id)
        let messageList  = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        guard messageList.count > 0 else {
            return
        }
        do{
            try realm.write {
                (messageList.first as! IMMessageList2).isShowTip = true
            }
        }catch{
            log.error("修改是否显示未读数--Realm数据库报错")
        }
    }
    
    func showAllTip(id: String){
        let predicate = NSPredicate(format: "userId CONTAINS '+\(id)@coop' AND isShowTip = %d",0)
        let messageList  = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        guard messageList.count > 0 else {
            return
        }
        do{
            try realm.write {
                for message in messageList{
                    (message as! IMMessageList2).isShowTip = true
                }
            }
        }catch{
            log.error("显示所有未读数--Realm数据库报错")
        }
    }
    
    //登录时修改未完成下载、未完成上传的图片为失败
    func loginUpdateImageType(id: String){
        let predicate = NSPredicate(format: "userId CONTAINS '+\(id)@coop' AND (messageDownType = %d OR messageSendType = %d)", 0, 0)
        let objects  = IMRealmUtil.findObjects(predicate: predicate, object: IMChat.self)
        if objects.count > 0{
            for item in objects{
                let realm = try! Realm()
                let chat =  item as! IMChat
                do{
                    try realm.write {
                        if chat.messageDownType == 0{
                            chat.messageDownType = 2
                        }
                        if chat.messageSendType == 0{
                            chat.messageSendType = 2
                        }
                    }
                }catch{
                     log.error("修改未完成下载--Realm数据库报错")
                }
            }
        }
    }
    //获取未读数
    func getUnReadNum(id: String)-> Int{
        let predicate = NSPredicate(format: "userId CONTAINS '+\(id)@coop'")
        let messageList  = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        guard messageList.count > 0 else {
            return 0
        }
        var unreadMesNumber = 0
        for message in messageList{
            unreadMesNumber += (message as! IMMessageList2).unreadMesNumber
        }
        return unreadMesNumber
    }
    
    //获取所有聊天列表
    func getAllMessageList(id: String)-> Results<Object>?{
        let predicate = NSPredicate(format: "userId CONTAINS '+\(id)@coop'")
        return IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
    }
    
    //获取所有群聊天列表
    func getGroupMessageList()-> Results<Object>?{
        let predicate = NSPredicate(format: "userId CONTAINS '@conference.coop'")
        let messageList  = IMRealmUtil.findObjects(predicate: predicate, object: IMMessageList2.self)
        guard messageList.count > 0 else {
            return nil
        }
        return messageList
    }
    
    //修改草稿
    func updateDraft(content: String?,id: String){
        let predicate = NSPredicate(format: "userId = %@", id)
        
        let chats = IMRealmUtil.findObjects(predicate: predicate, object: IMChat.self).sorted(byKeyPath: "date")
        
        guard let list = self.getAllMessageList(id: IMSessionManager.sharedSessionManager.username!)?.filter(predicate).first else{
            return
        }
        let msgList = list as! IMMessageList2
        if let text = content, text != ""{
            if msgList.draft == text {
                return
            }
            do{
                let realm = try Realm()
                if let text = content, text != ""{
                    try realm.write {
                        msgList.draft = text
                        msgList.date = IMXMPPManager.sharedXmppManager.getCurrentDate()
                    }
                }
            }catch{
                log.error("")
            }
        }else{
            do{
                let realm = try Realm()
                try realm.write {
                    msgList.draft = ""
                    if chats.count > 0{
                        msgList.date = (chats.last as! IMChat).date!
                    }else{
                        msgList.date = msgList.timeStamp == "" ? msgList.date : msgList.timeStamp
                    }
                }
            }catch{
                log.error("")
            }
        }
    }
}
