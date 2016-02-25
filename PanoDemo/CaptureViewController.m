//
//  CaptureViewController.m
//  PanoDemo
//
//  Created by DJI on 15/7/29.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import "CaptureViewController.h"
#import <DJISDK/DJISDK.h>
#import "VideoPreviewer.h"

#define PHOTO_NUMBER 8
#define ROTATE_ANGLE 45
#define kCaptureModeAlertTag 100

#define ENTER_DEBUG_MODE 0

#define weakSelf(__TARGET__) __weak typeof(self) __TARGET__=self
#define weakReturn(__TARGET__) if(__TARGET__==nil)return;

@interface CaptureViewController ()<DJICameraDelegate, DJIPlaybackDelegate, DJISDKManagerDelegate, DJIMissionManagerDelegate, DJIFlightControllerDelegate>{
    
}

@property (nonatomic, assign) __block int selectedPhotoNumber;
@property (strong, nonatomic) UIAlertView* downloadProgressAlert;
@property (strong, nonatomic) UIAlertView* prepareMissionProgressAlert;
@property (strong, nonatomic) NSMutableArray* imageArray;
@property (nonatomic) bool isMissionStarted;
@property (atomic) CLLocationCoordinate2D aircraftLocation;
@property (atomic) double aircraftAltitude;
@property (atomic) DJIGPSSignalStatus gpsSignalStatus;
@property (atomic) double aircraftYaw;
@property (nonatomic, strong) DJIMission* mission;
@end

@implementation CaptureViewController

#pragma mark Inherited Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Panorama Demo";
    
    self.isMissionStarted = NO;
    self.aircraftLocation = kCLLocationCoordinate2DInvalid;
    
    [[VideoPreviewer instance] setView:self.fpvPreviewView];
    [self registerApp];
}

//Pass the downloaded photos to StitchingViewController
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"Stitching"]) {
        [segue.destinationViewController setValue:self.imageArray forKey:@"imageArray"];
    }
}

#pragma mark DJISDKManagerDelegate Methods
- (void)sdkManagerProductDidChangeFrom:(DJIBaseProduct *)oldProduct to:(DJIBaseProduct *)newProduct
{
    DJICamera* camera = [self fetchCamera];
    if (camera) {
        [camera setDelegate:self];
        [camera.playbackManager setDelegate:self];
    }
    
    [[DJIMissionManager sharedInstance] setDelegate:self];
    
    DJIFlightController *flightController = [self fetchFlightController];
    if (flightController) {
        [flightController setDelegate:self];
        [flightController setYawControlMode:DJIVirtualStickYawControlModeAngle];
        [flightController setRollPitchCoordinateSystem:DJIVirtualStickFlightCoordinateSystemGround];
        [flightController enableVirtualStickControlModeWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Enable VirtualStickControlMode Failed");
            }
        }];
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error {
    
    NSString* message = @"Register App Successed!";
    if (error) {
        message = @"Register App Failed! Please enter your App Key and check the network.";
    }else{
        NSLog(@"registerAppSuccess");

#if ENTER_DEBUG_MODE
        [DJISDKManager enterDebugModeWithDebugId:@"10.81.0.29"];
#else
        [DJISDKManager startConnectionToProduct];
#endif

        [[VideoPreviewer instance] start];
    }
    
    [self showAlertViewWithTitle:@"Register App" withMessage:message];

}

#pragma mark - DJICameraDelegate Method
-(void)camera:(DJICamera *)camera didReceiveVideoData:(uint8_t *)videoBuffer length:(size_t)size
{
    uint8_t* pBuffer = (uint8_t*)malloc(size);
    memcpy(pBuffer, videoBuffer, size);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:(int)size];

}

- (void)camera:(DJICamera *)camera didUpdateSystemState:(DJICameraSystemState *)systemState
{
    
}

#pragma mark - DJIPlaybackDelegate
- (void)playbackManager:(DJIPlaybackManager *)playbackManager didUpdatePlaybackState:(DJICameraPlaybackState *)playbackState
{
    self.selectedPhotoNumber = playbackState.numberOfSelectedFiles;
}

#pragma mark - DJIMissionManagerDelegate Methods
- (void)missionManager:(DJIMissionManager *)manager didFinishMissionExecution:(NSError *)error
{
    if (error) {
        [self showAlertViewWithTitle:@"Mission Execution Failed" withMessage:[NSString stringWithFormat:@"%@", error.description]];
    }
    else {
        
        if (self.isMissionStarted) {
            [self showAlertViewWithTitle:@"Intelligent Navigation" withMessage:@"Mission Finished"];
            self.isMissionStarted = NO;
        }
    }

}

