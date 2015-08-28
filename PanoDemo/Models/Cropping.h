//
//  Cropping.h
//  PanoDemo
//
//  Created by lizefei on 15/7/31.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cropping : NSObject

+ (bool) cropWithMat: (const cv::Mat &)src andResult:(cv::Mat &)dest;

@end
