//
//  ScoreViewController.m
//  Gum Wall
//
//  Created by Muhammad Junaid Butt on 02/01/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import "ScoreViewController.h"
#import "Utilities.h"

@interface ScoreViewController ()

@end

@implementation ScoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lblScore.text = [[Utilities sharedInstance] getStringForKey:@"score"];
    self.btnClose.backgroundColor = [UIColor clearColor];
    [self.lblScore startPulseWithColor:[UIColor whiteColor]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnCloseAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }];
}

@end
