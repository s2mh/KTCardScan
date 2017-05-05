//
//  KTCardScanViewController.m
//  CardScan
//
//  Created by QQQ on 2017/4/28.
//  Copyright © 2017年 MY. All rights reserved.
//

#import "KTCardScanViewController.h"
#import <GPUImage.h>
#import <TesseractOCR/TesseractOCR.h>
#import "KTCardEdgeDetector.h"
#import "KTCardReader.h"
#import "KTScanOverlayView.h"

//#define DEBUGMODE

@interface KTCardScanViewController () <GPUImageVideoCameraDelegate>

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) GPUImageStillCamera *stillCamera;
@property (nonatomic, strong) GPUImageHoughTransformLineDetector *detector;
@property (nonatomic, strong) GPUImageCropFilter *cropper;
@property (nonatomic, strong) GPUImageTransformFilter *rotator;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) KTCardReader *cardReader;
@property (nonatomic, strong) KTScanOverlayView *overlayView;
@property (nonatomic, strong) KTCardEdgeDetector *cardEdgeDetector;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) UIImage *cardImage;

@property (assign ,nonatomic) CGRect scanRect;
#ifdef DEBUGMODE
@property (nonatomic, strong) GPUImageLineGenerator *generator;
#endif
@end
@implementation KTCardScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self tlbr];
    
    self.queue = [[NSOperationQueue alloc] init];
    self.queue.maxConcurrentOperationCount = 1;
    
    self.semaphore = dispatch_semaphore_create(1);
    
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080
                                                           cameraPosition:AVCaptureDevicePositionBack];

    [self.stillCamera removeAudioInputsAndOutputs];
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.stillCamera addTarget:self.filterView];
    [self.view addSubview:self.filterView];
    
    self.overlayView = [[KTScanOverlayView alloc] initWithFrame:self.view.bounds scanRect:self.scanRect];
    [self.view addSubview:self.overlayView];
    
    GPUImageCropFilter *cropper = [[GPUImageCropFilter alloc] init];
    CGFloat captureViewWidth = 1080.0;
    CGFloat captureViewHeight = 1920.0;
    CGFloat cardAspectRatio = 54.0 / 85.6;
    CGFloat verticalRatio = 368.0 / 568.0;
    CGFloat cardHeight = captureViewHeight * verticalRatio;
    CGFloat cardWidth = cardHeight * cardAspectRatio;
    CGFloat horionalRatio = cardWidth / captureViewWidth;

    cropper.cropRegion = CGRectMake((1.0 - horionalRatio) / 2.0,
                                    (1.0 - verticalRatio) / 2.0,
                                    horionalRatio,
                                    verticalRatio);
    self.cropper = cropper;
    
    GPUImageTransformFilter *rotator = [[GPUImageTransformFilter alloc] init];
    rotator.affineTransform = CGAffineTransformMakeRotation(-M_PI_2);
    rotator.ignoreAspectRatio = YES;
    [rotator forceProcessingAtSize:CGSizeMake(ceil(cardHeight), ceil(cardWidth))];
    self.rotator = rotator;
    
    [self.stillCamera addTarget:self.cropper];
    [self.cropper addTarget:self.rotator];
    
    self.cardEdgeDetector = [[KTCardEdgeDetector alloc] init];
    self.cardEdgeDetector.threshold = 0.9;

    self.cardReader = [[KTCardReader alloc] init];
    
    __weak typeof(self) weakSelf = self;
    self.detector = [[GPUImageHoughTransformLineDetector alloc] init];
    self.detector.lineDetectionThreshold = 0.4;
    self.detector.linesDetectedBlock = ^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime) {
#ifndef DEBUGMODE
        KTCardEdgeDetectorResult result = [weakSelf.cardEdgeDetector detectWithLineArray:lineArray
                                                                           linesDetected:linesDetected];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.overlayView setTopEdgeVisible:(result & KTCardEdgeDetectorDidFindTopEdge)];
            [weakSelf.overlayView setLeftEdgeVisible:(result & KTCardEdgeDetectorDidFindLeftEdge)];
            [weakSelf.overlayView setBottomEdgeVisible:(result & KTCardEdgeDetectorDidFindBottomEdge)];
            [weakSelf.overlayView setRightEdgeVisible:(result & KTCardEdgeDetectorDidFindRightEdge)];
        });

        if (result == KTCardEdgeDetectorDidFindAllEdges) {
            [weakSelf.cardReader readCardIdFromImage:weakSelf.cardImage
                                          completion:^(NSString *cardId, UIImage *image) {
                                              if (cardId && weakSelf.completion) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                      weakSelf.completion(cardId, image);
                                                      [weakSelf.navigationController popViewControllerAnimated:YES];
                                                  });
                                              }
                                          }];
        }
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.generator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
        });
#endif
        dispatch_semaphore_signal(weakSelf.semaphore);
    };
    
#ifdef DEBUGMODE
    self.generator = [[GPUImageLineGenerator alloc] init];
    [self.stillCamera addTarget:self.detector];
    [self.detector addTarget:self.generator];
    
    GPUImageView *v = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    v.alpha = .5;
    [self.filterView addSubview:v];
    [self.generator addTarget:v];
#endif
}

- (void)focus {
    NSError *error;
    AVCaptureDevice *device = self.stillCamera.inputCamera;
    if (!device.isAdjustingFocus && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        if ([device lockForConfiguration:&error]) {
            CGPoint cameraPoint = [self.stillCamera.videoCaptureConnection.videoPreviewLayer captureDevicePointOfInterestForPoint:self.view.center];
            [device setFocusPointOfInterest:cameraPoint];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)capture {
#ifndef DEBUGMODE
    [self.queue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        [self.rotator useNextFrameForImageCapture];
        UIImage *processedImage = [self.rotator imageFromCurrentFramebuffer];
        if (processedImage) {
            GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:processedImage];
            [stillImageSource addTarget:self.detector];
            [stillImageSource processImage];
            
            self.cardImage = processedImage;
        } else {
            dispatch_semaphore_signal(self.semaphore);
        }
    }]];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.stillCamera.inputCamera addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:NULL];
    [self.stillCamera startCameraCapture];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(focus) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.stillCamera.inputCamera removeObserver:self forKeyPath:@"adjustingFocus"];
    [self.stillCamera stopCameraCapture];
    [self.timer invalidate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"]){
        if (!self.stillCamera.inputCamera.isAdjustingFocus) {
            [self capture];
        }
    }
}

- (void)tlbr {
    CGRect viewBounds = self.view.bounds;
    CGFloat width = viewBounds.size.width;
    CGFloat height = viewBounds.size.height;
    
    CGFloat topInset = 0.0;
    CGFloat leftInset = 0.0;
    CGFloat bottomInset = 0.0;
    CGFloat rightInset = 0.0;
    
    if ((width == 375) && (height == 667)) {//iP6
        topInset = 100 * 1.174;
        leftInset = 45 * 1.174;
    } else if ((width == 320) && (height == 568)) {//iP5
        topInset = 100; // 368
        leftInset = 45; // 230
    } else if ((width == 320) && (height == 480)) {//iP4
        topInset = 100 - 44;
        leftInset = 45;
    } else if (height == 736) {//6plus
        topInset = 100 * 1.295;
        leftInset = 45 * 1.295;
    }
    bottomInset = topInset;
    rightInset = leftInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);
    self.scanRect = UIEdgeInsetsInsetRect(viewBounds, insets);
}

@end
