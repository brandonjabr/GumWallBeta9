//
//  InitialViewController.m
//  Gum Wall
//
//  Created by Murtaza on 06/02/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import "InitialViewController.h"
#import "CommentsViewController.h"

@interface InitialViewController ()

@end

@implementation InitialViewController
- (IBAction)btnPressed:(id)sender {

    CommentsViewController* vc = [[CommentsViewController alloc] initWithImageData:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
