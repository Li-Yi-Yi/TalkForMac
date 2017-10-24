//
//  NSObject+addition.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

import Cocoa

extension NSObject {
    class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last! as String
    }
    
    // 用于获取 cell 的 reuse identifier
    class var identifier: String {
        return String(format: "%@_identifier", self.nameOfClass)
    }
}