- (void)missionManager:(DJIMissionManager *)manager missionProgressStatus:(DJIMissionProgressStatus *)missionProgress
{
    
}

#pragma mark - DJIFlightControllerDelegate Method
- (void)flightController:(DJIFlightController *)fc didUpdateSystemState:(DJIFlightControllerCurrentState *)state
{
    self.aircraftLocation = CLLocationCoordinate2DMake(state.aircraftLocation.latitude, state.aircraftLocation.longitude);
    self.gpsSignalStatus = state.gpsSignalStatus;
    self.aircraftAltitude = state.altitude;
    self.aircraftYaw = state.attitude.yaw;

}

#pragma mark Custom Methods

- (void)cleanVideoPreview {
    [[VideoPreviewer instance] unSetView];
    
    if (self.fpvPreviewView != nil) {
        [self.fpvPreviewView removeFromSuperview];
        self.fpvPreviewView = nil;
    }
}

- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

- (DJICamera*) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }
    return nil;
}

- (DJIGimbal*) fetchGimbal {
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).gimbal;
    }
    return nil;
}

- (void) registerApp {
    NSString *appKey = @"Please enter your App Key here";
    [DJISDKManager registerApp:appKey withDelegate:self];
}

- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Rotate Drone With Joystick Methods
- (void)rotateDroneWithJoystick {

    weakSelf(target);

    DJICamera *camera = [target fetchCamera];
    [camera setCameraMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        if (!error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [target executeVirtualStickControl];
            });
        }
    }];
    
}

- (void)executeVirtualStickControl
{
    DJICamera *camera = [self fetchCamera];
    
    for(int i = 0;i < PHOTO_NUMBER; i++){
        
        float yawAngle = ROTATE_ANGLE*i;
        
        if (yawAngle > DJIVirtualStickYawControlMaxAngle) { //Filter the angle between -180 ~ 0, 0 ~ 180
            yawAngle = yawAngle - 360;
        }
        
        NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(rotateDrone:) userInfo:@{@"YawAngle":@(yawAngle)} repeats:YES];
        [timer fire];
        
        [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        
        [timer invalidate];
        timer = nil;
        
        [camera startShootPhoto:DJICameraShootPhotoModeSingle withCompletion:nil];
        sleep(2);
    }
    
      dispatch_async(dispatch_get_main_queue(), ^{
          [self showAlertViewWithTitle:@"Capture Photos" withMessage:@"Capture finished"];
      });

}

- (void)rotateDrone:(NSTimer *)timer
{
    NSDictionary *dict = [timer userInfo];
    float yawAngle = [[dict objectForKey:@"YawAngle"] floatValue];
    
    DJIFlightController *flightController = [self fetchFlightController];

    DJIVirtualStickFlightControlData vsFlightCtrlData;
    vsFlightCtrlData.pitch = 0;
    vsFlightCtrlData.roll = 0;
    vsFlightCtrlData.verticalThrottle = 0;
    vsFlightCtrlData.yaw = yawAngle;
    
    [flightController sendVirtualStickFlightControlData:vsFlightCtrlData withCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Send FlightControl Data Failed %@", error.description);
        }
    }];

}

#pragma mark - Rotate Gimbal Methods
- (void)rotateGimbal {
    
    DJICamera *camera = [self fetchCamera];
    weakSelf(target);
    [camera setCameraMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        if (!error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [target executeRotateGimbal];
            });
        }
    }];

}

- (void)executeRotateGimbal
{
    
    DJIGimbal *gimbal = [self fetchGimbal];
    DJICamera *camera = [self fetchCamera];
    
    //Reset Gimbal at the beginning
    [gimbal resetGimbalWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"ResetGimbal Failed: %@", [NSString stringWithFormat:@"%@", error.description]);
        }
    }];
    sleep(3);
    
    //rotate the gimbal clockwise
    float yawAngle = 0;
    
    DJIGimbalAngleRotation pitchRotation = {NO, 0, DJIGimbalRotateDirectionClockwise};
    DJIGimbalAngleRotation rollRotation = {NO, 0, DJIGimbalRotateDirectionClockwise};
    DJIGimbalAngleRotation yawRotation = {YES, yawAngle, DJIGimbalRotateDirectionClockwise};
    
    for(int i = 0; i < PHOTO_NUMBER; i++){
        
        [camera startShootPhoto:DJICameraShootPhotoModeSingle withCompletion:nil];
        sleep(2);
        
        yawAngle += ROTATE_ANGLE;
        yawRotation.angle = yawAngle;
        [gimbal rotateGimbalWithAngleMode:DJIGimbalAngleModeAbsoluteAngle pitch:pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Rotate Gimbal Failed: %@", [NSString stringWithFormat:@"%@", error.description]);
            }
        }];
        sleep(2);
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertViewWithTitle:@"Capture Photos" withMessage:@"Capture finished"];
    });
    
}

