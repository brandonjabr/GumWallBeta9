//
//  ViewController.m
//  Gum Wall
//
//  Created by Muhammad Junaid Butt on 01/01/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import "Utilities.h"
#import <KVNProgress/KVNProgress.h>
#import "CoreDataHandler.h"
#import "VoteData.h"
#import <Social/Social.h>
#import "CategorySliderView.h"
#import "UIScrollView+InfiniteScroll.h"
#import "ScoreViewController.h"
#import "EULAViewViewController.h"
#import "MRProgress.h"
#import "UIImage+BlurredFrame.h"
#import "UIImage+Resize.h"
#import "CommentsViewController.h"
#import "ImageData.h"
#import "FeLoadingIcon.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface ViewController () {
    NSMutableArray *feeds;
    NSArray *votes;
    NSInteger selectedIndex;
    UIRefreshControl *refreshControl;
    int feedsSkipCount;
    int feedsLimit;
    BOOL isRefreshingFeeds;
    int scrollY;
    BOOL isHighVotesFeed;
    BOOL isLocalFeed;
    BOOL isLocalFeedFetchInProgressed;
    BOOL isCameraButtonPressed;
    CategorySliderView *sliderView;
    FeLoadingIcon* mainLoadingIcon;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];

    
    if([[[Utilities sharedInstance] getStringForKey:@"score"] intValue] == 0){
    NSString *storyboardName = @"Main_iPhone";
    if (IPAD) {
        storyboardName = @"Main_iPad";
    }
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
//    EULAViewViewController *scoreVC = [storyboard instantiateViewControllerWithIdentifier:@"eulaView"];
//    [self presentViewController:scoreVC animated:YES completion:^{
//        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
//    }];
//    storyboardName = nil;
//    scoreVC = nil;
    
    
    }
    
    
    
    

    
    [TGCamera setOption:kTGCameraOptionSaveImageToAlbum value:[NSNumber numberWithBool:YES]];
    
    // Setting up the Navigation bar.
    [self setNavBar];
    
    //set the background color & cell separator style of UITableView
    self.view.backgroundColor = [UIColor colorWithRed:35.0f/255.0f green:35.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
    self.scrollView.backgroundColor = [UIColor colorWithRed:35.0f/255.0f green:35.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
    
    //initialize the arrays
    feeds = [NSMutableArray array];
    votes = [NSMutableArray array];
    
    //setting up the score
    if ([[Utilities sharedInstance] getStringForKey:@"score"] != nil) {
        self.scoreLabel.title = [[Utilities sharedInstance] getStringForKey:@"score"];
    }
    
    //add upper slider view
    CGFloat sliderHeight = 35;
    if (IPAD) {
        sliderHeight = 60;
    }
    
    sliderView = [[CategorySliderView alloc] initWithSliderHeight:sliderHeight
                                                andCategoryViews:@[[self labelWithText:@"Local"],[self labelWithText:@"Global"]]
                                        categorySelectionBlock:^(UIView *categoryView, NSInteger categoryIndex) {
                                            if (categoryIndex == 0) {
                                                isLocalFeed = YES;
                                                [self showLocalFeeds];
                                            }
                                            else if (categoryIndex == 1) {
                                                isLocalFeed = NO;
                                                [self refreshGumWall];
                                            }
                                        }];
    sliderView.backgroundImage = [UIImage imageNamed:@"PulseBar.png"];
    [self.view addSubview:sliderView];
    
    UILabel *dotLabel = [[UILabel alloc]initWithFrame:CGRectMake(142, 5, 40, 40)];
    dotLabel.text = @".";
    dotLabel.textAlignment = NSTextAlignmentCenter;
    dotLabel.textColor = [UIColor colorWithRed:42.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0];
    dotLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16.0f];
    [self.view addSubview:dotLabel];

    //full to refresh
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(refreshGumWall) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:refreshControl];
    
    //add infinite scroll view
    self.scrollView.infiniteScrollIndicatorStyle = UIActivityIndicatorViewStyleWhite;
    [self.scrollView addInfiniteScrollWithHandler:^(UIScrollView *scrollView) {
        isRefreshingFeeds = NO;
        feedsSkipCount = (int)feeds.count;
        [self getFeedsWithSkipLimit:feedsSkipCount andFeedsLimit:feedsLimit];
    }];
    
    //by default mark selection on Local
    isLocalFeed = YES;
    isHighVotesFeed = NO;
    [sliderView markSelectionOnCategoryNumber:0];
    
    //add gestures
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeAction)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.scrollView addGestureRecognizer:rightSwipe];
    rightSwipe = nil;
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeAction)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.scrollView addGestureRecognizer:leftSwipe];
    leftSwipe = nil;
}

