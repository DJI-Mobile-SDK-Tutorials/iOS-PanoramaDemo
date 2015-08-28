//
//  DJIIOC.h
//  DJISDK
//
//  Created by Ares on 15/7/1.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJINavigation.h>
#import <DJISDK/DJIObject.h>

/**
 *  IOC type
 */
typedef NS_ENUM(uint8_t, DJIIOCType){
    /**
     *  IOC course lock. The aircraft only moving at the locked course.
     */
    DJIIOCTypeCourseLock = 1,
    /**
     *  IOC home lock. The aircraft could only approach to or far away frome the home point when moving. the home lock mission need the aircraft recorded a home point.
     */
    DJIIOCTypeHomeLock = 2,
};

/**
 *  Mission status for ioc
 */
@interface DJIIOCMissionStatus : DJINavigationMissionStatus

/**
 *  Error occured in executing ioc fly mission. show the reason why the ioc mission stop unexpectedly. error.errorCode is ERR_Successed is no error.
 */
@property(nonatomic, readonly) DJIError* error;

@end

/**
 *  IOC mission defines.
 */
@interface DJIIOCMission : NSObject

/**
 *  IOC type for mission.
 */
@property(nonatomic, readonly) DJIIOCType iocType;

-(id) initWithIOCType:(DJIIOCType)type;

@end

/**
 *  Define the IOC(Intelligent Orientation Control) mission operation interface.
 */
@protocol DJINavigationIOC <DJINavigation>

@property(nonatomic, readonly) DJIIOCMission* currentIOCMission;

/**
 *  Set IOC mission, user should set IOC mission first before calling startIOCMissionWithResult:
 *
 *  @param iocMission IOC mission
 *
 *  @return Return result of IOC mission checking. if checked successed, then 'iocMission' will be set to the property currentIOCMission.
 */
-(BOOL) setIOCMission:(DJIIOCMission*)iocMission;

/**
 *  Start IOC mission. currentIOCMission should not be nil. and there is no other mission is in executing.
 *
 *  @param block Remote execute result callback.
 */
-(void) startIOCMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop IOC mission.
 *
 *  @param block Remote execute result callback.
 */
-(void) stopIOCMissionWithResult:(DJIExecuteResultBlock)block;

@end
