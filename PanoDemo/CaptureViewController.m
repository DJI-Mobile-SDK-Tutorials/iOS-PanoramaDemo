//
//  CaptureViewController.m
//  PanoDemo
//
//  Created by lizefei on 15/7/29.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import "CaptureViewController.h"
#import <DJISDK/DJISDK.h>
#import "VideoPreviewer.h"

#define PHOTO_NUMBER 8
#define ROTATE_ANGLE 45
#define kCaptureModeAlertTag 100

#define GIMBAL_ROTATE_BUG 


@interface CaptureViewController ()<DJIAppManagerDelegate, DJICameraDelegate, DJIDroneDelegate, DJIMainControllerDelegate, DJINavigationDelegate>{
    __block NSMutableData* _downloadedFileData;
    __block int _selectedPhotoNumber;
    __block long _totalFileSize;
    __block NSString* _targetFileName;
}
@property (strong, nonatomic) DJIDrone* drone;
@property (strong, nonatomic) DJIInspireCamera* camera;
@property (weak, nonatomic) NSObject<DJINavigation>* navigation;
@property (strong, nonatomic) UIAlertView* downloadProgressAlert;
@property (strong, nonatomic) UIAlertView* uploadMissionProgressAlert;
@property (strong, nonatomic) NSMutableArray* imageArray;
@property (nonatomic) bool isMissionStarted;
@property (atomic) CLLocationCoordinate2D droneLocation;
@property (atomic) double droneAltitude;
@property (atomic) DJIGpsSignalLevel gpsSignalLevel;
@property (atomic) double droneYaw;
@property (weak, nonatomic) NSObject<DJIWaypointMission>* waypointMission;
@property (strong,nonatomic) DJIInspireGimbal *gimbal;
@end

@implementation CaptureViewController

#pragma mark Inherited Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isMissionStarted = NO;
    self.droneLocation = kCLLocationCoordinate2DInvalid;
    
    self.drone = [[DJIDrone alloc] initWithType:DJIDrone_Inspire];
    self.drone.delegate = self;
    
    self.camera = (DJIInspireCamera *)_drone.camera;
    self.camera.delegate = self;
    
    self.navigation = self.drone.mainController.navigationManager;
    self.navigation.delegate = self;
    
    self.gimbal=(DJIInspireGimbal*)_drone.gimbal;

    self.waypointMission = self.navigation.waypointMission;
    
    self.drone.mainController.mcDelegate = self;
    
    [[VideoPreviewer instance] setView:self.fpvPreviewView];
    
    [self registerApp];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

//pass the downloaded photos to StitchingViewController
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"Stitching"]) {
        [segue.destinationViewController setValue:_imageArray forKey:@"imageArray"];
    }
}

#pragma mark Custom Methods
- (void) registerApp {
    NSString *appKey = @"Enter Your App Key Here";
    [DJIAppManager registerApp:appKey withDelegate:self];
}

- (void)rotateDroneWithJoystick {
    
    if (self.droneAltitude < 5.0f) {
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Start Capture Failed" message:@"Aircraft is not in the air(>= 5m), please take off the aircraft" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingUp) userInfo:nil repeats:YES];
    [timer fire];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        [timer invalidate];
        
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = ROTATE_ANGLE;
        [_camera startTakePhoto:CameraSingleCapture withResult:nil];
        sleep(2);
        
        for(int i = 0;i < PHOTO_NUMBER - 1; i++){
            [self.navigation.flightControl sendFlightControlData:ctrlData withResult:nil];
            sleep(2);
            
            [self.camera startTakePhoto:CameraSingleCapture withResult:nil];
            sleep(2);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Capture Photos" message:@"Capture finished" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        });
    });
    
}

- (void) warmingUp {
    DJIFlightControlData noActionData;
    noActionData.mPitch = 0;
    noActionData.mRoll = 0;
    noActionData.mThrottle = 0;
    noActionData.mYaw = 0;
    [_navigation.flightControl sendFlightControlData:noActionData withResult:nil];
}