- (void)rightSwipeAction {
    [sliderView resetSelectionsOnViews];
    [sliderView markSelectionOnCategoryNumber:0];
}

- (void)leftSwipeAction {
    [sliderView resetSelectionsOnViews];
    [sliderView markSelectionOnCategoryNumber:1];
}

- (UILabel *)labelWithText:(NSString *)text {
    CGFloat fontSize = 18.0f;
    float w = 0.0f;
    UILabel *lbl = nil;
    
    if (IPAD) {
        fontSize = 30.0f;
        w = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Avenir-Medium" size:fontSize]}].width;
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 60)];
    }
    else {
        w = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Avenir-Medium" size:fontSize]}].width;
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 35)];
    }
    
    [lbl setFont:[UIFont fontWithName:@"Avenir-Medium" size:fontSize]];
    [lbl setText:text];
    [lbl setTextColor:[UIColor whiteColor]];
    [lbl setTextAlignment:NSTextAlignmentCenter];
    
    return lbl;
}

- (void)setNavBar {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:35.0f/255.0f green:35.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;
    
    //Adding Navigation bar menu
    UISegmentedControl *navbar = [[UISegmentedControl alloc] initWithItems:@[@"New", @"Hot"]];
    [navbar setSelectedSegmentIndex:0];
    [navbar setFrame:CGRectMake(0, 0, 120, 32)];
    UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:15.0f];
    if (IPAD) {
        [navbar setFrame:CGRectMake(0, 0, 300, 32)];
        font = [UIFont fontWithName:@"Avenir-Medium" size:20.0f];
    }
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    [navbar setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [navbar addTarget:self action:@selector(segmentedControlIndexChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = navbar;
    
    if (IPAD) {
        [self.scoreLabel setTitleTextAttributes:@{
                                                  NSFontAttributeName: [UIFont fontWithName:@"Avenir-Medium" size:30.0f],
                                                  NSForegroundColorAttributeName: [UIColor whiteColor]
                                                  } forState:UIControlStateNormal];
    }
    else {
        [self.scoreLabel setTitleTextAttributes:@{
                                                  NSFontAttributeName: [UIFont fontWithName:@"Avenir-Medium" size:20.0f],
                                                  NSForegroundColorAttributeName: [UIColor whiteColor]
                                                  } forState:UIControlStateNormal];
    }
}

//method that will called when navigation bar menu tapped
- (void)segmentedControlIndexChanged:(UISegmentedControl *)sender {
    NSInteger selectedSegmentIndex = sender.selectedSegmentIndex;
    if (selectedSegmentIndex == 0) {
        isHighVotesFeed = NO;
    }
    else if (selectedSegmentIndex == 1) {
        isHighVotesFeed = YES;
    }
    
    isLocalFeed = YES;
    isLocalFeedFetchInProgressed = NO;
    
    [sliderView resetSelectionsOnViews];
    [sliderView markSelectionOnCategoryNumber:0];
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - Method to fetch Local feeds
- (void)showLocalFeeds {
    [self clearScrollView];
    
    //check for location
    if ([CLLocationManager locationServicesEnabled] == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Enable Location Service"
                                               message:@"You have to enable the Location Service to use this feature.\nTo enable, please go to\nSettings->Privacy->Location Services"];
    }
    else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            [[Utilities sharedInstance] showAlertWithTitle:@"Request for Location Service"
                                                   message:@"Please allow the app to access the Location Service."];
        }
        else {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            self.locationManager.delegate = self;
            if(IS_OS_8_OR_LATER) {
                [self.locationManager requestWhenInUseAuthorization];
            }
            else {
                [self.locationManager startUpdatingLocation];
            }
        }
    }
}

