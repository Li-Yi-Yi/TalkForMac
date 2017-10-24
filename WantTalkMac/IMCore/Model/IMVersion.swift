//
//  IMVersion.swift
//  IM
//
//  Created by 刘表聪 on 17/2/28.
//  Copyright © 2017年 want. All rights reserved.
//

import Foundation

/**
 *  版本号Model
 */
class IMVersion: NSObject {
    
    var version: String?      // 版本号
    var downLoadURL: String?  // 下载地址
    
    init(version: String?, url: String?) {
        super.init()
        self.version = version
        self.downLoadURL = url
    }

}
