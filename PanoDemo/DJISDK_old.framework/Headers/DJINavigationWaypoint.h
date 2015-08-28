//
//  DJINavigationWaypoint.h
//  DJISDK
//
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Waypoint mission state
 */
typedef NS_ENUM(uint8_t, DJIWaypointMissionExecutePhase){
    /**
     *  Initializing is the phase that the mission started and going to the first waypoint from current position
     */
    DJIWaypointMissionExecutePhaseInitializing,
    /**
     *  Moving to target waypoint
     */
    DJIWaypointMissionExecutePhaseMoving,
    /**
     *  Adjust angle
     */
    DJIWaypointMissionExecutePhaseRotating,
    /**
     *  Reached a waypoint and doing action
     */
    DJIWaypointMissionExecutePhaseDoingAction,
    /**
     *  Reached a waypoint and will start action
     */
    DJIWaypointMissionExecutePhaseBeginAction,
    /**
     *  Reached a waypoint and finished action
     */
    DJIWaypointMissionExecutePhaseFinishedAction,
};

typedef NS_ENUM(uint8_t, DJIWaypointMissionFinishedAction)
{
    DJIWaypointMissionFinishedNoAction,
    DJIWaypointMissionFinishedGoHome,
    DJIWaypointMissionFinishedAutoLanding,
    DJIWaypointMissionFinishedGoFirstWaypoint,
    DJIWaypointMissionFinishedWaiting
};

/**
 *  Waypoint mission status
 */
@interface DJIWaypointMissionStatus : DJINavigationMissionStatus

/**
 *  Target waypoint index
 */
@property(nonatomic, readonly) NSInteger targetWaypointIndex;

/**
 *  Execute phase
 */
@property(nonatomic, readonly) DJIWaypointMissionExecutePhase currentPhase;

@end

@protocol DJINavigationWaypoint <DJINavigation>

@property(nonatomic, assign) float maxFlightSpeed;

@property(nonatomic, assign) float autoFlightSpeed;

@property(nonatomic, assign) DJIWaypointMissionFinishedAction missionFinishedAction;


@end
