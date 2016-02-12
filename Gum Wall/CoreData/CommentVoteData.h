//
//  CommentVoteData.h
//  Gum Wall
//
//  Created by Murtaza on 13/02/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CommentVoteData : NSManagedObject

@property (nonatomic, retain) NSString * commentId;
@property (nonatomic, retain) NSNumber * isDownVoted;
@property (nonatomic, retain) NSNumber * isUpVoted;

@end
