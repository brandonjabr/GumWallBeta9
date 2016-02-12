//
//  CommentTableViewCell.m
//  Gum Wall
//
//  Created by Murtaza on 02/02/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import "CommentTableViewCell.h"
#import "Utilities.h"

@interface CommentTableViewCell ()


@end
@implementation CommentTableViewCell
- (IBAction)btnVoteUpPressed:(id)sender {
    [self.delegate btnUpPressedAtIndexPath:[self.parentTableView indexPathForCell:self]];
}

- (IBAction)btnVoteDnPressed:(id)sender {
    [self.delegate btnDownPressedAtIndexPath:[self.parentTableView indexPathForCell:self]];
}

- (void)awakeFromNib {
    // Initialization code
    
    self.lblTime.textColor = [UIColor colorWithRed:42.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0];
    self.lblVoteCount.textColor = [UIColor colorWithRed:42.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
