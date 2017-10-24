//
//  IMYYTextLinePostionModifier.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

import YYText

private let ascentScale: CGFloat = 0.84
private let descentScale: CGFloat = 0.16

class IMYYTextLinePostionModifier: NSObject, YYTextLinePositionModifier {
    
    internal var font: UIFont // 基准字体 (例如 Heiti/SC/PingFang SC)
    private var PaddingTop: CGFloat = 2.0 // 文本顶部留白
    private var PaddingBottom: CGFloat = 2.0 // 文本底部留白
    private var lineHeightMultiple: CGFloat // 行距倍数
    
    required init(font: UIFont) {
        
        if ((UIDevice.current.systemVersion as NSString).floatValue >= 9.0) {
            self.lineHeightMultiple = 1.23
        } else {
            self.lineHeightMultiple = 1.1925
        }
        self.font = font
        super.init()
    }
    
    // MARK: @delegate YYTextLinePostionModifier
    func modifyLines(_ lines: [YYTextLine], fromText text: NSAttributedString, in container: YYTextContainer) {
        let ascent: CGFloat = self.font.pointSize * ascentScale
        let lineHeight: CGFloat = self.font.pointSize * self.lineHeightMultiple
        for line: YYTextLine in lines {
            var position: CGPoint = line.position
            position.y = self.PaddingTop + ascent + CGFloat(line.row) * lineHeight
            line.position = position
        }
    }
    
    // MARK: @delegate NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let one = type(of: self).init(font: self.font)
        return one
    }
    
    func heightForLineCount(lineCount: Int) -> CGFloat {
        if lineCount == 0 {
            return 0
        }
        let ascent: CGFloat = self.font.pointSize * ascentScale
        let descent: CGFloat = self.font.pointSize * descentScale
        let lineHeight: CGFloat = self.font.pointSize * self.lineHeightMultiple
        return self.PaddingTop + self.PaddingBottom + ascent + descent + CGFloat(lineCount - 1) * lineHeight
    }
}




