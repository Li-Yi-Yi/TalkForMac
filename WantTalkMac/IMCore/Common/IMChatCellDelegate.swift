//
//  IMChatCellDelegate.swift
//  IM_Swift
//
//  Created by 刘表聪 on 16/11/4.
//  Copyright © 2016年 wangwang. All rights reserved.
//

import Foundation

@objc protocol IMChatCellDelegate: NSObjectProtocol {
    
    /**
     *  点击 cell 本身
     */
    @objc optional func cellDidTap(cell: IMChatBaseCell)
    
    /// 点击了 文件cell
    ///
    /// - Parameter model: 传入文件需要的模型数据
    func cellDidTapedFileContentView(_ model: IMChat)
    
    /**
     *  点击了 cell 的头像
     */
    @objc optional func cellDidTapedAvatarIamge(cell: IMChatBaseCell)
    
    /**
     点击了 cell 的图片
     */
    func cellDidTapedImageView(_ cell: IMChat, _ imageView: UIImageView)
    
    /*
     *长按图片删除
     */
    func cellDidLongTapGestureImageView(imChatModel: IMChat,cell: TSChatImageCell)
    
    /*
     *长按文件删除
     */
    func cellDidLongTapGestureFile(imChatModel: IMChat,cell: IMChatFileCell)
    
    /**
     *  点击cell的中文字的URL
     */
    @objc optional func cellDidTapedLink(cell: IMChatBaseCell, linkString: String)
    
    /**
     *  点击cell的中文字的电话
     */
    @objc optional func cellDidTapedPhone(cell: IMChatBaseCell, phoneString: String)
    
}