#pragma mark - Method to refresh feeds
- (void)refreshGumWall {
    feedsSkipCount = 0;
    feedsLimit = 100;
    isRefreshingFeeds = YES;
    [self getFeedsWithSkipLimit:feedsSkipCount andFeedsLimit:feedsLimit];
}

- (void)getFeedsWithSkipLimit:(int)skipCount andFeedsLimit:(int)feedLimit {
    //initializing the loading view
//    [MRProgressOverlayView showOverlayAddedTo:self.navigationController.view animated:YES];
    mainLoadingIcon = [[FeLoadingIcon alloc] initWithView:self.view blur:NO backgroundColors:nil];
    [self.view addSubview:mainLoadingIcon];
    [mainLoadingIcon show];
    
    PFQuery *query = [PFQuery queryWithClassName:@"FeedData"];
    [query whereKey:@"voteCount" greaterThan:@-5];
    
    if (isHighVotesFeed) {
        if (isLocalFeed) {
            PFGeoPoint *userGeoPoint = [PFGeoPoint geoPointWithLatitude:self.myLocation.latitude
                                                              longitude:self.myLocation.longitude];
            [query whereKey:@"location" nearGeoPoint:userGeoPoint withinMiles:10.0];
        }
        [query orderByDescending:@"voteCount"];
    }
    else if (isLocalFeed) {
        NSLog(@"ON LOCAL FEED");
        PFGeoPoint *userGeoPoint = [PFGeoPoint geoPointWithLatitude:self.myLocation.latitude
                                                          longitude:self.myLocation.longitude];
        [query whereKey:@"location" nearGeoPoint:userGeoPoint withinMiles:10.0];
    }
    else {
        [query orderByDescending:@"createdAt"];
    }

    [query setSkip:skipCount];
    [query setLimit:feedLimit];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [refreshControl endRefreshing];
//        [MRProgressOverlayView dismissOverlayForView:self.navigationController.view animated:YES];
        [mainLoadingIcon dismiss];
        [mainLoadingIcon removeFromSuperview];
        mainLoadingIcon = nil;
        
        [self.scrollView finishInfiniteScroll];
        isLocalFeedFetchInProgressed = NO;
        
        if (!error) {
            
            if (objects.count > 0) {
                
                if (isRefreshingFeeds) {
                    [feeds removeAllObjects];
                    [self clearScrollView];
                }
                
                if (isHighVotesFeed) {
                    //sort array on Vote count
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"voteCount" ascending:NO];
                    NSArray *sortedFeedArray = [[objects sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
                    [feeds addObjectsFromArray:sortedFeedArray];
                    sortedFeedArray = nil;
                    sortDescriptor = nil;
                }
                else {
                    //sort array on createdAt
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
                    NSArray *sortedFeedArray = [[objects sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
                    [feeds addObjectsFromArray:sortedFeedArray];
                    sortedFeedArray = nil;
                    sortDescriptor = nil;
                }
                
                int delta = 65;
                if (IPAD) {
                    delta = 160;
                }
                self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, feeds.count * (self.view.frame.size.width + delta));
                [self loadWallFeeds];
                
                if (isRefreshingFeeds || isLocalFeed || isHighVotesFeed) {
                    [self.scrollView setContentOffset:CGPointZero animated:YES];
                }
            }
            else {
                if (isLocalFeed && isRefreshingFeeds) {
                    NSString *text = @"No posts on your local Gum Wall. Be the first one to make a mark! 😏";
                    
                    CGFloat fontSize = 18;
                    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, self.scrollView.frame.size.height/3.5, self.view.frame.size.width-20, 100)];
                    if (IPAD) {
                        fontSize = 30.0f;
                        lbl = [[UILabel alloc] initWithFrame:CGRectMake(40, self.scrollView.frame.size.height/3.5, self.view.frame.size.width-80, 100)];
                    }
                    
                    [lbl setFont:[UIFont fontWithName:@"Avenir-Medium" size:fontSize]];
                    [lbl setText:text];
                    [lbl setTextColor:[UIColor whiteColor]];
                    [lbl setTextAlignment:NSTextAlignmentCenter];
                    [lbl setNumberOfLines:3];
                    
                    [self.scrollView addSubview:lbl];
                    lbl = nil;
                    text = nil;
                }
            }
            
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to load Gum Wall feeds. Please check your internet connection and try again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
            alertView.tag = 404;
            [alertView show];
            alertView = nil;
        }
    }];
}

