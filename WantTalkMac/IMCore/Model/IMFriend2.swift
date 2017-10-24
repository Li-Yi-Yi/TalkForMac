//
//  IMFriend2.swift
//  IM
//
//  Created by 林海生 on 2017/5/19.
//  Copyright © 2017年 want. All rights reserved.
//

 
import RealmSwift
import Realm

//好友
class IMFriend2: Object {
    dynamic var userId: String? = nil    // 好友id
    dynamic var jidId: String? = nil     // Jid带 userId@coop
    dynamic var name: String = ""  // 好友姓名
    dynamic var nickName: String? = nil  // 好友备注名
    dynamic var myId: String = ""  //谁的好友 (区分使用备注名还是姓名)
    dynamic var unOnline: Bool = false   // 是否不在线  (使用realm自带排序，需要倒序使用)
    dynamic var initials: String? = nil  // 首字母(排序)
    dynamic var header = NSData()        // 头像 ???
    
    convenience init(id: String, nickName: String?) {  // 初始化
        self.init()
        self.userId = id.components(separatedBy: "@").first
        self.jidId = id
        self.nickName = nickName
        self.unOnline = true
        self.initials = self.nickName?.lowerInitials()
        self.myId = IMSessionManager.sharedSessionManager.username!
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
    
    override static func primaryKey()-> String {//主键
        return "userId" // 必须是属性，必须是不一样的内容
    }
}
