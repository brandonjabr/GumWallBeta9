//
//  Utilities.h
//  Gum Wall
//
//  Created by Apple on 26/12/2014.
//  Copyright (c) 2014 AMP, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

#define IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

+ (Utilities*)sharedInstance;

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString*)msg;

- (void)setBOOL:(BOOL)value forKey:(NSString*)key;
- (BOOL)getBOOLForKey:(NSString*)key;

- (void)setString:(NSString*)value forKey:(NSString *)key;
- (NSString*)getStringForKey:(NSString*)key;
- (NSString *)getElapsedTime:(NSDate *)pastDate;
- (UITableView*)tableViewFromCell:(UITableViewCell*)cell;

@end
