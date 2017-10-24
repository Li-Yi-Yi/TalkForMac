//
//  IMFriendDetail.swift
//  IM
//
//  Created by 刘表聪 on 16/11/22.
//  Copyright © 2016年 want. All rights reserved.
//

import Foundation

/**
 *  好友详情model
 */
class IMFriendDetail: NSObject {
    
    var name: String?          // 姓名
    var id: String?            // 工号  没有@coop结尾
    var position: String?      // 职务
    var post: String?          // 岗位
    var phoneNumber: String?   // 分机
    var charge: String?        // 主管
    var orgnization: String?   // 组织
    var email: String?         // 邮箱
    var gender: String?        // 性别  1：男  2：女
    
    override init() {
        super.init()
    }
    
    // 初始化
    init(name: String?, id: String?, orgnization: String?) {
        self.name = name
        self.id = id
        self.orgnization = orgnization
    }
    
    // 初始化
    init(name: String?, id: String?, position: String?, post: String?, phoneNumber: String?, charge: String?, orgnization: String?, email: String?, gender: String?) {
        self.name = name
        self.id = id
        self.position = position
        self.post = post
        self.phoneNumber = phoneNumber
        self.charge = charge
        self.orgnization = orgnization
        self.email = email
        self.gender = gender
    }
    
    
    

}
