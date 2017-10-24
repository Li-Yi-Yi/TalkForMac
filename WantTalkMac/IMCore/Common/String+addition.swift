//
//  String+addition.swift
//  IM
//
//  Created by 林海生 on 2017/5/18.
//  Copyright © 2017年 want. All rights reserved.
//

import Cocoa

extension String {
    
    /**
     *  获取小写首字母
     */
    func lowerInitials()->String{
        return self.getInitials().lowercased()
    }
    
    /**
     *  获取大写首字母
     */
    func upperInitials()->String{
        return self.getInitials().uppercased()
    }
    
    /**
     *  获取首字母
     */
    func getInitials()->String{
        let mutableStr = NSMutableString()
        mutableStr.append(self)
        CFStringTransform(mutableStr, nil, kCFStringTransformMandarinLatin, false)
        return mutableStr.substring(to: 1)
    }
    
    

}

extension String{
    
    func stringToDate()->Date?{
        //        let d: NSDate!
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        
        if let date = format.date(from: self){
            return date
        }
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = format.date(from: self){
            return date
        }
        format.dateFormat = "MM-dd HH:mm:ss:SSS"
        if let date = format.date(from: self){
            return date
        }
        
        format.dateFormat = "MM-dd HH:mm:ss"
        if let date = format.date(from: self){
            return date
        }
        
        return nil
    }
    
    //时间处理
    func getHHmm()-> String{
        guard let data = self.stringToDate() else {
            return ""
        }

        if Date.getThisYear() == Int(data.year)!{
            return data.mdHs
        }
        
        return data.ymdHm
    }
}


extension String{
    
    //截取字段
    func substringRange(start: Int,end: Int)-> String{
        var xend = end
        if self.characters.count < 19{
             xend -= 5
        }
        let range: Range = self.index(self.startIndex, offsetBy: start)..<self.index(self.startIndex, offsetBy: xend)
        return self.substring(with: range)
    }
    
    
    //转换位NSString
    func useNs()->NSString{
        let ns: NSString = self as NSString
        return ns
    }
    
    //去除最后一个字母
    func substringLast()->String{
        var ns = self.useNs()
        
        if ns.length > 0{
            ns = ns.substring(to: ns.length-1) as NSString
        }
        
        return ns as String
    }
    
}



extension Date{
    var year: String{
        let format = DateFormatter()
        format.dateFormat = "yyyy"
        return format.string(from: self)
    }
    
    var yearInt: Int{
        return Int(self.year)!
    }
    
    var month: String{
        let format = DateFormatter()
        format.dateFormat = "MM"
        return format.string(from: self)
    }
    
    var monthInt: Int{
        return Int(self.month)!
    }
    
    var day: String{
        let format = DateFormatter()
        format.dateFormat = "dd"
        return format.string(from: self)
    }
    
    var dayInt: Int{
        return Int(self.day)!
    }
    
    var mdhm: String{
        let format = DateFormatter()
        format.dateFormat = "MM-dd HH:mm:ss"
        return format.string(from: self)
    }
    var mdHs: String{
        let format = DateFormatter()
        format.dateFormat = "MM-dd HH:mm"
        return format.string(from: self)
    }
    //年月日时分
    var ymdHm: String{
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        return format.string(from: self)
    }
    
    //年月日
    var ymd: String{
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.string(from: self)
    }
    
    //年月
    var ym: String{
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM"
        return format.string(from: self)
    }
    //月日
    var md: String{
        let format = DateFormatter()
        format.dateFormat = "MM-dd"
        return format.string(from: self)
    }
    //时分
    var hm: String{
        let format = DateFormatter()
        format.dateFormat = "HH:mm"
        return format.string(from: self)
    }
    
    //时
    var hh: String{
        let format = DateFormatter()
        format.dateFormat = "HH"
        return format.string(from: self)
    }
    
    //星期
    var weekInt: Int{
        let interval = self.timeIntervalSince1970
        let days = Int(interval / 86400)
        return (days - 3) % 7
    }
    
    //今年
    static func getThisYear()-> Int{
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return Int(dateFormatter.string(from: date))!
    }
    
}
