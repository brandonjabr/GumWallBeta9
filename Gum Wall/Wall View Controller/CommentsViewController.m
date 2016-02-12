//
//  RootViewController.m
//  SecretTestApp
//
//  Created by Aaron Pang on 3/28/14.
//  Copyright (c) 2014 Aaron Pang. All rights reserved.
//

#import "CommentsViewController.h"
#import "UIImage+ImageEffects.h"
#import "ToolBarView.h"
#import "UIFont+SecretFont.h"
#import "CommentTableViewCell.h"
#import "UIView+GradientMask.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "UIViewController+KeyboardAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import <Social/Social.h>
#import "MRProgressOverlayView.h"
#import "CoreDataHandler.h"
#import "CRToast.h"

#define HEADER_HEIGHT 320.0f
#define HEADER_INIT_FRAME CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT)
#define TOOLBAR_INIT_FRAME CGRectMake (0, 292, 320, 22)

const CGFloat kBarHeight = 50.0f;
const CGFloat kBackgroundParallexFactor = 0.5f;
const CGFloat kBlurFadeInFactor = 0.005f;
const CGFloat kTextFadeOutFactor = 0.05f;
const CGFloat kCommentCellHeight = 60.0f;
const CGFloat kToolBarHeight = 65.0f;
const CGFloat kBtnCloseY = 25.0f;

@interface CommentsViewController () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,UIActionSheetDelegate, CommentTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITextView* txtComment;
@property (weak, nonatomic) IBOutlet UILabel *lblOverlay;

@property (strong, nonatomic) ImageData* imageData;
@end

@implementation CommentsViewController {
    UIScrollView *_mainScrollView;
    UIScrollView *_backgroundScrollView;
    UIImageView *_blurImageView;
    UIView *_toolBarView;
    UIView *_commentsViewContainer;
    UITableView *_commentsTableView;
    UIView* commentEditorView;
    
    // To be populated
    UIImageView *imageView;
    UILabel *lblTimer;
    UILabel *photoCaption;
    UILabel *voteCountLbl;
    
    UIButton *upVoteBtn;
    UIButton* downVoteBtn;
    UIButton* btnClose;
    UIButton* shareBtn;
    UIImageView *timerImgView;
    UIButton* overlayButton;
    
    // TODO: Implement these
    UIGestureRecognizer *_leftSwipeGestureRecognizer;
    UIGestureRecognizer *_rightSwipeGestureRecognizer;
    
    NSMutableArray *comments;
    CGPoint previousContentOffset;
}
@synthesize comments = comments;

