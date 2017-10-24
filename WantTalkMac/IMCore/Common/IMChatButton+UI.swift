//
//  TSChatButton+UI.swift
//  TSWeChat
//
//  Created by Hilen on 12/30/15.
//  Copyright © 2015 Hilen. All rights reserved.
//



// MARK: - @extension TSChatButton
extension UIButton {
  
    
    /**
     控制——表情按钮和键盘切换的图标变化
     
     - parameter showKeyboard: 是否显示键盘
     */
    func replaceEmotionButtonUI(showKeyboard: Bool) {

        if showKeyboard {
            self.setBackgroundImage(UIImage(named: "chat_emotion_keyboard_unhighlight"), for: .normal)
            self.setBackgroundImage(UIImage(named: "chat_emotion_keyboard_highlight"), for: .highlighted)
        } else {
            self.setBackgroundImage(UIImage(named: "tool_emotion_1"), for: .normal)
            self.setBackgroundImage(UIImage(named: "tool_emotion_2"), for: .highlighted)
        }
    }
    
  
}