#pragma mark - Method that clear the Scroll View
- (void)clearScrollView {
    NSArray *subViews = [self.scrollView subviews];
    for (UIView *subView in subViews) {
        if ([subView isKindOfClass:[UIRefreshControl class]]) {
            continue;
        }
        [subView removeFromSuperview];
    }
    scrollY = 0;
}

#pragma mark - Method that shows feed in Scroll View
- (void)loadWallFeeds {
    const NSInteger kTagLoadingCircle = 69;
    int height = 320;
    if (IPAD) {
        height = 768;
    }
    
    int startIndex = feedsSkipCount;
    if (startIndex > 0) {
        startIndex = startIndex - 1;
    }

    int count = feedsSkipCount + feedsLimit;
    if (count > feeds.count) {
        count = (int)feeds.count;
        feedsSkipCount = (int)feeds.count;
    }
    
    for (int i=startIndex; i<count; i++) {
        PFObject *feedObject = [feeds objectAtIndex:i];
        
        //create view
        int deltaHeight = 65;
        if (IPAD) {
            deltaHeight = 160;
        }
        
        UIView *feedCellView = [[UIView alloc] initWithFrame:CGRectMake(0, scrollY, self.view.frame.size.width, height + deltaHeight)];
        feedCellView.tag = i;
        
        //add image feed
        UIImageView *blurImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, feedCellView.frame.size.width, feedCellView.frame.size.height)];
        UIImageView *feedImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, feedCellView.frame.size.width, feedCellView.frame.size.height - deltaHeight)];
        feedImgView.tag = 101;
        
        PFFile *file = feedObject[@"imageFile"];
        [file getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:imageData];
                feedImgView.image = image;
                
                image = [image resizedImageToFitInSize:feedCellView.frame.size scaleIfSmaller:YES];
                CGRect frame = CGRectMake(0, image.size.height - deltaHeight, image.size.width, image.size.height - deltaHeight);
                blurImgView.image = [[image resizedImageToFitInSize:feedCellView.frame.size scaleIfSmaller:YES] applyDarkEffectAtFrame:frame];
                // Dismiss loading icon