- (id)initWithImageData:(ImageData*)data {
    self = [super init];
    if (self) {
        comments = [NSMutableArray new];
        self.imageData = data;
        // Load comments data
        [self loadComments];
        
        _mainScrollView = [[UIScrollView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
        _mainScrollView.delegate = self;
        _mainScrollView.bounces = YES;
        _mainScrollView.alwaysBounceVertical = YES;
        _mainScrollView.contentSize = CGSizeZero;
        _mainScrollView.showsVerticalScrollIndicator = YES;
        _mainScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(kBarHeight, 0, 0, 0);
        self.view = _mainScrollView;
        
        _backgroundScrollView = [[UIScrollView alloc] initWithFrame:HEADER_INIT_FRAME];
        _backgroundScrollView.scrollEnabled = NO;
        _backgroundScrollView.contentSize = CGSizeMake(320, 1000);
        
        CGRect imgVFrame = HEADER_INIT_FRAME;
//        imgVFrame.size.height -= kToolBarHeight;
        imageView = [[UIImageView alloc] initWithFrame:imgVFrame];
        imageView.image = self.imageData.image;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIView *fadeView = [[UIView alloc] initWithFrame:imageView.frame];
        fadeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_backgroundScrollView addSubview:imageView];
//        [_backgroundScrollView addSubview:fadeView];
//        [_backgroundScrollView addSubview:_toolBarView];
//        [self.view addSubview:_toolBarView];
        
        // Take a snapshot of the background scroll view and apply a blur to that image
        // Then add the blurred image on top of the regular image and slowly fade it in
        // in scrollViewDidScroll
        UIGraphicsBeginImageContextWithOptions(_backgroundScrollView.bounds.size, _backgroundScrollView.opaque, 0.0);
        [_backgroundScrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        _blurImageView = [[UIImageView alloc] initWithFrame:HEADER_INIT_FRAME];
        _blurImageView.image = [img applyBlurWithRadius:12 tintColor:[UIColor colorWithWhite:0.8 alpha:0.4] saturationDeltaFactor:1.8 maskImage:nil];
        _blurImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _blurImageView.alpha = 0;
        _blurImageView.backgroundColor = [UIColor clearColor];
        [_backgroundScrollView addSubview:_blurImageView];
 
        _commentsViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_backgroundScrollView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - kBarHeight )];
//        [_commentsViewContainer addGradientMaskWithStartPoint:CGPointMake(0.5, 0.0) endPoint:CGPointMake(0.5, 0.03)];
        // Add tool bar
        _toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kToolBarHeight)];
        _toolBarView.autoresizingMask =   UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
        _toolBarView.backgroundColor = [UIColor colorWithRed:36.0/255.0 green:36.0/255.0 blue:48.0/255.0 alpha:1.0f];
        
        //add photo caption
        CGRect captionLbl = CGRectMake(15, 10, 265, 30);
        
        photoCaption = [[UILabel alloc] initWithFrame:captionLbl];
        photoCaption.center = CGPointMake(photoCaption.center.x, _toolBarView.center.y);
        photoCaption.text = self.imageData.imageDescription;
        if([photoCaption.text isEqualToString:@"Add a caption..."]){
            photoCaption.text = @"";
        }
        
        photoCaption.textColor = [UIColor whiteColor];
        photoCaption.font = [UIFont fontWithName:@"Avenir-Medium" size:18];
        photoCaption.numberOfLines = 2;
        [_toolBarView addSubview:photoCaption];
        
        //add up vote button
        CGRect upVoteBtnRect = CGRectMake(imageView.frame.size.width - 30, 2, 25, 20);
        
        upVoteBtn = [[UIButton alloc] initWithFrame:upVoteBtnRect];
        [upVoteBtn setImage:[UIImage imageNamed:@"icon_up"] forState:UIControlStateNormal];
        [upVoteBtn setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateHighlighted];
        [upVoteBtn addTarget:self action:@selector(onUpVotePress:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:upVoteBtn];
        
        //add vote count label
        CGRect voteCountLblRect = CGRectMake(upVoteBtn.frame.origin.x-12.50f, CGRectGetMaxY(upVoteBtn.frame)+2.0 , 50, 21);
        int fontSize = 16.0;
        voteCountLbl = [[UILabel alloc] initWithFrame:voteCountLblRect];
        voteCountLbl.font = [UIFont fontWithName:@"Avenir-Medium" size:fontSize];
        voteCountLbl.textColor = [UIColor colorWithRed:42.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0];
        voteCountLbl.textAlignment = NSTextAlignmentCenter;
        voteCountLbl.tag = 102;
        voteCountLbl.text =  [NSString stringWithFormat:@"%@",self.imageData.voteCount];
        [_toolBarView addSubview:voteCountLbl];
        
        //add down vote button
        CGRect downVoteBtnRect = CGRectMake(upVoteBtn.frame.origin.x, CGRectGetMaxY(voteCountLbl.frame), 25, 20);
        
        downVoteBtn = [[UIButton alloc] initWithFrame:downVoteBtnRect];
        [downVoteBtn setImage:[UIImage imageNamed:@"icon_down.png"] forState:UIControlStateNormal];
        [downVoteBtn setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateHighlighted];
        [downVoteBtn addTarget:self action:@selector(onDownVotePress:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:downVoteBtn];
        
        _commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_toolBarView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - kBarHeight ) style:UITableViewStylePlain];
        _commentsTableView.scrollEnabled = NO;
        _commentsTableView.delegate = self;
        _commentsTableView.dataSource = self;
        _commentsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _commentsTableView.separatorColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8];
        
        [self.view addSubview:_backgroundScrollView];
        [_commentsViewContainer addSubview:_toolBarView];
        [_commentsViewContainer addSubview:_commentsTableView];
        [self.view addSubview:_commentsViewContainer];
        
        // Let's put in some fake data!
//        comments = [@[] mutableCopy];
//        comments = [@[@"Oh my god! Me too!", @"No way! I love secrets too!", @"I for some reason really like sharing my deepest darkest secrest to the entire world", @"More comments", @"Go Toronto Blue Jays!", @"I rather use Twitter", @"I don't get Secret", @"I don't have an iPhone", @"How are you using this then?"] mutableCopy];
        
        [_commentsTableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"Cell"];
        
        // Add share button
        CGRect shareBtnFrame = CGRectMake([UIScreen mainScreen].bounds.size.width - 37, imageView.frame.size.height - 22, 30, 10);
        shareBtn = [[UIButton alloc] initWithFrame:shareBtnFrame];
