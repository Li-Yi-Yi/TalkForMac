//
//  AESHelper.h
//  Journey
//
//  Created by Yen on 2015/10/16.
//
//

#import <Foundation/Foundation.h>

@interface AESHelper : NSObject

+ (NSString*) AES128Encrypt:(NSString *)plainText  withKey:(NSString*)key;

+ (NSString*) AES128Decrypt:(NSString *)encryptText  withKey:(NSString*)key;

@end
