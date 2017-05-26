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
    NSError *error = nil;
    AVCaptureDevice* inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [captureOutput setRectOfInterest:CGRectMake(0.2,0.2,0.5,0.6)];//扫码范围，右上角为原点
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    self.captureSession = captureSession;
    if ([self.captureSession canAddInput:captureInput]) {
        [self.captureSession addInput:captureInput];
    }
    if([self.captureSession canAddOutput:captureOutput]){
        [self.captureSession addOutput:captureOutput];
    }
    captureOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;//设置扫描的画质
    
    self.captureVideoPreviewLayer =[AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.captureVideoPreviewLayer.frame = self.view.layer.bounds;
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.captureVideoPreviewLayer];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCapture];
    [self startScan];
    
    self.title = @"Scanning";
    coverImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-44)];
    coverImage.image = [UIImage imageNamed:@"Sony_TVLogin_bound.png"];
       
    UILabel *alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, CGRectGetHeight(coverImage.frame)-160, 300, 40)];
    alertLabel.text = @"Please Scanning QR code";
    alertLabel.textColor = [UIColor whiteColor];
    [coverImage addSubview:alertLabel];
    [self.view addSubview:coverImage];
}

//循环♻️的绿色扫码条
-(void)loopDrawLine
{
    CGRect  rect = CGRectMake(75,180,502/2, 8/2);//扫描开始位置
    if (readLineView) {
        [readLineView removeFromSuperview];
        readLineView = nil;
    }
    readLineView = [[UIImageView alloc] initWithFrame:rect];
    readLineView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:(@"Sony_TV_Login_Line.png")]];
    [UIView animateWithDuration:3.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         //修改fream的代码写在这里
                         readLineView.frame =CGRectMake(75,360, 502/2, 8/2);//扫描结束位置
                         [readLineView setAnimationRepeatCount:0];
                     }
                     completion:^(BOOL finished){
                        [self loopDrawLine];
                     }];
    [self.view addSubview:readLineView];
}

//开始扫描
-(void)startScan{
    [self.captureSession startRunning];
    [self loopDrawLine];
}

//扫码条停止循环
-(void)stopScan{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [readLineView removeFromSuperview];
    [coverImage removeFromSuperview];
    [self.captureVideoPreviewLayer removeFromSuperlayer];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    if ([metadataObjects count] >0){
        //停止扫描
        [self stopScan];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;//扫描出信息
        BFLog(stringValue);
        
        //判断扫描出的信息是否正确
        if(![stringValue isEqualToString:@""])
        {
            NSData *jsonResultData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:jsonResultData options:NSJSONReadingMutableContainers error:nil];
            if (resultDic[@"macStr"] && resultDic[@"secretKey2"]) {
                //加入本地缓存列表
                GarageModel *model = [[GarageModel alloc] init];
                model.isOwner = YES;
                model.macStr = resultDic[@"macStr"];
                model.name = resultDic[@"name"]?resultDic[@"name"]:resultDic[@"macStr"];
                NSString *secretStr = resultDic[@"secretKey2"];
                model.secretKey2 = [self hexStringToByte:secretStr];
                [[AppContext sharedAppContext] addNewGarage:model];
                //发送通知，刷新列表
                [[NSNotificationCenter defaultCenter] postNotificationName:NSNOTIFICATION_ACTIVITYSUCCESS object:nil];
                
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else {
                BFALERT(@"设备信息错误");
            }
        }else{
            BFALERT(@"设备信息错误");
        }
    }
}

-(NSData*)hexStringToByte:(NSString*)hexString
{
    hexString=[[hexString uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    hexString=[hexString stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hexString=[hexString stringByReplacingOccurrencesOfString:@">" withString:@""];
    if ([hexString length]%2!=0)
    {
        return nil;
    }
    
    Byte tmpByt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i = 0; i < [hexString length]; i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; //两位 16 进制数中的第一位（高位*16 ）
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16; //0 的 Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //A 的 Ascll - 65
        else
            return nil;
        
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; //两位 16 进制数中的第二位（低位）
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //0 的 Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //A 的 Ascll - 65 
        else 
            return nil; 
        
        tmpByt[0] = int_ch1+int_ch2; ///将转化后的数放入 Byte 数组里 
        [bytes appendBytes:tmpByt length:1]; 
    } 
    return bytes; 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
