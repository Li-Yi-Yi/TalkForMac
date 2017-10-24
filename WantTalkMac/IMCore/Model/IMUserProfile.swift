//
//  IMUserProfile.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

import Cocoa

let kUserIdKey: String = "userId"
let kPasswordKey: String = "password"
let kJid: String = "jidId"

/**
 *  用户一些基本信息model
 */
class IMUserProfile: NSObject, NSCoding {

    var userId: String?    // 用户id 工号
    var password: String?  // 用户密码
    var jidId: String?     // 用户jid
    
    init(id: String?, password: String?) {
        self.userId = id
        self.password = password
        self.jidId = id! + "@coop"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: kUserIdKey)
        aCoder.encode(password, forKey: kPasswordKey)
        aCoder.encode(jidId, forKey: kJid)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        userId = aDecoder.decodeObject(forKey: kUserIdKey) as! String?
        password = aDecoder.decodeObject(forKey: kPasswordKey) as! String?
        jidId = aDecoder.decodeObject(forKey: kJid) as! String?
    }

}



