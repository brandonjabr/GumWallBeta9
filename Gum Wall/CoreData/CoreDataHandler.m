//
//  CoreDataHandler.m
//  Gum Wall
//
//  Created by Apple on 30/12/2014.
//  Copyright (c) 2014 AMP, Inc. All rights reserved.
//


#import "CoreDataHandler.h"
#import "AppDelegate.h"
#import "VoteData.h"
#import "CommentVoteData.h"

@implementation CoreDataHandler


+(void)addVoteDataWithImageID:(NSString *)imgID andVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown {
    //create the object of AppDelegate
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get the context from AppDelegate
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    VoteData *voteDataItem = [NSEntityDescription insertNewObjectForEntityForName:@"VoteData"
                                                       inManagedObjectContext:context];
    voteDataItem.imageID = imgID;
    voteDataItem.isUpVoted = [NSNumber numberWithBool:isVoteUp];
    voteDataItem.isDownVoted = [NSNumber numberWithBool:isVoteDown];
    
    //save the entity in core data
    NSError * error = nil;
    [context save:&error];
    if (error) {
        NSLog(@"VoteData item did not save in CoreData. Error : %@",[error localizedDescription]);
    }
}

+(void)updateVoteDataForImageID:(NSString *)imgID withVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown {
    
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"VoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"imageID=%@",imgID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    VoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
    }
    else {
        voteDataItem = [NSEntityDescription insertNewObjectForEntityForName:@"VoteData"
                                                inManagedObjectContext:context];
        voteDataItem.imageID = imgID;
    }
    voteDataItem.isUpVoted = [NSNumber numberWithBool:isVoteUp];
    voteDataItem.isDownVoted = [NSNumber numberWithBool:isVoteDown];
    
    //save the entity in core data
    error = nil;
    [context save:&error];
    if (error) {
        NSLog(@"VoteData did not update in CoreData. Error : %@",[error localizedDescription]);
    }
}

+(NSArray *)getVoteDataItems {
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"VoteData" inManagedObjectContext:context]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error in fetching VoteData items: %@",[error localizedDescription]);
        return nil;
    }
    return result;
}

+ (BOOL)isUpVotedImageID:(NSString *)imgID {
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"VoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"imageID=%@",imgID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    VoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
        return voteDataItem.isUpVoted.boolValue;
    }
    
    return NO;
}

+ (BOOL)isDownVotedImageID:(NSString *)imgID {
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"VoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"imageID=%@",imgID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    VoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
        return voteDataItem.isDownVoted.boolValue;
    }
    return NO;
}

#pragma mark CommentVoteData methods
+(void)addCommentVoteDataWithCommentID:(NSString *)cmntID andVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown {
    //create the object of AppDelegate
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get the context from AppDelegate
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    CommentVoteData *voteDataItem = [NSEntityDescription insertNewObjectForEntityForName:@"CommentVoteData"
                                                           inManagedObjectContext:context];
    voteDataItem.commentId = cmntID;
    voteDataItem.isUpVoted = [NSNumber numberWithBool:isVoteUp];
    voteDataItem.isDownVoted = [NSNumber numberWithBool:isVoteDown];
    
    //save the entity in core data
    NSError * error = nil;
    [context save:&error];
    if (error) {
        NSLog(@"VoteData item did not save in CoreData. Error : %@",[error localizedDescription]);
    }
}

+(void)updateCommentVoteDataForCommentID:(NSString *)cmntID withVoteUp:(BOOL)isVoteUp andVoteDown:(BOOL)isVoteDown {
    
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"CommentVoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"commentId=%@",cmntID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    CommentVoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
    }
    else {
        voteDataItem = [NSEntityDescription insertNewObjectForEntityForName:@"CommentVoteData"
                                                     inManagedObjectContext:context];
        voteDataItem.commentId = cmntID;
    }
    voteDataItem.isUpVoted = [NSNumber numberWithBool:isVoteUp];
    voteDataItem.isDownVoted = [NSNumber numberWithBool:isVoteDown];
    
    //save the entity in core data
    error = nil;
    [context save:&error];
    if (error) {
        NSLog(@"VoteData did not update in CoreData. Error : %@",[error localizedDescription]);
    }
}

+ (BOOL)isUpVotedCommentID:(NSString *)cmntID {
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"CommentVoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"commentId=%@",cmntID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    CommentVoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
        return voteDataItem.isUpVoted.boolValue;
    }
    
    return NO;
}


+ (BOOL)isDownVotedCommentID:(NSString *)cmntID {
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [appDelegate managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"CommentVoteData" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"commentId=%@",cmntID]];
    
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error in fetching VoteData : %@",[error description]);
    }
    
    CommentVoteData *voteDataItem = nil;
    if (result.count == 1) {
        voteDataItem = [result firstObject];
        return voteDataItem.isDownVoted.boolValue;
    }
    return NO;
}

+(void)deleteVoteDataForImageID:(NSString *)imgID {
    
}

+(void)deleteAllVoteData {
    
}

@end