- (void)rotateDroneWithGoundStation {
    if (CLLocationCoordinate2DIsValid(self.droneLocation) && self.gpsSignalLevel != GpsSignalLevel0 && self.gpsSignalLevel != GpsSignalLevel1) {
        [self createWaypointMission];
        if (self.waypointMission.isValid ) {
            [self uploadWaypointMission];
        }
        else {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Upload Mission" message:@"Waypoint mission invalid!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }
    else {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"GPS signal weak" message:@"Rotate drone failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)createWaypointMission {
    [self.waypointMission removeAllWaypoints];
    self.waypointMission.finishedAction = DJIWaypointMissionFinishedNoAction;
    self.waypointMission.headingMode = DJIWaypointMissionHeadingAuto;
    self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathNormal;
    
    DJIWaypoint *wp1 = [[DJIWaypoint alloc] initWithCoordinate:self.droneLocation];
    wp1.altitude = self.droneAltitude;
    double rotateAngle = self.droneYaw;
    for (int i = 0; i < PHOTO_NUMBER ; i++) {
        rotateAngle += ROTATE_ANGLE;
        DJIWaypointAction *action1 = [[DJIWaypointAction alloc] initWithActionType:DJIWaypointActionStartTakePhoto param:0];
        DJIWaypointAction *action2 = [[DJIWaypointAction alloc] initWithActionType:DJIWaypointActionRotateAircraft param:rotateAngle];
        [wp1 addAction:action1];
        [wp1 addAction:action2];
    }
    
    DJIWaypoint *wp2 = [[DJIWaypoint alloc] initWithCoordinate:self.droneLocation];
    wp2.altitude = self.droneAltitude + 1;
    
    [self.waypointMission addWaypoint:wp1];
    [self.waypointMission addWaypoint:wp2];
}

- (void)uploadWaypointMission {
    __weak typeof(self) weakSelf = self;
    //setup progress handler
    [self.waypointMission setUploadProgressHandler:^(uint8_t progress) {
        NSString *message = [NSString stringWithFormat:@"Mission Upload %d%%" ,progress];
        if (weakSelf.uploadMissionProgressAlert == nil) {
            weakSelf.uploadMissionProgressAlert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [weakSelf.uploadMissionProgressAlert show];
        }
        else {
            [weakSelf.uploadMissionProgressAlert setMessage:message];
        }
        
        if (progress == 100) {
            [weakSelf.uploadMissionProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            weakSelf.uploadMissionProgressAlert = nil;
        }
    }];
    //upload mission
    [self.waypointMission uploadMissionWithResult:^(DJIError *error) {
        if (weakSelf.uploadMissionProgressAlert) {
            [weakSelf.uploadMissionProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
            weakSelf.uploadMissionProgressAlert = nil;
        }
        [weakSelf.waypointMission setUploadProgressHandler:nil];
        [self startWaypointMission];
    }];
}

- (void)startWaypointMission {
    [self.waypointMission startMissionWithResult:^(DJIError *error) {
        self.isMissionStarted = YES;
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Start Mission" message:[NSString stringWithFormat:@"%@", error.errorDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }];
}

//select the last PHOTO_NUMBER photos
-(void)selectPhotos {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.camera enterMultiplePreviewMode];
        sleep(1);
        [self.camera enterMultipleEditMode];
        sleep(1);
        
        while (_selectedPhotoNumber != PHOTO_NUMBER) {
            [self.camera selectAllFilesInPage];
            sleep(1);
            
            if(_selectedPhotoNumber > PHOTO_NUMBER){
                for(int unselectFileIndex = 0; _selectedPhotoNumber != PHOTO_NUMBER; unselectFileIndex++){
                    [self.camera unselectFileAtIndex:unselectFileIndex];
                    sleep(1);
                }
                break;
            }
            else if(_selectedPhotoNumber < PHOTO_NUMBER) {
                [self.camera multiplePreviewPreviousPage];
                sleep(1);
            }
            
        }
        [self downloadPhotos];
    });
}


//download the selected photos
-(void)downloadPhotos {
    __block int finishedFileCount=0;
    __weak typeof(self) weakSelf = self;
    __block NSTimer *timer;
    _imageArray=[NSMutableArray new];
    
    [_camera downloadAllSelectedFilesWithPreparingBlock:^(NSString* fileName, DJIDownloadFileType fileType, NSUInteger fileSize, BOOL* skip) {
        _totalFileSize=(long)fileSize;
        _downloadedFileData=[NSMutableData new];
        _targetFileName=fileName;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showDownloadProgressAlert];
            [weakSelf.downloadProgressAlert setTitle:[NSString stringWithFormat:@"Download (%d/%d)", finishedFileCount + 1, PHOTO_NUMBER]];
            [weakSelf.downloadProgressAlert setMessage:[NSString stringWithFormat:@"FileName:%@ FileSize:%0.1fKB Downloaded:0.0KB", fileName, fileSize / 1024.0]];
            timer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDownloadProgress) userInfo:nil repeats:YES];
            [timer fire];
        });
    } dataBlock:^(NSData *data, NSError *error) {
        [_downloadedFileData appendData:data];
    } completionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [timer invalidate];
            finishedFileCount++;
            if(finishedFileCount>=PHOTO_NUMBER) {
                [self.downloadProgressAlert dismissWithClickedButtonIndex:0 animated:YES];
                self.downloadProgressAlert = nil;
                [_camera setCameraWorkMode:CameraWorkModeCapture withResult:nil];
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Download (%d/%d)", finishedFileCount, PHOTO_NUMBER] message:@"download finished" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
            UIImage *downloadPhoto=[UIImage imageWithData:_downloadedFileData];
            [_imageArray addObject:downloadPhoto];
        });
    }];
}



