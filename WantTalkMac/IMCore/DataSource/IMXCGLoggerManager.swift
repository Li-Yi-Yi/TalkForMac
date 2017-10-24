//
//  IMXCGLoggerManager.swift
//  IM
//
//  Created by 林海生 on 2017/6/26.
//  Copyright © 2017年 want. All rights reserved.
//

import Foundation
import XCGLogger


let log = XCGLogger.default

//日志打印
class IMXCGLoggerManager: NSObject {

    static let sharedLogManager: IMXCGLoggerManager  = { IMXCGLoggerManager() }()
    
    func logInstall(id: String){
        //控制台输出
        let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")
        
        //设置控制台输出的各个配置项
        systemDestination.outputLevel = .debug
        systemDestination.showLogIdentifier = false
        systemDestination.showFunctionName = true
        systemDestination.showThreadName = true
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = true
        
        //logger对象中添加控制台输出
        log.add(destination: systemDestination)
        
        
        //日志文件地址
        let logURL = self.createLogFile(id: id)
        
        let fileDestination = FileDestination(writeToFile: logURL,
                                              identifier: "advancedLogger.fileDestination",
                                              shouldAppend: true, appendMarker: "-- Relauched App --")
        //设置文件输出的各个配置项
        fileDestination.outputLevel = .debug
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = true
        fileDestination.showThreadName = true
        fileDestination.showLevel = true
        fileDestination.showFileName = true
        fileDestination.showLineNumber = true
        fileDestination.showDate = true
        
        
        //文件输出在后台处理
        fileDestination.logQueue = XCGLogger.logQueue
        
        //logger对象中添加控制台输出
        log.add(destination: fileDestination)
        
        //开始启用
        log.logAppDetails()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale.current
        log.dateFormatter = dateFormatter
        
        #if DEBUG
            log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
        #else
            log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
        #endif
        
        
        NSSetUncaughtExceptionHandler { (exception) in
            let arr:NSArray = exception.callStackSymbols as NSArray//得到当前调用栈信息
            let reason = exception.reason//非常重要，就是崩溃的原因
            let name = exception.name//异常类型
            let content =  String("===异常错误报告===:name:\(name)===\n==reson:\(reason!)==\n==ncallStackSymbols:\n\(arr.componentsJoined(by: "\n"))")
            log.error("exception type : \(name) \n crash reason : \(reason!) \n call stack info : \(arr)====content-->\(content ?? "")")
        }
    }
    
    func createLogFile(id: String)-> URL{
        //日志文件地址
        let cachePath = FileManager.default.urls(for: .cachesDirectory,
                                                 in: .userDomainMask)[0]
        let date: Date = Date()
        let fileFormatter: DateFormatter = DateFormatter()
        fileFormatter.dateFormat = "YYYY-MM-dd"
        let filePath = fileFormatter.string(from: date)+".txt"
        
        //日志文件地址
        let logURL = cachePath.appendingPathComponent("\(id)/\(filePath)")
        
        //日志文件夹地址
        let myDirectory = cachePath.appendingPathComponent("\(id)")
        
        do{
            try FileManager.default.createDirectory(at: myDirectory, withIntermediateDirectories: true, attributes: nil)
        }catch{
            log.error("log日志文件夹创建失败")
        }
        return logURL
    }
}