//                FeLoadingIcon* icon = (FeLoadingIcon*)[feedCellView viewWithTag:kTagLoadingCircle];
//                [icon dismiss];
//                [icon removeFromSuperview];
//                icon = nil;
            }
        }];
       // [feedCellView addSubview:blurImgView];
        [feedCellView addSubview:feedImgView];
        
        // Add comment button
        UIButton* btnComment = [UIButton buttonWithType:UIButtonTypeCustom];
        btnComment.frame = feedImgView.frame;
        [btnComment setBackgroundColor:[UIColor clearColor]];
        
        [btnComment addTarget:self action:@selector(btnCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
        btnComment.tag = i;
        [feedCellView addSubview:btnComment];
        
        //add photo caption
        CGRect captionLbl = CGRectMake(8, 257 + deltaHeight, 270, 60);
        CGFloat captionFontSize = 18.0f;
        if (IPAD) {
            captionLbl = CGRectMake(16, 630 + deltaHeight, 688, 120);
            captionFontSize = 36.0f;
        }
        
        UILabel *photoCaption = [[UILabel alloc] initWithFrame:captionLbl];
        photoCaption.text = feedObject[@"photoCaption"];
        if([photoCaption.text isEqualToString:@"Add a caption..."]){
            photoCaption.text = @"";
        }
        photoCaption.textColor = [UIColor whiteColor];
        photoCaption.font = [UIFont fontWithName:@"Avenir-Medium" size:captionFontSize];
        photoCaption.numberOfLines = 2;
        photoCaption.tag = 100;
        [feedCellView addSubview:photoCaption];
        
        //add up vote button
        CGRect upVoteBtnRect = CGRectMake(284, 252 + deltaHeight, 30, 30);
        if (IPAD) {
            upVoteBtnRect = CGRectMake(688, 620 + deltaHeight, 60, 60);
        }
        
        UIButton *upVoteBtn = [[UIButton alloc] initWithFrame:upVoteBtnRect];
        [upVoteBtn setImage:[UIImage imageNamed:@"icon_up"] forState:UIControlStateNormal];
        [upVoteBtn setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateHighlighted];
        if ([CoreDataHandler isUpVotedImageID:feedObject.objectId]) {
            [upVoteBtn setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateNormal];
        }
        upVoteBtn.tag = i;
        [upVoteBtn addTarget:self action:@selector(onUpVotePress:) forControlEvents:UIControlEventTouchUpInside];
        [feedCellView addSubview:upVoteBtn];
        
        //add vote count label
        CGRect voteCountLblRect = CGRectMake(274, 276 + deltaHeight, 50, 21);
        int fontSize = 18.0;
        if (IPAD) {
            voteCountLblRect = CGRectMake(668, 670 + deltaHeight, 100, 40);
            fontSize = 34.0;
        }
        
        UILabel *voteCountLbl = [[UILabel alloc] initWithFrame:voteCountLblRect];
        voteCountLbl.font = [UIFont fontWithName:@"Avenir-Medium" size:fontSize];
        voteCountLbl.textColor = [UIColor colorWithRed:42.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0];
        voteCountLbl.textAlignment = NSTextAlignmentCenter;
        voteCountLbl.tag = 102;
        voteCountLbl.text =  [NSString stringWithFormat:@"%@",feedObject[@"voteCount"]];
        [feedCellView addSubview:voteCountLbl];
        
        //add down vote button
        CGRect downVoteBtnRect = CGRectMake(284, 290 + deltaHeight, 30, 30);
        if (IPAD) {
            downVoteBtnRect = CGRectMake(688, 700 + deltaHeight, 60, 60);
        }
        
        UIButton *downVoteBtn = [[UIButton alloc] initWithFrame:downVoteBtnRect];
        [downVoteBtn setImage:[UIImage imageNamed:@"icon_down.png"] forState:UIControlStateNormal];
        [downVoteBtn setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateHighlighted];
        if ([CoreDataHandler isDownVotedImageID:feedObject.objectId]) {
            [downVoteBtn setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateNormal];
        }
        downVoteBtn.tag = i;
        [downVoteBtn addTarget:self action:@selector(onDownVotePress:) forControlEvents:UIControlEventTouchUpInside];
        [feedCellView addSubview:downVoteBtn];
        
        //add share button
        CGRect shareBtnRect = CGRectMake(8, 8, 14, 28);
        if (IPAD) {
            shareBtnRect = CGRectMake(16, 16, 24, 48);
        }
        
        UIButton *shareBtn = [[UIButton alloc] initWithFrame:shareBtnRect];
        [shareBtn setImage:[UIImage imageNamed:@"icon_share.png"] forState:UIControlStateNormal];
        shareBtn.tag = i;
        [shareBtn addTarget:self action:@selector(onShareBtnPress:) forControlEvents:UIControlEventTouchUpInside];
        [feedCellView addSubview:shareBtn];
        
        //add timer image
        CGRect timerImgRect = CGRectMake(8, 297 - 70 + deltaHeight, 15, 15);
        if (IPAD) {
            timerImgRect = CGRectMake(16, 700 - 140 + deltaHeight, 35, 35);
        }
        
        UIImageView *timerImgView = [[UIImageView alloc] initWithFrame:timerImgRect];
        timerImgView.image = [UIImage imageNamed:@"icon_timer"];
        [feedCellView addSubview:timerImgView];
        
        //add timer label
        CGRect timerLblRect = CGRectMake(30, 295 - 70 + deltaHeight, 50, 21);
        if (IPAD) {
            timerLblRect = CGRectMake(59, 707 - 140 + deltaHeight, 80, 21);
        }
        
        UILabel *timerlbl = [[UILabel alloc] initWithFrame:timerLblRect];
        if (IPAD) {
            timerlbl.font = [UIFont fontWithName:@"Avenir-Black" size:22];
        }
        else {
            timerlbl.font = [UIFont fontWithName:@"Avenir-Black" size:13];            
        }
        
        timerlbl.textColor = [UIColor whiteColor];
        timerlbl.tag = 103;
        timerlbl.text =  [[Utilities sharedInstance] getElapsedTime:feedObject.createdAt];
        [feedCellView addSubview:timerlbl];
        
        UIView *borderView = [[UIView alloc]initWithFrame:CGRectMake(0, 384, 500, 0.3)];
        [borderView setBackgroundColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0]];
        [feedCellView addSubview:borderView];
        
//        //add whole view in scroll view
//        FeLoadingIcon* loadingIcon = [[FeLoadingIcon alloc] initWithView:feedCellView blur:NO backgroundColors:nil];
//        loadingIcon.tag = kTagLoadingCircle;
//        [feedCellView addSubview:loadingIcon];
//        [loadingIcon show];
        
        [self.scrollView addSubview:feedCellView];
        scrollY = scrollY + height + deltaHeight;
        
        feedImgView = nil;
        blurImgView = nil;
        upVoteBtn = nil;
        voteCountLbl = nil;
        downVoteBtn = nil;
        shareBtn = nil;
        timerlbl = nil;
        timerImgView = nil;
        photoCaption = nil;
        feedCellView = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Method to show Score
- (IBAction)onScoreBtnPress:(id)sender {
    NSString *storyboardName = @"Main_iPhone";
    if (IPAD) {
        storyboardName = @"Main_iPad";
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    ScoreViewController *scoreVC = [storyboard instantiateViewControllerWithIdentifier:@"ScoreVC"];
    [self presentViewController:scoreVC animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }];
    storyboardName = nil;
    scoreVC = nil;
}

#pragma mark - Method to launch camera
- (IBAction)onCameraBtnPress:(id)sender {
    //check for location
    if ([CLLocationManager locationServicesEnabled] == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Enable Location Service"
                                               message:@"You have to enable the Location Service to use this feature.\nTo enable, please go to\nSettings->Privacy->Location Services"];
    }
    else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            [[Utilities sharedInstance] showAlertWithTitle:@"Request for Location Service"
                                                   message:@"Please allow the app to access the Location Service."];
        }
        else {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            self.locationManager.delegate = self;
            if(IS_OS_8_OR_LATER) {
                [self.locationManager requestWhenInUseAuthorization];
            }
            else {
                [self.locationManager startUpdatingLocation];
            }
            
            isCameraButtonPressed = YES;
        }
    }
}

