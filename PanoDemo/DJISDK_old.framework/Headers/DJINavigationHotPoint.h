//
//  DJIHotPointSurround.h
//  DJIVisionSDK
//
//  Created by Ares on 15/4/13.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIFoundation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJINavigation.h>

/**
 *  Max surrounding radius
 */
DJI_API_EXTERN const float DJIMaxSurroundingRadius;

/**
 *  Min surrounding radius
 */
DJI_API_EXTERN const float DJIMinSurroundingRadius;

/**
 *  Entry point position relative to the hot point
 */
typedef NS_ENUM(NSUInteger, DJIHotPointEntryPoint){
    /**
     *  Entry from the north
     */
    DJIHotPointEntryFromNorth,
    /**
     *  Entry from the south
     */
    DJIHotPointEntryFromSouth,
    /**
     *  Entry from the west
     */
    DJIHotPointEntryFromWest,
    /**
     *  Entry from the east
     */
    DJIHotPointEntryFromEast,
    /**
     *  Entry from point which nesrest to the current position
     */
    DJIHotPointEntryFromNearest,
};

/**
 *  Heading mode for aircraft while surrounding the hot point
 */
typedef NS_ENUM(NSUInteger, DJIHotPointHeadingMode){
    /**
     *  Along the circle looking forward
     */
    DJIHotPointHeadingAlongTheCircleLookingForward,
    /**
     *  Along the circle looking backward
     */
    DJIHotPointHeadingAlongTheCircleLookingBackward,
    /**
     *  Toward the hot point
     */
    DJIHotPointHeadingTowardHotPoint,
    /**
     *  Backward the hot point
     */
    DJIHotPointHeadingBackwardHotPoint,
    /**
     *  Heading Controlled by remote controller
     */
    DJIHotPointHeadingControlledByRemoteController,
    /**
     *  Using initial direction always. The initial direction is the aircraft's Yaw heading while starting the mission.
     */
    DJIHotPointHeadingUsingInitialDirection
};

/**
 *  The hotpoint mission executing state
 */
typedef NS_ENUM(uint8_t, DJIHotpointMissionExecutePhase){
    /**
     *  Initializing
     */
    DJIHotpointMissionExecutePhaseInitializing,
    /**
     *  Moving,
     */
    DJIHotpointMissionExecutePhaseMoving,
    /**
     *  Waing, Maybe the gps level is bad, waiting gps ready.
     */
    DJIHotpointMissionExecutePhaseWaiting,
};

@interface DJIHotpointMissionStatus : DJINavigationMissionStatus

/**
 *  Execute phase of hot point mission.
 */
@property(nonatomic, readonly) DJIHotpointMissionExecutePhase currentPhase;

/**
 *  The current radius to the hotpoint
 */
@property(nonatomic, readonly) float currentRadius;

/**
 *  Error for the hot point mission when interrupted unexpectedly. No error when the error.errorCode is ERR_Successed.
 */
@property(nonatomic, readonly) DJIError* error;

@end


/**
 *  Mission for Hot point navigation
 */
@interface DJIHotPointMission : NSObject

/**
 *  Hot point coordinate in degree
 */
@property(nonatomic, assign) CLLocationCoordinate2D hotPoint;

/**
 *  Hot point altitude in meter. relate to the ground.
 */
@property(nonatomic, assign) float altitude;

/**
 *  Radius in meter for surrounding. should be in range [5, 500]
 */
@property(nonatomic, assign) float surroundRadius;

/**
 *  Surround the hot point in clockwise
 */
@property(nonatomic, assign) BOOL clockwise;

/**
 *  Angular velocity of drone, the unit is degree/second. in range [0, 30], default is 20. The angular velocity relative to the surround radius. use the + maxAngularVelocityForRadius: to get max supported angular velocity.
 */
@property(nonatomic, assign) float angularVelocity;

/**
 *  Entry point for the aircraft to entry the air line when start the mission.
 */
@property(nonatomic, assign) DJIHotPointEntryPoint entryPoint;

/**
 *  Heading of aircraft while in surrounding
 */
@property(nonatomic, assign) DJIHotPointHeadingMode headingMode;

/**
 *  Init mission instance using coordinate
 *
 *  @param coordinate Hot point coordinate
 *
 *  @return Mission Instance
 */
-(id) initWithCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 *  Get supported maximum angular velocity for radius
 *
 *  @param surroundRadius Input surround radius in [5, 500], or 0 will be return.
 *
 *  @return Return the supported maximum angular velocity for surroundRadius
 */
+(float) maxAngularVelocityForRadius:(float)surroundRadius;

@end

@protocol DJINavigationHotPoint <DJINavigation>

@required

/**
 *  Current execute mission
 */
@property(nonatomic, readonly) DJIHotPointMission* currentHotPointMisson;

/**
 *  Set mission
 *
 *  @param mission Mission to be execute
 *
 *  @return Return YES while the parameters of mission is valid.
 */
-(BOOL) setHotPointMission:(DJIHotPointMission*)mission;

/**
 *  Get mission from aircraft. If get successed, property 'currentHotPointMission' will be updated to the downloaded mission.
 *
 *  @param block Remote execute result block.
 */
-(void) getHotPointMissionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Start execute hot point surround mission. Will enter NavigationMissionHotpoint mode.
 *
 *  @param result Remote execute result
 */
-(void) startHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Pasue execute hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) pauseHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Resume hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) resumeHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Stop hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) stopHotPointMissionWithResult:(DJIExecuteResultBlock)result;

@end
