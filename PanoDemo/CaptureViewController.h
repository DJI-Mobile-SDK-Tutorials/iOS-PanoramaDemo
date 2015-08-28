//
//  CaptureViewController.h
//  PanoDemo
//
//  Created by lizefei on 15/7/29.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaptureViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (strong, nonatomic) IBOutlet UIButton *enterNavigationBtn;
@property (strong, nonatomic) IBOutlet UIButton *captureBtn;
@property (strong, nonatomic) IBOutlet UIButton *downloadBtn;

- (IBAction)onEnterNavigationClicked:(id)sender;
- (IBAction)onCaptureButtonClicked:(id)sender;
- (IBAction)onDownloadButtonClicked:(id)sender;

@end