#pragma mark - Delegate methods of CLLocationManager
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
     [self.locationManager requestWhenInUseAuthorization];
    
    NSLog(@"locationManager: didChangeAuthorizationStatus");
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
    
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Request for Location Service"
                                               message:@"Please allow the app to access the Location Service."];
        isCameraButtonPressed = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"locationManager: didUpdateLocations");
    CLLocation * newLocation = [locations lastObject];
    self.myLocation = newLocation.coordinate;
    [self.locationManager stopUpdatingLocation];
    
    if (isCameraButtonPressed) {
        //show the Camera after capturing the user's location
        TGCameraNavigationController *cameraController = [TGCameraNavigationController newWithCameraDelegate:self];
        [self presentViewController:cameraController animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }];
        cameraController = nil;
        isCameraButtonPressed = NO;
    }
    else if (isLocalFeed) {
        if (!isLocalFeedFetchInProgressed) {
            isLocalFeedFetchInProgressed = YES;
            [self refreshGumWall];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager: didFailWithError");
    switch([error code]) {
        case kCLErrorNetwork: {
            [[Utilities sharedInstance] showAlertWithTitle:@"Network Error"
                                                   message:@"Please check your network connection."];
        }
            break;
        case kCLErrorDenied: {
            [[Utilities sharedInstance] showAlertWithTitle:@"Enable Location Service"
                                                   message:@"You have to enable the Location Service to use this feature.\nTo enable, please go to\nSettings->Privacy->Location Services"];
        }
            break;
    }
    
    isCameraButtonPressed = NO;
}

#pragma mark - Methods for Vote-up & Vote-down
- (void)onUpVotePress:(UIButton*)sender {
    
    if(isLocalFeed == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote on your local feed!"];
    }
    else {
    
        PFObject *currentFeed = [feeds objectAtIndex:sender.tag];
        if ([CoreDataHandler isUpVotedImageID:currentFeed.objectId] || [CoreDataHandler isDownVotedImageID:currentFeed.objectId]) {
            [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
        }
        else {
            [sender setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateNormal];
            
            UIView *cell = [self.scrollView viewWithTag:sender.tag];
            UILabel *voteCounterLbl = (UILabel *)[cell viewWithTag:102];
            int voteCount =  [voteCounterLbl.text intValue] + 1;
            
            currentFeed[@"voteCount"] = [NSNumber numberWithInt:voteCount];
            [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
                    [feeds replaceObjectAtIndex:sender.tag withObject:currentFeed];
                    [CoreDataHandler updateVoteDataForImageID:currentFeed.objectId withVoteUp:YES andVoteDown:NO];
                    
                    int score = [[[Utilities sharedInstance] getStringForKey:@"score"] intValue] + 1;
                    self.scoreLabel.title = [NSString stringWithFormat:@"%i",score];
                    [[Utilities sharedInstance] setString:self.scoreLabel.title forKey:@"score"];
                    
                    voteCounterLbl.text = [NSString stringWithFormat:@"%i",voteCount];
                }
                else {
                    [sender setImage:[UIImage imageNamed:@"icon_up"] forState:UIControlStateNormal];
                    [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to UpVote. Please check your internet connection and try again."];
                }
            }];
        }
    }
}

- (void)onDownVotePress:(UIButton*)sender {
    
    if(isLocalFeed == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote on your local feed!"];
    }
    else {
        
        PFObject *currentFeed = [feeds objectAtIndex:sender.tag];
        if ([CoreDataHandler isUpVotedImageID:currentFeed.objectId] || [CoreDataHandler isDownVotedImageID:currentFeed.objectId]) {
            [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
        }
        else {
            [sender setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateNormal];
            
            UIView *cell = [self.scrollView viewWithTag:sender.tag];
            UILabel *voteCounterLbl = (UILabel *)[cell viewWithTag:102];
            int voteCount =  [voteCounterLbl.text intValue] - 1;
            
            currentFeed[@"voteCount"] = [NSNumber numberWithInt:voteCount];
            [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
                    [feeds replaceObjectAtIndex:sender.tag withObject:currentFeed];
                    [CoreDataHandler updateVoteDataForImageID:currentFeed.objectId withVoteUp:NO andVoteDown:YES];
                    
                    voteCounterLbl.text = [NSString stringWithFormat:@"%i",voteCount];
                }
                else {
                    [sender setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateNormal];
                    [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to DownVote. Please check your internet connection and try again."];
                }
            }];
        }
    }
}

- (void)btnCommentPressed:(UIButton*)btn
{
    UIView *selectedCell = [self.scrollView viewWithTag:btn.tag];
    UIImageView *imageView = (UIImageView *)[selectedCell viewWithTag:101];
    PFObject *photoObj = [feeds objectAtIndex:btn.tag];
    if (photoObj) {
        ImageData* data = [ImageData new];
        data.isLocalFeed = isLocalFeed;
        data.image = imageView.image;
        data.imageId = photoObj.objectId;
        data.imageDescription = photoObj[kPhotoCaption];
        data.voteCount = photoObj[kVoteCountComment];
        data.imagePFObject = photoObj;
        CommentsViewController* vc = [[CommentsViewController alloc] initWithImageData:data];
        [self presentViewController:vc animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }];
    }
    
}

