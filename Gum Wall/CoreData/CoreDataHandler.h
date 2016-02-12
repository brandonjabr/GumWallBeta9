//
//  CoreDataHandler.h
//  Gum Wall
//
//  Created by Apple on 30/12/2014.
//  Copyright (c) 2014 AMP, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataHandler : NSObject

+(void)addVoteDataWithImageID:(NSString *)imgID andVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown;
+(void)updateVoteDataForImageID:(NSString *)imgID withVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown;
+(NSArray *)getVoteDataItems;
+ (BOOL)isUpVotedImageID:(NSString *)imgID;
+ (BOOL)isDownVotedImageID:(NSString *)imgID;
+(void)deleteVoteDataForImageID:(NSString *)imgID;
+(void)deleteAllVoteData;

//CommentVoteData methods
+(void)addCommentVoteDataWithCommentID:(NSString *)cmntID andVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown;
+(void)updateCommentVoteDataForCommentID:(NSString *)cmntID withVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown;
+ (BOOL)isUpVotedCommentID:(NSString *)cmntID;
+ (BOOL)isDownVotedCommentID:(NSString *)cmntID;

@end