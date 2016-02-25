//
//  StitchingViewController.h
//  PanoDemo
//
//  Created by DJI on 15/7/30.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StitchingViewController : UIViewController

@property (strong,nonatomic) NSMutableArray* imageArray;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView* imageView;

@end
