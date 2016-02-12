//
//  CommentTableViewCell.h
//  Gum Wall
//
//  Created by Murtaza on 02/02/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CommentTableViewCellDelegate <NSObject>

- (void)btnUpPressedAtIndexPath:(NSIndexPath*)index;
- (void)btnDownPressedAtIndexPath:(NSIndexPath*)index;

@end
@interface CommentTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *btnDown;
@property (weak, nonatomic) IBOutlet UIButton *btnUp;

@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;
@property (weak, nonatomic) IBOutlet UILabel *lblVoteCount;

@property (nonatomic, weak) UITableView* parentTableView;
@property (nonatomic, weak) id<CommentTableViewCellDelegate> delegate;
@end