-(void)updateDownloadProgress{
    [self.downloadProgressAlert setMessage:[NSString stringWithFormat:@"FileName:%@ FileSize:%0.1fKB Downloaded:%0.1fKB", _targetFileName, _totalFileSize / 1024.0, _downloadedFileData.length / 1024.0]];
}

-(void) showDownloadProgressAlert {
    if (self.downloadProgressAlert == nil) {
        self.downloadProgressAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [self.downloadProgressAlert show];
    }
}

#pragma mark - IBAction Methods
-(IBAction)onEnterNavigationClicked:(id)sender {
    [self.navigation enterNavigationModeWithResult:^(DJIError *error) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Enter Navigation" message:[NSString stringWithFormat:@"Enter Navigation Mode:%@", error.errorDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }];
}

-(IBAction)onCaptureButtonClicked:(id)sender {

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select Mode" message:@"" delegate:self cancelButtonTitle:@"GroundStation" otherButtonTitles:@"Joystick", nil];
    alertView.tag = kCaptureModeAlertTag;
    [alertView show];
    
}

-(IBAction)onDownloadButtonClicked:(id)sender {
    __weak typeof(self) weakSelf = self;
    [_camera setCameraWorkMode:CameraWorkModePlayback withResult:^(DJIError *error) {
        if (error.errorCode == ERR_Successed) {
            [weakSelf selectPhotos];
        }else {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Camera WorkMode" message:@"Enter playback mode failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

#pragma mark UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kCaptureModeAlertTag) {
        if (buttonIndex == 0){
            [self rotateDroneWithGoundStation];
        }else if(buttonIndex == 1){
            [self rotateDroneWithJoystick];
        }
    }
}

#pragma mark DJIAppManagerDelegate Method
- (void)appManagerDidRegisterWithError:(int)error {
    NSString* message = @"Register App Successed!";
    if (error != RegisterSuccess) {
        message = @"Register App Failed!";
    }else{
        NSLog(@"registerAppSuccess");
        [_drone connectToDrone];
        [_camera startCameraSystemStateUpdates];
        [self.drone.mainController startUpdateMCSystemState];
        [[VideoPreviewer instance] start];
    }
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Register App" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - DJICameraDelegate Method
-(void) camera:(DJICamera*)camera didReceivedVideoData:(uint8_t*)videoBuffer length:(int)length {
    uint8_t* pBuffer = (uint8_t*)malloc(length);
    memcpy(pBuffer, videoBuffer, length);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:length];
}

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{

}

-(void) camera:(DJICamera *)camera didUpdatePlaybackState:(DJICameraPlaybackState*)playbackState{
    _selectedPhotoNumber=playbackState.numbersOfSelected;
}

#pragma mark - DJIDroneDelegate Method
-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status {
    if (status == ConnectionSuccessed) {
        NSLog(@"Connection Successed");
    } else if(status == ConnectionStartConnect) {
        NSLog(@"Start Reconnect");
    } else if(status == ConnectionBroken) {
        NSLog(@"Connection Broken");
    } else if (status == ConnectionFailed) {
        NSLog(@"Connection Failed");
    }
}

#pragma mark - DJIMainControllerDelegate Method
-(void) mainController:(DJIMainController*)mc didUpdateSystemState:(DJIMCSystemState*)state {
    self.droneLocation = CLLocationCoordinate2DMake(state.droneLocation.latitude, state.droneLocation.longitude);
    self.gpsSignalLevel = state.gpsSignalLevel;
    self.droneAltitude = state.altitude;
    self.droneYaw = state.attitude.yaw;
}

#pragma mark - DJINavigationDelegate Method
-(void) onNavigationMissionStatusChanged:(DJINavigationMissionStatus*)missionStatus {
    if (self.isMissionStarted && missionStatus.missionType == DJINavigationMissionNone) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Ground Station" message:@"mission finished" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        self.isMissionStarted = NO;
    }
}

@end