#pragma mark - Method for Social Sharing
- (void)onShareBtnPress:(UIButton*)sender {
    selectedIndex = sender.tag;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share on your favorite Social Media" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"Report", nil];
    [actionSheet showInView:self.view];
}

#pragma UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIView *selectedCell = [self.scrollView viewWithTag:selectedIndex];
    UIImageView *imageView = (UIImageView *)[selectedCell viewWithTag:101];
    NSString *caption = [(UILabel *)[selectedCell viewWithTag:100] text];
    
    if (caption.length > 0){
        caption = [NSString stringWithFormat:@"\"%@\" - Gum Wall", caption];
    }
    else {
        caption = @"Gum Wall";
    }
    
    if (buttonIndex == 0) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [vc setInitialText:caption];
            [vc addImage:imageView.image];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else {
            NSString *message = @"It seems that we cannot talk to Facebook at the moment or you have not yet added your Facebook account to this device. Go to the Settings application to add your Facebook account to this device.";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            alertView = nil;
            message = nil;
        }
    }
    else if (buttonIndex == 1) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [vc setInitialText:caption];
            [vc addImage:imageView.image];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else {
            NSString *message = @"It seems that we cannot talk to Twitter at the moment or you have not yet added your Twitter account to this device. Go to the Settings application to add your Twitter account to this device.";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            alertView = nil;
            message = nil;
        }
    } else {
        
        PFObject *feedObject = [feeds objectAtIndex:selectedIndex];
        [feedObject setValue:@YES forKey:@"reported"];
        [feedObject saveInBackground];
        
    }
}


