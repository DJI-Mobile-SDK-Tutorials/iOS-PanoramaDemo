//
//  DJIFollowMe.h
//  DJIVisionSDK
//
//  Created by Ares on 15/4/17.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIFoundation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJINavigation.h>

/**
 *  Heading mode, decided how the aircraft heading during the follow mission.
 */
typedef NS_ENUM(uint8_t, DJIFollowMeHeadingMode){
    /**
     *  Aircraft will heading toward to the follow position
     */
    DJIFollowMeHeadingTowardFollowPosition,
    /**
     *  Aircraft's heading will controlled by remote controller
     */
    DJIFollowMeHeadingControlledByRemoteController,
};

/**
 *  The follow me mission executing phase
 */
typedef NS_ENUM(uint8_t, DJIFollowMeMissionExecutePhase){
    /**
     *  Initializing
     */
    DJIFollowMeMissionExecutePhaseInitializing,
    /**
     *  Moving,
     */
    DJIFollowMeMissionExecutePhaseMoving,
    /**
     *  Waing, Maybe the gps quality is bad or the connection is broken, waiting ok.
     */
    DJIFollowMeMissionExecutePhaseWaiting,
};

@interface DJIFollowMeMissionStatus : DJINavigationMissionStatus

/**
 *  Execute phase of follow me mission.
 */
@property(nonatomic, readonly) DJIFollowMeMissionExecutePhase currentPhase;

/**
 *  Distance between aircraft and the target follow position. (m)
 */
@property(nonatomic, readonly) float distance;

/**
 *  Error for the follow me mission when interrupted unexpectedly. No error when the error.errorCode is ERR_Successed.
 */
@property(nonatomic, readonly) DJIError* error;

@end

@interface DJIFollowMeMission : NSObject

/**
 *  User's initial coordinate
 */
@property(nonatomic, assign) CLLocationCoordinate2D userCoordinate;

/**
 *  Heading mode, decided how the aricraft heading during the mission.
 */
@property(nonatomic, assign) DJIFollowMeHeadingMode headingMode;

@end

@protocol DJINavigationFollowMe <DJINavigation>

@required

@property(nonatomic, readonly) DJIFollowMeMission* currentFollowMeMission;
/**
 *  Set follow me mission
 *
 *  @param mission Follow me mission
 *
 *  @return Return result of mission checking. if the mission's userCoordinate is invalid, return NO.
 */
-(BOOL) setFollowMeMission:(DJIFollowMeMission*)mission;

/**
 *  Start follow me mission
 *
 *  @param block Remote execute result
 */
-(void) startFollowMeMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Pause follow me mission
 *
 *  @param block Remote execute result
 */
-(void) pauseFollowMeMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Resume follow me mission
 *
 *  @param block Remote execute result
 */
-(void) resumeFollowMeMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop follow me mission
 *
 *  @param block Remote execute result
 */
-(void) stopFollowMeMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Update user coordinate
 *
 *  @param coordinate Coordinate of user, the aricraft will follow this coordinate.
 *  @param block      Remote execute result callback
 */
-(void) updateUserCoordinate:(CLLocationCoordinate2D)coordinate withResult:(DJIExecuteResultBlock)block;

@end
