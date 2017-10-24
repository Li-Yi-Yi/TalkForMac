//
//  IMModel.swift
//  IM_Swift
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 wangwang. All rights reserved.
//



/**
 *  消息内容类型：
    0 - 文本
    1 - 图片
    2 - 语音
    3 - 群组提示消息：列如 高必犯邀请白琳，彭英加入群聊
    4 - 文件
    110 - 时间
 */
enum MessageContentType: String {
    case Text = "0"
    case Image = "1"
    case Voice = "2"
    case System = "3"
    case File = "4"
    case Time = "110"
}

enum MessageDownType: Int{
    case Loading = 0  //正在下载
    case Success = 1 //下载成功
    case Failed = 2   //下载失败
}

enum MessageSendType: Int{
    case Loading = 0  //正在上传
    case Success = 1 //上传成功
    case Failed = 2   //上传失败
}

