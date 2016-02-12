//
//  ImageData.h
//  Gum Wall
//
//  Created by Murtaza on 12/02/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#define kPhotoId @"photoId"
#define kPhotoCaption @"photoCaption"
#define kVoteCount @"voteCount"
#define kVoteCountComment @"voteCount"
#define kCommentText @"commentText"

@interface ImageData : NSObject

@property (nonatomic, assign) BOOL isLocalFeed;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSString* imageId;
@property (nonatomic, strong) NSString* imageDescription;
@property (nonatomic, strong) NSNumber* voteCount;
@property (nonatomic, strong) PFObject* imagePFObject;
@end
