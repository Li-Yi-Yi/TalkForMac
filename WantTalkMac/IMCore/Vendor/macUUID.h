//
//  macUUID.h
//  TalkClient
//
//  Created by 吳淑菁 on 2017/9/12.
//
//
// macOS has no device unique id. Use MAC address instead.

#import <Foundation/Foundation.h>

@interface macUUID : NSObject

+(NSString *)getMacIndentifier;

@end
