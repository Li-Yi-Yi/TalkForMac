//
//  IMMessageList2.swift
//  IM
//
//  Created by 林海生 on 2017/5/23.
//  Copyright © 2017年 want. All rights reserved.
//

 
import Realm
import RealmSwift

//消息列表
class IMMessageList2: Object {
    dynamic var userId: String? = nil      // 好友id 或者 群Id
    dynamic var nickName: String = ""       // 消息名称
    dynamic var unreadMesNumber = 0    // 未读消息数目
    dynamic var header = NSData()     // 头像
    dynamic var isGroupChat: Bool = false //是否是群聊
    dynamic var isShowTip: Bool = true //是否显示未读数
    dynamic var date: String = ""
    dynamic var timeStamp: String = ""
    dynamic var recentMessage: String = "" //最新消息
    
    dynamic var draft: String = ""  //草稿
//    let chats = List<IMChat>()       //聊天内容

    
    convenience init(userId: String?,message: String?,nickName: String){
        self.init()
        self.userId = userId
        self.recentMessage = message == nil ? "" :  message!
        self.nickName = nickName
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
    
    override static func primaryKey()-> String {// 主键
        return "userId"
    }
    
}
