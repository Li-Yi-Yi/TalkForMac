//
//  IMChatTextParser.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

// 
import YYText

public let kChatTextKeyPhone = "phone"
public let kChatTextKeyURL = "URL"

class IMChatTextParser: NSObject {
    
    class func parseText(text: String, font: UIFont) -> NSMutableAttributedString? {
        if text.characters.count == 0 {
            return nil
        }
        
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedText.yy_font = font
        attributedText.yy_color = UIColor.black
        
        // 匹配电话
        self.enumeratePhoneParser(attributedText: attributedText)
        // 匹配URL
        self.enumerateURLParser(attributedText: attributedText)
        // 匹配[表情]
        self.enumerateEmotionParser(attributedText: attributedText, fontSize: font.pointSize)
        return attributedText
    }
    
    /**
     *  匹配电话
     *  parameter attributedText: 富文本
     */
    private class func enumeratePhoneParser(attributedText: NSMutableAttributedString) {
        let phoneResults = IMChatTextParserHelper.regexPhoneNumber.matches(in: attributedText.string, options: [.reportProgress], range: attributedText.yy_rangeOfAll())
        for phone: NSTextCheckingResult in phoneResults {
            if phone.range.location == NSNotFound && phone.range.length <= 1 {
                continue
            }
            
            let highlightBorder = IMChatTextParserHelper.highlightBorder
            if (attributedText.yy_attribute(YYTextHighlightAttributeName, at: UInt(phone.range.location)) == nil) {
                attributedText.yy_setColor(UIColor("#1F79FD"), range: phone.range)
                let highlight = YYTextHighlight()
                highlight.setBackgroundBorder(highlightBorder)
                
                let stringRange = attributedText.string.RangeFromNSRange(nsRange: phone.range)!
                highlight.userInfo = [kChatTextKeyPhone : attributedText.string.substring(with: stringRange)]
                attributedText.yy_setTextHighlight(highlight, range: phone.range)
            }
        }
    }
    
    /**
     *  匹配URL
     *  parameter attributedText: 富文本
     */
    private class func enumerateURLParser(attributedText: NSMutableAttributedString) {
        let URLsResults = IMChatTextParserHelper.regexURLs.matches(in: attributedText.string, options: [.reportProgress], range: attributedText.yy_rangeOfAll())
        for URL: NSTextCheckingResult in URLsResults {
            if URL.range.location == NSNotFound && URL.range.length <= 1 {
                continue
            }
            
            let highlightBorder = IMChatTextParserHelper.highlightBorder
            if (attributedText.yy_attribute(YYTextHighlightAttributeName, at: UInt(URL.range.location)) == nil) {
                attributedText.yy_setColor(UIColor("#1F79FD"), range: URL.range)
                let highlight = YYTextHighlight()
                highlight.setBackgroundBorder(highlightBorder)
                
                let stringRange = attributedText.string.RangeFromNSRange(nsRange: URL.range)!
                highlight.userInfo = [kChatTextKeyURL : attributedText.string.substring(with: stringRange)]
                attributedText.yy_setTextHighlight(highlight, range: URL.range)
            }
        }
    }
    
    /**
     *  匹配 [表情]
     */
    private class func enumerateEmotionParser(attributedText: NSMutableAttributedString, fontSize: CGFloat) {
        let emotionResults = IMChatTextParserHelper.regexEmotions.matches(in: attributedText.string, options: [.reportProgress], range: attributedText.yy_rangeOfAll())
        
        var emoClipLength: Int = 0
        for emotion: NSTextCheckingResult in emotionResults {
            if emotion.range.location == NSNotFound && emotion.range.length <= 1 {
                continue
            }
            var range: NSRange = emotion.range
            range.location -= emoClipLength
            if (attributedText.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)) != nil) {
                continue
            }
            if (attributedText.yy_attribute(YYTextAttachmentAttributeName, at: UInt(range.location)) != nil) {
                continue
            }
            
            let imageName = attributedText.string.substring(with: attributedText.string.RangeFromNSRange(nsRange: range)!)
            guard let theImageName = IMEmojiDictionary[imageName]  else {
                continue
            }
            
            // 表情的文件名称
            let imageString = "\(IMConfig.ExpressionBundleName)/\(theImageName)"
            let emojiText = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: imageString)!, fontSize: fontSize + 1)
            attributedText.replaceCharacters(in: range, with: emojiText!)
            
            emoClipLength += range.length - 1
        }
    }
}


class IMChatTextParserHelper {
    // 高亮的文字背景色
    class var highlightBorder: YYTextBorder {
        get {
            let highlightBorder = YYTextBorder()
            highlightBorder.insets = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
            highlightBorder.fillColor = UIColor("#D4D1D1")
            return highlightBorder
        }
    }
    
    /**
     *  正则：匹配 [哈哈] [笑哭..] 表情
     */
    class var regexEmotions: NSRegularExpression {
        get {
            let regularExpression = try! NSRegularExpression(pattern: "\\[[^\\[\\]]+?\\]", options: [.caseInsensitive])
            return regularExpression
        }
    }
    
    /**
     正则：匹配 www.a.com 或者 http://www.a.com 的类型
     
     ref: http://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
     */
    class var regexURLs: NSRegularExpression {
        get {
            let regex: String = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|^[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+([-A-Z0-9a-z_\\$\\.\\+!\\*\\(\\)/,:;@&=\\?~#%]*)*"
            let regularExpression = try! NSRegularExpression(pattern: regex, options: [.caseInsensitive])
            return regularExpression
        }
    }
    
    /**
     正则：匹配 7-25 位的数字, 010-62104321, 0373-5957800, 010-62104321-230
     */
    class var regexPhoneNumber: NSRegularExpression {
        get {
            let regex = "([\\d]{7,25}(?!\\d))|((\\d{3,4})-(\\d{7,8}))|((\\d{3,4})-(\\d{7,8})-(\\d{1,4}))"
            let regularExpression = try! NSRegularExpression(pattern: regex, options: [.caseInsensitive])
            return regularExpression
        }
    }
}

private extension String {
    func NSRangeFromRange(range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distance(to: from), from.distance(to: to))
    }
    
    func RangeFromNSRange(nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
}


