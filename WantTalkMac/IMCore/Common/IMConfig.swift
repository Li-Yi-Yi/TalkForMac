//
//  IMConfig.swift
//  IM_Swift
//
//  Created by 刘表聪 on 16/11/4.
//  Copyright © 2016年 wangwang. All rights reserved.
//

import Foundation

/**
 *  得到表情文件对应的路径
 */
class IMConfig {
    static let testUserID = "wx1234skjksmsjdfwe234"
    static let ExpressionBundle = Bundle(url: Bundle.main.url(forResource: "Expression", withExtension: "bundle")!)
    static let ExpressionBundleName = "Expression.bundle"
    static let ExpressionPlist = Bundle.main.path(forResource: "Expression", ofType: "plist")
}
