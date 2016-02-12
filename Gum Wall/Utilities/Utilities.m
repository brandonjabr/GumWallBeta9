//
//  Utilities.m
//  Gum Wall
//
//  Created by Apple on 26/12/2014.
//  Copyright (c) 2014 AMP, Inc. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

static Utilities* sharedInstance = nil;

+ (Utilities*)sharedInstance
{
    @synchronized([Utilities class])
    {
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
        return sharedInstance;
    }
    
    return nil;
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString*)msg {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
    [alert show];
}

- (void)setBOOL:(BOOL)value forKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

- (BOOL)getBOOLForKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

- (void)setString:(NSString*)value forKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

- (NSString*)getStringForKey:(NSString*)key {
    NSString *value =[[NSUserDefaults standardUserDefaults] stringForKey:key];
    return value;
}


- (NSString *)getElapsedTime:(NSDate *)pastDate {
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:pastDate
                                                  toDate:currentDate options:0];
    
    NSString *timeLeft = @"";
    NSInteger result = [components year];
    if (result > 0) {
        if (result > 1) {
            timeLeft = [NSString stringWithFormat:@"%ldy", (long)result];
        }
        else {
            timeLeft = [NSString stringWithFormat:@"%ldy", (long)result];
        }
        return timeLeft;
    }
    
    result = [components month];
    if (result > 0) {
        if (result > 1) {
            timeLeft = [NSString stringWithFormat:@"%ldm", (long)result];
        }
        else {
            timeLeft = [NSString stringWithFormat:@"%ldm", (long)result];
        }
        return timeLeft;
    }
    
    result = [components day];
    if (result > 0) {
        if (result > 1) {
            timeLeft = [NSString stringWithFormat:@"%ldd", (long)result];
        }
        else {
            timeLeft = [NSString stringWithFormat:@"%ldd", (long)result];
        }
        return timeLeft;
    }
    
    result = [components hour];
    if (result > 0) {
        if (result > 1) {
            timeLeft = [NSString stringWithFormat:@"%ldh", (long)result];
        }
        else {
            timeLeft = [NSString stringWithFormat:@"%ldh", (long)result];
        }
        return timeLeft;
    }
    
    result = [components minute];
    if (result > 0) {
        if (result > 1) {
            timeLeft = [NSString stringWithFormat:@"%ldmin", (long)result];
        }
        else {
            timeLeft = [NSString stringWithFormat:@"%ldmin", (long)result];
        }
        return timeLeft;
    }
    
    result = [components second];
    if (result > 0) {
        timeLeft = [timeLeft stringByAppendingFormat:@"%lisec", (long)result];
    }
    
    currentDate = nil;
    gregorian = nil;
    components = nil;
    
    return timeLeft;
}

- (UITableView*)tableViewFromCell:(UITableViewCell*)cell
{
    id view = [cell superview];
    
    while (view && [view isMemberOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    
    UITableView *tableView = (UITableView *)view;
    return tableView;
}


@end
