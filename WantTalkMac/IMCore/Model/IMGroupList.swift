//
//  IMGroupList.swift
//  BPM-T
//
//  Created by 刘表聪 on 16/12/23.
//  Copyright © 2016年 com.want.mis.wantworld. All rights reserved.
//

import Foundation

/**
 *  分组管理列表model
 */
class IMGroupList: NSObject {
    var groupName: String?     // 旧的分组名
    var newGroupName: String?  // 新的分组名
    
    init(groupName: String?, newGroupName: String?) {
        self.groupName = groupName
        self.newGroupName = newGroupName
    }
}