#pragma mark - Delegate method of UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 404) {
        if (buttonIndex == 1) {
            [self refreshGumWall];
        }
    }
}

#pragma mark -
#pragma mark - TGCameraDelegate required

- (void)cameraDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)image withCaption:(NSString *)caption {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    PFFile *imageFile = [PFFile fileWithName:@"image.jpg" data:imageData];
    
    PFObject *feedData = [PFObject objectWithClassName:@"FeedData"];
    feedData[@"UUID"] = [[Utilities sharedInstance] getStringForKey:@"UUID"];
    feedData[@"imageFile"] = imageFile;
    feedData[@"voteCount"] = @0;
    feedData[@"location"] = [PFGeoPoint geoPointWithLatitude:self.myLocation.latitude longitude:self.myLocation.longitude];
    feedData[@"photoCaption"] = caption;
    
    KVNProgressConfiguration *configuration = [[KVNProgressConfiguration alloc] init];
    configuration.fullScreen = YES;
    [KVNProgress setConfiguration:configuration];
    [KVNProgress showWithStatus:@"Uploading ..."];
    
    [feedData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [KVNProgress showSuccessWithStatus:@"Success" completion:^{
                int score = [[[Utilities sharedInstance] getStringForKey:@"score"] intValue] + 5;
                self.scoreLabel.title = [NSString stringWithFormat:@"%i",score];
                [[Utilities sharedInstance] setString:self.scoreLabel.title forKey:@"score"];
                [self.scrollView setContentOffset:CGPointZero animated:YES];
                [self refreshGumWall];
            }];
        } else {
            [KVNProgress showErrorWithStatus:@"Error"];
        }
    }];
}

- (void)cameraDidSelectAlbumPhoto:(UIImage *)image {
    NSLog(@"cameraDidSelectAlbumPhoto");
}

@end
