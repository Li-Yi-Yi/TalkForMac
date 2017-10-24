//
//  NSImage+Extension.swift
//  TalkClient
//
//  Created by 吳淑菁 on 2017/9/12.
//
//
// Convenient functions for converting NSImage to PNG/JPG file

import Foundation
import AppKit

extension NSBitmapImageRep {
    var png: Data? {
        return representation(using: .PNG, properties: [:])
    }
    
    var jpg: Data? {
        
        return representation(using: .JPEG, properties: [NSImageCompressionFactor:1.0])
    }
}

extension Data {
    var bitmap: NSBitmapImageRep? {
        return NSBitmapImageRep(data: self)
    }
}

extension NSImage {
    
    var png: Data? {
        return tiffRepresentation?.bitmap?.png
    }
    var jpg: Data? {
        return tiffRepresentation?.bitmap?.jpg
    }
    
    func savePNG(to url: URL) -> Bool {
        do {
            try png?.write(to: url)
            return true
        } catch {
            print(error)
            return false
        }
        
    }
    
    func saveJPG(to url: URL) -> Bool {
        do {
            try jpg?.write(to: url)
            return true
        } catch {
            print(error)
            return false
        }
        
    }
    
    func im_imageToResizeWithSize(size: CGSize) -> NSImage? {
        
        let newImage =  NSImage(size: size)
        newImage.lockFocus()
        self.draw(in: NSMakeRect(0, 0, size.width, size.height),
                  from: NSMakeRect(0, 0, self.size.width, self.size.height),
                  operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    
    
}
