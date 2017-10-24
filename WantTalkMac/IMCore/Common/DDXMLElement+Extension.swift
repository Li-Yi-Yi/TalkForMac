//
//  DDXMLElement+Extension.swift
//  BPM-T
//
//  Created by Jim.Yen on 2016/12/28.
//  Copyright © 2016年 com.want.mis.wantworld. All rights reserved.
//

import KissXML

extension DDXMLElement {
    //通过索引获取子节点
    subscript(key: String) -> DDXMLElement {
        get {
            let r = self.forName(key)
            return r!
        }
    }
}
