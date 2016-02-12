//
//  EULAViewViewController.m
//  Gum Wall
//
//  Created by Brandon Jabr on 1/26/15.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import "EULAViewViewController.h"

@interface EULAViewViewController ()

@end

@implementation EULAViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnAcceptAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }];
    
    
}

-(IBAction)clickedEULA:(id)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mento.la/eula.html"]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