#pragma mark - Rotate Drone With Waypoint Mission Methods

- (void)rotateDroneWithWaypointMission {
    if (CLLocationCoordinate2DIsValid(self.aircraftLocation) && self.gpsSignalStatus != DJIGPSSignalStatusLevel0 && self.gpsSignalStatus != DJIGPSSignalStatusLevel1) {
        [self prepareWaypointMission];
    }
    else {
        [self showAlertViewWithTitle:@"GPS signal weak" withMessage:@"Rotate drone failed"];
    }
}

- (DJIMission*) initializeMission {
    
    DJIWaypointMission *mission = [[DJIWaypointMission alloc] init];
    mission.maxFlightSpeed = 15.0;
    mission.autoFlightSpeed = 4.0;
    
    DJIWaypoint *wp1 = [[DJIWaypoint alloc] initWithCoordinate:self.aircraftLocation];
    wp1.altitude = self.aircraftAltitude;
    
    for (int i = 0; i < PHOTO_NUMBER ; i++) {
        
        double rotateAngle = ROTATE_ANGLE*i;
        
        if (rotateAngle > 180) { //Filter the angle between -180 ~ 0, 0 ~ 180
            rotateAngle = rotateAngle - 360;
        }

        DJIWaypointAction *action1 = [[DJIWaypointAction alloc] initWithActionType:DJIWaypointActionTypeShootPhoto param:0];
        DJIWaypointAction *action2 = [[DJIWaypointAction alloc] initWithActionType:DJIWaypointActionTypeRotateAircraft param:rotateAngle];
        [wp1 addAction:action1];
        [wp1 addAction:action2];
    }
    
    DJIWaypoint *wp2 = [[DJIWaypoint alloc] initWithCoordinate:self.aircraftLocation];
    wp2.altitude = self.aircraftAltitude + 1;

    [mission addWaypoint:wp1];
    [mission addWaypoint:wp2];
    [mission setFinishedAction:DJIWaypointMissionFinishedNoAction]; //Change the default action of Go Home to None
    
    return mission;
}

- (void)prepareWaypointMission {
   
    self.mission = [self initializeMission];
    if (self.mission == nil) return; //Initialization failed
    
    weakSelf(target);
    [[DJIMissionManager sharedInstance] prepareMission:self.mission withProgress:^(float progress) {
        
        NSString *message = [NSString stringWithFormat:@"Mission Upload %.2f%%" ,progress*100];
        
        if (target.prepareMissionProgressAlert == nil) {
            target.prepareMissionProgressAlert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [target.prepareMissionProgressAlert show];
        }
        else {
            [target.prepareMissionProgressAlert setMessage:message];
        }
        
        if (progress*100 == 100) {
            [target.prepareMissionProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            target.prepareMissionProgressAlert = nil;
        }
        
    } withCompletion:^(NSError * _Nullable error) {
        
        if (target.prepareMissionProgressAlert) {
            [target.prepareMissionProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            target.prepareMissionProgressAlert = nil;
        }
        
        if (error) {
            [target showAlertViewWithTitle:@"Prepare Mission Failed" withMessage:[NSString stringWithFormat:@"%@", error.description]];
        }else
        {
            [target showAlertViewWithTitle:@"Prepare Mission Finished" withMessage:nil];
        }
        
        [target startWaypointMission];
    }];
}

- (void)startWaypointMission {

    weakSelf(target);
    [[DJIMissionManager sharedInstance] startMissionExecutionWithCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        target.isMissionStarted = YES;
        if (error) {
            NSLog(@"Start Mission Failed: %@", error.description);
        }
    }];
   
}

#pragma mark - Select the lastest photos for Panorama

-(void)selectPhotos {
    
    weakSelf(target);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        weakReturn(target);
        DJICamera *camera = [target fetchCamera];
        [camera.playbackManager enterMultiplePreviewMode];
        sleep(1);
        [camera.playbackManager enterMultipleEditMode];
        sleep(1);
        
        while (self.selectedPhotoNumber != PHOTO_NUMBER) {
            [camera.playbackManager selectAllFilesInPage];
            sleep(1);
            
            if(self.selectedPhotoNumber > PHOTO_NUMBER){
                for(int unselectFileIndex = 0; self.selectedPhotoNumber != PHOTO_NUMBER; unselectFileIndex++){
                    [camera.playbackManager toggleFileSelectionAtIndex:unselectFileIndex];
                    sleep(1);
                }
                break;
            }
            else if(self.selectedPhotoNumber < PHOTO_NUMBER) {
                [camera.playbackManager goToPreviousMultiplePreviewPage];
                sleep(1);
            }
        }
        [target downloadPhotos];
    });
}

