//
//  ViewController.h
//  Gum Wall
//
//  Created by Muhammad Junaid Butt on 01/01/2015.
//  Copyright (c) 2015 AMP, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TGCamera.h"
#import "TGCameraViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, TGCameraDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scoreLabel;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D myLocation;

@end
