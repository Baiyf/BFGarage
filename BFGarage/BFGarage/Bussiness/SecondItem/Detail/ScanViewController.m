//
//  ScanViewController.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ScanViewController ()<UIImagePickerControllerDelegate,AVCaptureMetadataOutputObjectsDelegate>{
    UIImageView *readLineView;//扫描线图片
    UIImageView *coverImage;//扫描框图片
    BOOL is_Anmotion;
    
}
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@end

@implementation ScanViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [self stopScan];
    [super viewDidDisappear:animated];
}

- (void)initCapture
{
    AVCaptureDevice* inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //captureOutput.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    [captureOutput setRectOfInterest:CGRectMake(80,150,100,100)];
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    self.captureSession = captureSession;
    if ([self.captureSession canAddInput:captureInput])
    {
        [self.captureSession addInput:captureInput];
    }
    
    if ([self.captureSession canAddOutput:captureOutput])
    {
        [self.captureSession addOutput:captureOutput];
    }
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;//设置扫描的画质
    
    self.captureVideoPreviewLayer =[AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.captureVideoPreviewLayer.frame = self.view.layer.bounds;
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer: self.captureVideoPreviewLayer atIndex:0];
    
    NSLog(@"222");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    coverImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-88)];
    coverImage.image = [UIImage imageNamed:(@"Sony_TVLogin_bound.png")];
    [self.view addSubview:coverImage];
    [self initCapture];
    [self startScan];
}

//循环♻️的绿色扫码条
-(void)loopDrawLine
{
    CGRect  rect = CGRectMake(68/2+30,140, 502/2, 8/2);//扫描开始位置
    if (readLineView) {
        [readLineView removeFromSuperview];
        readLineView = nil;
    }
    readLineView = [[UIImageView alloc] initWithFrame:rect];
    readLineView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:(@"Sony_TV_Login_Line.png")]];
    [UIView animateWithDuration:3.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         //修改fream的代码写在这里
                         readLineView.frame =CGRectMake(68/2+30,380, 502/2, 8/2);//扫描结束位置
                         [readLineView setAnimationRepeatCount:0];
                     }
                     completion:^(BOOL finished){
                         if (!is_Anmotion) {
                             [self loopDrawLine];
                         }
                     }];
    
    [self.view addSubview:readLineView];
}

//开始扫描
-(void)startScan{
    coverImage.image = [UIImage imageNamed:(@"Sony_TVLogin_bound.png")];
    [self.captureSession startRunning];
    is_Anmotion = NO;
    [self loopDrawLine];
    NSLog(@"333");
}

//扫码条停止循环
-(void)stopScan{
    is_Anmotion = YES;
    //self.isScanning = NO;
    [self.captureSession stopRunning];
    [readLineView removeFromSuperview];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    if ([metadataObjects count] >0){
        //停止扫描
        [self.captureSession stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