//        [shareBtn setContentMode:UIViewContentModeCenter];
        [shareBtn setImage:[UIImage imageNamed:@"btnShare.png"] forState:UIControlStateNormal];
        [shareBtn addTarget:self action:@selector(onShareBtnPress) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:shareBtn];
        
        //add timer image
        CGRect timerImgRect = CGRectMake(8, imageView.frame.size.height - 30, 15, 15);
        timerImgView = [[UIImageView alloc] initWithFrame:timerImgRect];
        timerImgView.image = [UIImage imageNamed:@"icon_timer"];
        [self.view addSubview:timerImgView];
        
        //add timer label
        CGRect timerLblRect = CGRectMake(30, imageView.frame.size.height - 32, 50, 21);
        
        lblTimer = [[UILabel alloc] initWithFrame:timerLblRect];
        lblTimer.font = [UIFont fontWithName:@"Avenir-Black" size:13];
        lblTimer.textColor = [UIColor whiteColor];
        lblTimer.text =  [[Utilities sharedInstance] getElapsedTime:[[NSDate date] dateByAddingTimeInterval:-8]];
        [self.view addSubview:lblTimer];
        
        // Add close button
        btnClose = [[UIButton alloc] initWithFrame:CGRectMake(15, kBtnCloseY, 18, 18)];
        [btnClose setImage:[UIImage imageNamed:@"btn_close_comment.png"] forState:UIControlStateNormal];
        [btnClose addTarget:self action:@selector(btnClosePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btnClose];
        
        // Add Comments Editor View
        NSArray* a = [[NSBundle mainBundle] loadNibNamed:@"CommentEditorView" owner:self options:nil];
        commentEditorView = [a firstObject];
        CGRect frame = commentEditorView.frame;
        frame.origin.y = self.view.frame.size.height - frame.size.height;
        commentEditorView.frame = frame;
        AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.window addSubview:commentEditorView];
        
        //initializing the loading view
        [MRProgressOverlayView showOverlayAddedTo:self.navigationController.view animated:YES];
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)changeAlpha:(CGFloat)alpha
{
    btnClose.alpha = alpha;
    shareBtn.alpha = alpha;
    timerImgView.alpha = alpha;
    lblTimer.alpha = alpha;
    _toolBarView.alpha = alpha;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat delta = 0.0f;
    CGRect rect = HEADER_INIT_FRAME;
    // Here is where I do the "Zooming" image and the quick fade out the text and toolbar
    if (scrollView.contentOffset.y < 0.0f) {
        CGFloat alpha = MAX((scrollView.contentOffset.y + (kToolBarHeight/2))/(kToolBarHeight/2),0);
        [self changeAlpha:alpha];
        delta = fabs(MIN(0.0f, _mainScrollView.contentOffset.y));
        _backgroundScrollView.frame = CGRectMake(CGRectGetMinX(rect) - delta / 2.0f, CGRectGetMinY(rect) - delta, CGRectGetWidth(rect) + delta, CGRectGetHeight(rect) + delta);
        
        [_commentsTableView setContentOffset:(CGPoint){0,0} animated:NO];
    } else {
        delta = _mainScrollView.contentOffset.y;
        CGRect btnCloseRect = btnClose.frame;
        btnCloseRect.origin.y = delta + kBtnCloseY;
        btnClose.frame = btnCloseRect;
        
        _blurImageView.alpha = MIN(1 , delta * kBlurFadeInFactor);
        CGFloat backgroundScrollViewLimit = _backgroundScrollView.frame.size.height - kBarHeight;
        // Here I check whether or not the user has scrolled passed the limit where I want to stick the header, if they have then I move the frame with the scroll view
        // to give it the sticky header look
        if (delta > backgroundScrollViewLimit) {
            _backgroundScrollView.frame = (CGRect) {.origin = {0, delta - _backgroundScrollView.frame.size.height + kBarHeight}, .size = {self.view.frame.size.width, HEADER_HEIGHT}};
            _commentsViewContainer.frame = (CGRect){.origin = {0, CGRectGetMinY(_backgroundScrollView.frame) + CGRectGetHeight(_backgroundScrollView.frame)}, .size = _commentsViewContainer.frame.size };
            _commentsTableView.contentOffset = CGPointMake (0, delta - backgroundScrollViewLimit);
            CGFloat contentOffsetY = -backgroundScrollViewLimit * kBackgroundParallexFactor;
            [_backgroundScrollView setContentOffset:(CGPoint){0,contentOffsetY} animated:NO];
        }
        else {
            _backgroundScrollView.frame = rect;
            _commentsViewContainer.frame = (CGRect){.origin = {0, CGRectGetMinY(rect) + CGRectGetHeight(rect)}, .size = _commentsViewContainer.frame.size };
            [_commentsTableView setContentOffset:(CGPoint){0,0} animated:NO];
            [_backgroundScrollView setContentOffset:CGPointMake(0, -delta * kBackgroundParallexFactor)animated:NO];
        }
    }
}

