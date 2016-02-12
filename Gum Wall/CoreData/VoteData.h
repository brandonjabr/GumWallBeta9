//
//  VoteData.h
//  Gum Wall
//
//  Created by Apple on 30/12/2014.
//  Copyright (c) 2014 AMP, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface VoteData : NSManagedObject

@property (nonatomic, retain) NSString * imageID;
@property (nonatomic, retain) NSNumber * isUpVoted;
@property (nonatomic, retain) NSNumber * isDownVoted;

@end
