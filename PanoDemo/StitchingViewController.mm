//
//  StitchingViewController.mm
//  PanoDemo
//
//  Created by DJI on 15/7/30.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import "StitchingViewController.h"
#import "Stitching.h"
#import "OpenCVConversion.h"
#import "Cropping.h"

@implementation StitchingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak StitchingViewController *weakSelf = self;
    __weak NSMutableArray *weakImageArray = self.imageArray;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        cv::Mat stitchMat;
        if(![Stitching stitchImageWithArray:weakImageArray andResult:stitchMat]) {
            [weakSelf showAlertWithTitle:@"Stitching" andMessage:@"Stitching failed"];
            return;
        }
        
        cv::Mat cropedMat;
        if(![Cropping cropWithMat:stitchMat andResult:cropedMat]){
            [weakSelf showAlertWithTitle:@"Cropping" andMessage:@"cropping failed"];
            return;
        }
        
        UIImage *stitchImage=[OpenCVConversion UIImageFromCVMat:cropedMat];
        UIImageWriteToSavedPhotosAlbum(stitchImage, nil, nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf showAlertWithTitle:@"Save Photo Success" andMessage:@"Panoroma photo is saved to Album, please check it!"];
            _imageView.image=stitchImage;
        });
    });

}

//show the alert view in main thread
-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [_activityIndicator stopAnimating];
    });
}

@end