- (void)loadComments
{
    // Fetch comments for image
    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
    [query whereKey:kPhotoId equalTo:self.imageData.imageId];
    [query whereKey:kVoteCountComment greaterThan:@-5];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [MRProgressOverlayView dismissOverlayForView:self.navigationController.view animated:YES];
        if (!error) {
            if (objects.count > 0) {
                self.comments = [objects mutableCopy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_commentsTableView reloadData];
                });
                
            }
        }
    }];
}

- (void)updateOverlayText
{
    if (self.imageData.isLocalFeed) {
        self.lblOverlay.text = @"Comment back";
    }
    else
    {
        self.lblOverlay.text = @"Replies not allowed";
    }
}

#pragma mark

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [comments count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject* data = [comments objectAtIndex:[indexPath row]];
    NSString *text = data[kCommentText];
    CGSize requiredSize;
    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        CGRect rect = [text boundingRectWithSize:(CGSize){225, MAXFLOAT}
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont secretFontLightWithSize:16.f]}
                                                   context:nil];
        requiredSize = rect.size;
    } else {
        requiredSize = [text sizeWithFont:[UIFont secretFontLightWithSize:16.f] constrainedToSize:(CGSize){225, MAXFLOAT} lineBreakMode:NSLineBreakByWordWrapping];
    }
    return kCommentCellHeight + requiredSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject* data = [comments objectAtIndex:[indexPath row]];
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
//    if (!cell) {
//        cell = [[CommentTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"Cell %ld", indexPath.row]];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        cell.commentLabel.frame = (CGRect) {.origin = cell.commentLabel.frame.origin, .size = {CGRectGetMinX(cell.likeButton.frame) - CGRectGetMaxY(cell.iconView.frame) - kCommentPaddingFromLeft - kCommentPaddingFromRight,[self tableView:tableView heightForRowAtIndexPath:indexPath] - kCommentCellHeight}};
        
//        cell.timeLabel.frame = (CGRect) {.origin = {CGRectGetMinX(cell.commentLabel.frame), CGRectGetMaxY(cell.commentLabel.frame)}};
//        cell.timeLabel.text = @"1d ago";
//        [cell.timeLabel sizeToFit];
        
        // Don't judge my magic numbers or my crappy assets!!!
//        cell.likeCountImageView.frame = CGRectMake(CGRectGetMaxX(cell.timeLabel.frame) + 7, CGRectGetMinY(cell.timeLabel.frame) + 3, 10, 10);
//        cell.likeCountImageView.image = [UIImage imageNamed:@"like_greyIcon.png"];
//        cell.likeCountLabel.frame = CGRectMake(CGRectGetMaxX(cell.likeCountImageView.frame) + 3, CGRectGetMinY(cell.timeLabel.frame), 0, CGRectGetHeight(cell.timeLabel.frame));
//    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.commentLabel.numberOfLines = 0;
    cell.commentLabel.text = data[kCommentText];
    cell.lblVoteCount.text = [NSString stringWithFormat:@"%@",data[kVoteCount]];
    cell.lblTime.text = [[Utilities sharedInstance] getElapsedTime:data.createdAt];
    cell.delegate = self;
    cell.parentTableView = _commentsTableView;
    return cell;
}