#pragma mark - Download the selected photos
-(void)downloadPhotos {
    __block int finishedFileCount = 0;
    __block NSMutableData* downloadedFileData;
    __block long totalFileSize;
    __block NSString* targetFileName;
    
    self.imageArray=[NSMutableArray new];
    
    DJICamera *camera = [self fetchCamera];
    if (camera == nil) return;

    weakSelf(target);
    [camera.playbackManager downloadSelectedFilesWithPreparation:^(NSString * _Nullable fileName, DJIDownloadFileType fileType, NSUInteger fileSize, BOOL * _Nonnull skip) {

        totalFileSize=(long)fileSize;
        downloadedFileData=[NSMutableData new];
        targetFileName=fileName;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakReturn(target);
            [target showDownloadProgressAlert];
            [target.downloadProgressAlert setTitle:[NSString stringWithFormat:@"Download (%d/%d)", finishedFileCount + 1, PHOTO_NUMBER]];
            [target.downloadProgressAlert setMessage:[NSString stringWithFormat:@"FileName:%@ FileSize:%0.1fKB Downloaded:0.0KB", fileName, fileSize / 1024.0]];
        });
            
    } process:^(NSData * _Nullable data, NSError * _Nullable error) {
        
        weakReturn(target);
        [downloadedFileData appendData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [target.downloadProgressAlert setMessage:[NSString stringWithFormat:@"FileName:%@ FileSize:%0.1fKB Downloaded:%0.1fKB", targetFileName, totalFileSize / 1024.0, downloadedFileData.length / 1024.0]];
        });
        
    } fileCompletion:^{
        weakReturn(target);
        finishedFileCount++;

        UIImage *downloadPhoto=[UIImage imageWithData:downloadedFileData];
        [target.imageArray addObject:downloadPhoto];
        
    } overallCompletion:^(NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [target.downloadProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            target.downloadProgressAlert = nil;
            
            if (error) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Download failed" message:[NSString stringWithFormat:@"%@", error.description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }else
            {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Download (%d/%d)", finishedFileCount, PHOTO_NUMBER] message:@"download finished" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
            
            DJICamera *camera = [target fetchCamera];
            [camera setCameraMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
                if (error) {
                    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Set CameraMode to ShootPhoto Failed" message:[NSString stringWithFormat:@"%@", error.description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];

                }
            }];

        });
        
    }];
}

-(void) showDownloadProgressAlert {
    if (self.downloadProgressAlert == nil) {
        self.downloadProgressAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [self.downloadProgressAlert show];
    }
}

#pragma mark - IBAction Methods

-(IBAction)onCaptureButtonClicked:(id)sender {

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select Mode" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rotate Aircraft", @"Rotate Gimbal", @"WaypointMission", nil];
    alertView.tag = kCaptureModeAlertTag;
    [alertView show];
}

-(IBAction)onDownloadButtonClicked:(id)sender {

    weakSelf(target);
    DJICamera *camera = [self fetchCamera];
    [camera setCameraMode:DJICameraModePlayback withCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        
        if (error) {
            NSLog(@"Enter playback mode failed: %@", error.description);
        }else {
            [target selectPhotos];
        }
    }];
}

#pragma mark UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kCaptureModeAlertTag) {
        if(buttonIndex == 1){
            [self rotateDroneWithJoystick];
        }else if(buttonIndex == 2){
            [self rotateGimbal];
        }else if (buttonIndex == 3){
            [self rotateDroneWithWaypointMission];
        }
    }
}

@end