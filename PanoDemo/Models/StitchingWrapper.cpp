//
//  Stitching.cpp
//  PanoDemo
//
//  Created by lizefei on 15/7/30.
//  Copyright (c) 2015年 DJI. All rights reserved.
//


#include "stitchingWrapper.h"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/stitching/stitcher.hpp"

using namespace cv;

bool stitch (const cv::vector <cv::Mat> & images, cv::Mat &result) {
    Stitcher stitcher = Stitcher::createDefault(false);//don't need gpu
    Stitcher::Status status = stitcher.stitch(images, result);
    
    if (status != Stitcher::OK) {
        return false;
    }
    return true;
}