#pragma mark View life cycle
- (void)viewDidAppear:(BOOL)animated {
    _mainScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), kToolBarHeight + _commentsTableView.contentSize.height + CGRectGetHeight(_backgroundScrollView.frame) + commentEditorView.frame.size.height + 10.0);
    // Set overlay button dimension
    overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    overlayButton.frame = self.view.frame;
    overlayButton.backgroundColor = [UIColor clearColor];
    [overlayButton addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Update overlay text
    [self updateOverlayText];
    [self subscribeToKeyboard];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self an_unsubscribeKeyboard];
}

- (void)hideKeyboard
{
    [self.txtComment resignFirstResponder];
}

- (void)subscribeToKeyboard {
    [self an_subscribeKeyboardWithAnimations:^(CGRect keyboardRect, NSTimeInterval duration, BOOL isShowing) {
        if (isShowing) {
            // Hide textview overlay label text
            self.lblOverlay.hidden = YES;
            // Scroll view to top
            CGSize contentSize = _mainScrollView.contentSize;
            contentSize.height += CGRectGetHeight(self.view.frame);
            _mainScrollView.contentSize = contentSize;
            previousContentOffset = _mainScrollView.contentOffset;
            CGPoint contentOffset = CGPointMake(0.0f, HEADER_HEIGHT);
            if (_mainScrollView.contentOffset.y < contentOffset.y) {
                [_mainScrollView setContentOffset:contentOffset animated:YES];
            }
            
            CGRect commentFrame = commentEditorView.frame;
            commentFrame.origin.y -= CGRectGetHeight(keyboardRect);
            commentEditorView.frame = commentFrame;
            // Add hide keyboard button
            [self.view insertSubview:overlayButton belowSubview:btnClose];
        } else {
            // Unhide overlay text
            self.lblOverlay.hidden = NO;
            // Scroll view back
            CGSize contentSize = _mainScrollView.contentSize;
            contentSize.height -= CGRectGetHeight(self.view.frame);
            _mainScrollView.contentSize = contentSize;
            [_mainScrollView setContentOffset:previousContentOffset animated:YES];
            
            CGRect commentFrame = commentEditorView.frame;
            commentFrame.origin.y = (self.view.frame.size.height - commentFrame.size.height);
            commentEditorView.frame = commentFrame;
            // Remove overlay button
            [overlayButton removeFromSuperview];
        }
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Selectors
- (void)btnClosePressed
{
    // Remove Comment Editor View
    [commentEditorView removeFromSuperview];

    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }];
}

- (void)onShareBtnPress
{
    
}

- (void)onUpVotePress:(UIButton*)sender {
    
    if(self.imageData.isLocalFeed == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote on your local feed!"];
    }
    else {
        
        PFObject *currentFeed = self.imageData.imagePFObject;
        if ([CoreDataHandler isUpVotedImageID:currentFeed.objectId] || [CoreDataHandler isDownVotedImageID:currentFeed.objectId]) {
            [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
        }
        else {
            [sender setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateNormal];
            
            int voteCount =  [voteCountLbl.text intValue] + 1;
            
            currentFeed[kVoteCount] = [NSNumber numberWithInt:voteCount];
            [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
                    [CoreDataHandler updateVoteDataForImageID:currentFeed.objectId withVoteUp:YES andVoteDown:NO];
                    
                    int score = [[[Utilities sharedInstance] getStringForKey:@"score"] intValue] + 1;
                    [[Utilities sharedInstance] setString:[NSString stringWithFormat:@"%d",score] forKey:@"score"];
                    
                    voteCountLbl.text = [NSString stringWithFormat:@"%i",voteCount];
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
    
    if(self.imageData.isLocalFeed == NO) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote on your local feed!"];
    }
    else {
        
        PFObject *currentFeed = self.imageData.imagePFObject;
        if ([CoreDataHandler isUpVotedImageID:currentFeed.objectId] || [CoreDataHandler isDownVotedImageID:currentFeed.objectId]) {
            [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
        }
        else {
            [sender setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateNormal];
            
            int voteCount =  [voteCountLbl.text intValue] - 1;
            
            currentFeed[kVoteCount] = [NSNumber numberWithInt:voteCount];
            [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
                    [CoreDataHandler updateVoteDataForImageID:currentFeed.objectId withVoteUp:NO andVoteDown:YES];
                    
                    voteCountLbl.text = [NSString stringWithFormat:@"%i",voteCount];
                }
                else {
                    [sender setImage:[UIImage imageNamed:@"icon_down"] forState:UIControlStateNormal];
                    [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to DownVote. Please check your internet connection and try again."];
                }
            }];
        }
    }
}

- (IBAction)btnSendPressed:(id)sender
{
    NSString* commentText = self.txtComment.text;
    self.txtComment.text = @"";
    [self.txtComment resignFirstResponder];
    if (!self.imageData.isLocalFeed) {
        NSDictionary *options = @{
                                  kCRToastTextKey : @"Can't comment on non-local feed!",
                                  kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                  kCRToastBackgroundColorKey : [UIColor redColor],
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionBottom),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                  };
        [CRToastManager showNotificationWithOptions:options
                                    completionBlock:^{
                                        NSLog(@"Completed");
                                    }];
        
        return;
    }
    if (!self.txtComment.text || [self.txtComment.text isEqualToString:@""]) {
        return;
    }
    PFObject *commentObj = [PFObject objectWithClassName:@"Comment"];
    commentObj[kCommentText] = commentText;
    commentObj[kVoteCount] = @0;
    commentObj[kPhotoId] = self.imageData.imageId;
    [commentObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [self.comments addObject:commentObj];
                [_commentsTableView reloadData];
            }
            else
            {
                [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to post comment. Please check your internet connection and try again."];
            }
        });
    }];
}

