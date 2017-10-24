//
//  IMOrgnization.swift
//  IM
//
//  Created by 刘表聪 on 17/3/14.
//  Copyright © 2017年 want. All rights reserved.
//

import Foundation

/**
 *  组织model
 */
class IMOrgnization: NSObject {
    
    var name: String?          // 姓名
    var id: String?            // 工号
    var orgnization: String?   // 组织
    var isEmployee: Bool = false      // 是否是员工
    var department: String?    // 部门
    var departmentId: String?  // 部门id
    
    init(name: String?, id: String?, orgnization: String?) {
        super.init()
        self.name = name
        self.id = id
        self.orgnization = orgnization
        self.isEmployee = true
    }
    
    init(department: String?, departmentId: String?) {
        super.init()
        self.department = department
        self.departmentId = departmentId
        self.isEmployee = false
    }
}