#pragma mark - Method for Social Sharing
- (void)onShareBtnPress:(UIButton*)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share on your favorite Social Media" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"Report", nil];
    [actionSheet showInView:self.view];
}

#pragma UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *caption = self.imageData.imageDescription;
    
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
            [vc addImage:self.imageData.image];
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
            [vc addImage:self.imageData.image];
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
        
        PFObject *feedObject = self.imageData.imagePFObject;
        [feedObject setValue:@YES forKey:@"reported"];
        [feedObject saveInBackground];
        
    }
}

#pragma mark - CommentTableViewCellDelegate -
- (void)btnUpPressedAtIndexPath:(NSIndexPath *)index
{
    __block CommentTableViewCell* cell = (CommentTableViewCell*)[_commentsTableView cellForRowAtIndexPath:index];
    PFObject *currentFeed = [self.comments objectAtIndex:index.row];
    if ([CoreDataHandler isUpVotedCommentID:currentFeed.objectId] || [CoreDataHandler isDownVotedCommentID:currentFeed.objectId]) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
    }
    else {
        [cell.btnUp setImage:[UIImage imageNamed:@"icon_up_selected"] forState:UIControlStateNormal];
        
        [currentFeed incrementKey:kVoteCount];
        [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                
                [CoreDataHandler updateCommentVoteDataForCommentID:currentFeed.objectId withVoteUp:YES andVoteDown:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSInteger number = [currentFeed[kVoteCount] integerValue];
                    cell.lblVoteCount.text = [NSString stringWithFormat:@"%ld",number];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.btnUp setImage:[UIImage imageNamed:@"icon_up_comment"] forState:UIControlStateNormal];
                    [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to UpVote. Please check your internet connection and try again."];
                });
                
            }
        }];
    }
}

- (void)btnDownPressedAtIndexPath:(NSIndexPath *)index
{
    CommentTableViewCell* cell = (CommentTableViewCell*)[_commentsTableView cellForRowAtIndexPath:index];
    PFObject *currentFeed = [self.comments objectAtIndex:index.row];
    if ([CoreDataHandler isUpVotedCommentID:currentFeed.objectId] || [CoreDataHandler isDownVotedCommentID:currentFeed.objectId]) {
        [[Utilities sharedInstance] showAlertWithTitle:@"Oops!" message:@"You can only vote once!"];
    }
    else {
        [cell.btnDown setImage:[UIImage imageNamed:@"icon_down_selected"] forState:UIControlStateNormal];

        [currentFeed incrementKey:kVoteCount byAmount:@-1];
        [currentFeed saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                
                [CoreDataHandler updateCommentVoteDataForCommentID:currentFeed.objectId withVoteUp:NO andVoteDown:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSInteger number = [currentFeed[kVoteCount] integerValue];
                   cell.lblVoteCount.text = [NSString stringWithFormat:@"%ld",number];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.btnDown setImage:[UIImage imageNamed:@"icon_down_comment"] forState:UIControlStateNormal];
                    [[Utilities sharedInstance] showAlertWithTitle:@"Error!" message:@"Unable to DownVote. Please check your internet connection and try again."];
                });
                
            }
        }];
    }
}

#pragma mark Memory Management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
