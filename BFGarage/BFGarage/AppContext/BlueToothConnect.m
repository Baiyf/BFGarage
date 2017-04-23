//
//  BlueToothConnect.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
//

#import "BlueToothConnect.h"

#define UUID_TX  @"0XFFA9"

#define UUID_ACTIVITY   @"0XFFAA"   //激活
#define UUID_OPEN       @"0XFFAB"   //开锁
#define UUID_AFFIRM     @"0XFFAC"   //设备确认

#define KEY1 @""

@interface BlueToothConnect()
{
    NSTimer * connectTimer;
    NSTimer * noWeightTimer;// 超过15s未上秤，则表示没有称重则不算称重，连接超时
    
    BlueConnectResult blueConnectResult;
    CBPeripheral * picoocPeripheral;
    CBCentralManager * centralManager;
    
    NSString * macStr; //蓝牙mac地址
    
    BOOL isJustJudge; //判断是否是只判断蓝牙是否打开
    BOOL isJustJudgeConnect; //判断是否蓝牙连接上
    
    BOOL isActivity; //判断是否激活
    
    BlueToothConnectionState connectionState;
}
@property (nonatomic, strong) BlueToothConnectionStateBlock blueToothConnectionStateBlock;
@end

@implementation BlueToothConnect


///启动蓝牙
- (void)startBlueToothWithSucceedBlueBlock:(SucceedBlueBlock)succeed fail:(FailBlueBlock)fail updateBlueToothState:(BlueToothConnectionStateBlock)blueState
{
    //初始化CBCentralManager，管理中心设备
    self.isStartBlueTooth = YES;
    self.succeedBlueBlock = succeed;
    self.failBlueBlock = fail;
    self.blueToothConnectionStateBlock = blueState;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    isJustJudge = NO;
    isJustJudgeConnect = NO;
    hasSmartMatchData = NO;
    self.isDidFinishWeight = NO;
    singleData = 0;
}

///判断蓝牙的状态
- (void)judgeBlueToothState:(BlueStateBlock)blueState
{
    NSLog(@"whatlong-2-judgeBlueToothState");
    self.blueStateBlock = blueState;
    isJustJudge = YES;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

///判断蓝牙已经连接上了设备
- (void)judgeBlueToothConnect:(SucceedBlueBlock)succeed fail:(FailBlueBlock)fail
{
    NSLog(@"whatlong-3-judgeBlueToothConnect");
    self.isStartBlueTooth = YES;
    self.succeedBlueBlock = succeed;
    self.failBlueBlock = fail;
    isJustJudgeConnect = YES;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - CBCentralManagerDelegate

//检测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (centralManager == central) {
        switch ([central state]) {
            case CBCentralManagerStateUnknown:
                NSLog(@"状态未知,即将更新");
                break;
            case CBCentralManagerStatePoweredOff:
                NSLog(@"未打开蓝牙");
                if (self.blueToothConnectionStateBlock) {
                    connectionState = BlueToothConnectionStatePoweredOff;
                    self.blueToothConnectionStateBlock(BlueToothConnectionStatePoweredOff,NO);
                }
                break;
            case CBCentralManagerStatePoweredOn:
                NSLog(@"蓝牙运行正常");
                BOOL isStartScann = YES;
                if ([LTViewControllerManager shared].enterBackgroundByBlue == YES) {
                    [LTViewControllerManager shared].enterBackgroundByBlue = NO;
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    if (notification!=nil) {
                        isStartScann = false;
                        NSDate *now=[NSDate new];
                        notification.fireDate=[now dateByAddingTimeInterval:0.1];
                        notification.timeZone=[NSTimeZone defaultTimeZone];
                        notification.alertBody=@"您的蓝牙已经打开，快来看看吧！";
                        [[UIApplication sharedApplication]  scheduleLocalNotification:notification];
                    }
                }
                if (isStartScann) {
                    if (isJustJudge == NO || isJustJudgeConnect == YES) {
                        [self startScanning];
                    }
                }
                
                break;
            case CBCentralManagerStateResetting:
                NSLog(@"蓝牙正在复位");
                break;
            case CBCentralManagerStateUnauthorized:
                NSLog(@"未授权低功耗蓝牙");
                break;
            case CBCentralManagerStateUnsupported:
                NSLog(@"此设备不支 持蓝牙");
                break;
            default:
                break;
        }
        //判断蓝牙的状态
        if (isJustJudge == YES) {
            if ([central state] == CBCentralManagerStatePoweredOn) {
                isJustJudge = NO;    //判断蓝牙是否开启的标识，判断成功需要变为NO
                centralManager.delegate = nil;
                centralManager = nil;
            }
            self.blueStateBlock([central state]);
        }
    }
}

//扫描成功发现设备时的回调，是scanForPeripheralsWithServices
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"whatlong-6-centralManager");
    NSMutableString * theName = [NSMutableString stringWithFormat:@"Peripheral Info:"];
    [theName appendFormat:@"Name: %@ ",peripheral.name];
    [theName appendFormat:@"RSSI: %@ ",RSSI];
    [theName appendFormat:@"UUID: %@ ",peripheral.identifier];
    if ([peripheral.name isEqual:@"SD"]) {
        if ([centralManager isEqual:central]) {
            NSLog(@"扫瞄到正确设备");
            picoocPeripheral = peripheral;
            picoocPeripheral.delegate = self;
            
            //获取Mac地址
            NSData * macData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            macStr = [[self transformDataToStr:macData withRange:NSMakeRange(0, 11)] mutableCopy];
            //获取激活状态
            NSString *activity = [self transformDataToStr:macData withRange:NSMakeRange(12, 2)];
            if ([activity isEqualToString:@"01"]) {
                isActivity = YES;
            }else {
                isActivity = NO;
            }
            
            NSLog(@"name:%@----:%@",theName,macStr);
            
            [centralManager stopScan];
            [centralManager connectPeripheral:peripheral options:nil];
        }
    }
}

//连接指定设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"whatlong-8-centralManager");
    NSLog(@"连接蓝牙");
    [connectTimer invalidate];
    //    [centralManager stopScan];
    
    if (isJustJudgeConnect == YES) {
        [self disconnectPeripheral];
        self.succeedBlueBlock(0,blueToothType);
        return;
    }
    peripheral.delegate = self;
    //扫描服务
    [peripheral discoverServices:nil];

    if (self.blueToothConnectionStateBlock) {
        if ([peripheral.name isEqual:@"SD"]) {
            connectionState = BlueToothConnectionStateConnectionSucceedLatins;
        }
        
        self.blueToothConnectionStateBlock(connectionState,NO);
    }
}

//连接指定设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"whatlong-9-centralManager");
    NSLog(@"链接失败");
    [connectTimer invalidate];
    [self disconnectPeripheral];
}

//对设备扫描服务，扫瞄到服务后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"whatlong-10-peripheral");
    for (CBService *aService in peripheral.services)
    {
        //扫描特征
        [peripheral discoverCharacteristics:nil forService:aService];
    }
}

//扫描到特征后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"whatlong-11-peripheral");
    if (peripheral.identifier == NULL) {
        return;
    }
    if (!error) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_AFFIRM]]) {
                receiveCharateristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:receiveCharateristic];
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ACTIVITY]])
            {
                sendActivityCharateristic = characteristic;
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPEN]]){
                sendOpenCharateristic = characteristic;
            }
        }
    }
    //特征扫瞄完连接成功，让主界面动画开始旋转
    NSLog(@"\n\n\n");
}

//
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"whatlong-12-peripheral");
    NSLog(@"～～～～～%@",characteristic.value);
    
    //激活
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ACTIVITY]]) {
        //如果未激活
        if (!isActivity) {
            //发送激活数据
            NSData *data;
            //发送激活
            [self sendValueWithKey:KEY1 characteristic:sendActivityCharateristic];
        }
    }//开锁
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPEN]]){
        //发送开锁数据
        NSData *data;
        [self sendValueWithKey:data characteristic:sendOpenCharateristic];
    }//确认
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_AFFIRM]]){
        //如果未激活，说明收到的是验证步骤，取 前16位为密钥二，
        if (!isActivity && characteristic.value.length==20) {
            //判断Mac地址是否匹配
            NSData *dataMac = [characteristic.value subdataWithRange:NSMakeRange(15, 4)];
            NSData *localData;
            if ([dataMac isEqualToData:localData]) {
                //密钥二
                NSData *dataSecret = [characteristic.value subdataWithRange:NSMakeRange(0, 16)];
                [self sendValueWithKey:dataSecret characteristic:sendActivityCharateristic];
            }
        }//第二步验证成功
        else if (!isActivity && characteristic.value.length==2){
            isActivity = YES;
        }
    }
}

#pragma mark - 辅助方法

//开始扫描
- (void)startScanning
{
    NSLog(@"whatlong-5-startScanning");
    NSLog(@"开始扫瞄");
    NSDictionary * options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [centralManager scanForPeripheralsWithServices:nil options:options];
    if (self.blueToothConnectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectioning;
        self.blueToothConnectionStateBlock(BlueToothConnectionStateConnectioning,NO);
    }
    
    if (isJustJudgeConnect == NO) {
        
    }
    //开一个定时器监控连接超时的情况
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(connectTimeout:) userInfo:nil repeats:NO];
}

- (NSString *)transformDataToStr:(NSData *)macData withRange:(NSRange *)range
{
    NSLog(@"whatlong-7-transformMacDataToStr");
    NSString * str = [NSString stringWithFormat:@"%@",macData];
    NSMutableString * macString = nil;
    macString = [NSMutableString stringWithFormat:@"%@",[str substringWithRange:range]];
    return [macString uppercaseString];
}


//发送数据，data为发送的数据，type传定值CBCharacteristicWriteWithResponse
- (CBCharacteristicWriteType)sendTransparentData:(NSData *)data
                                            type:(CBCharacteristicWriteType)type
                                  characteristic:(CBCharacteristic *)characteristic{
    NSLog(@"whatlong-19-sendTransparentData");
    NSLog(@"[MyPeripheral] sendTransparentData:%@", data);
    if (characteristic == nil) {
        return CBCharacteristicWriteWithResponse;
    }
    CBCharacteristicWriteType actualType = type;
    if (type == CBCharacteristicWriteWithResponse) {
        if (!(characteristic.properties & CBCharacteristicPropertyWrite))
            actualType = CBCharacteristicWriteWithoutResponse;
    }
    else {
        if (!(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse))
            actualType = CBCharacteristicWriteWithResponse;
    }
    [picoocPeripheral writeValue:data forCharacteristic:characteristic type:actualType];
    return actualType;
}

//链接超时
- (void)connectTimeout:(NSTimer *)time
{
    NSLog(@"whatlong-21-connectTimeout");
    [noWeightTimer invalidate];
    
    if (self.blueToothConnectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectionTimeOut;
        self.blueToothConnectionStateBlock(BlueToothConnectionStateConnectionTimeOut,NO);
    }
    [self disconnectPeripheral];
    shake_to_failed_diff_time = [DateUtils getCurrentTimeStamp] - shake_to_failed_diff_time;
    [self uploadFailedDiffTime];
}

//断开蓝牙
- (void)disconnectPeripheral
{
    NSLog(@"whatlong-22-disconnectPeripheral");
    NSLog(@"蓝牙断开");
    if (picoocPeripheral != nil) {//如果扫描到设备，self.picoocPeripheral不为空
        [self performBlock:^{
            [centralManager cancelPeripheralConnection:picoocPeripheral];
        } afterDelay:0.5];
    }else
    {
        blueConnectResult = BlueConnectTimeOut;
        if (self.failBlueBlock) {
            self.failBlueBlock(blueConnectResult);
        }
    }
}

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth {
    NSLog(@"whatlong-24-stopBlueTooth");
    if (centralManager != nil) {//如果扫描到设备，self.picoocPeripheral不为空
        [centralManager stopScan];
        [centralManager cancelPeripheralConnection:picoocPeripheral];
    }
    
    if (connectTimer) {
        [connectTimer invalidate];
    }
    
    if (noWeightTimer) {
        [noWeightTimer invalidate];
    }
    
    if (self.failBlueBlock) {
        self.failBlueBlock = nil;
    }
    
    if (self.blueToothConnectionStateBlock) {
        self.blueToothConnectionStateBlock = nil;
    }
    
    if (self.succeedBlueBlock) {
        self.succeedBlueBlock = nil;
    }
    
    if (self.blueStateBlock) {
        self.blueStateBlock = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"whatlong-25-centralManager");
    
    NSLog(@"蓝牙已经断开");
    NSLog(@"centraManager = %@  self.picoocPeripheral = %@",centralManager,picoocPeripheral);
    NSLog(@"aaaerror = %@ peripheral = %@ central = %@",error,peripheral,central);
    //如果非正常断开，把蓝牙释放掉，重新扫瞄
    if (self.isDidFinishWeight == NO) {
        if (error != nil) {
            NSLog(@"蓝牙意外断开");
            self.failBlueBlock(blueConnectResult);
            connect_to_failed_diff_time = [DateUtils getCurrentTimeStamp] - connect_to_failed_diff_time;
            
            if (self.blueToothConnectionStateBlock) {
                connectionState = BlueToothConnectionStateConnectionOff;
                [noWeightTimer invalidate];
                self.blueToothConnectionStateBlock(BlueToothConnectionStateConnectionOff,hasSmartMatchData);
            }
        }
        
        [self uploadFailedDiffTime];
    }else
    {
        NSLog(@"蓝牙正常断开");
        if (blueConnectResult == BlueConnectTimeOut) {
            self.failBlueBlock(blueConnectResult);
        }
        
        if (self.blueToothConnectionStateBlock) {
            connectionState = BlueToothConnectionStateConnectionOff;
            [noWeightTimer invalidate];
            self.blueToothConnectionStateBlock(BlueToothConnectionStateConnectionOff,hasSmartMatchData);
        }
    }
    
}

//发送命令 14位随机数作头部加上6位MAC组成20bytes，使用秘钥加密
- (void)sendValueWithKey:(NSString *)key characteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"whatlong-27-sendStepOneValue");
    Byte byteArray[3] = {0xF1,0x03,0x30};
    NSData * theData = [[NSData alloc] initWithBytes:byteArray length:20];
    
    [self sendTransparentData:[self AES128Encrypt:theData key:key]
                         type:CBCharacteristicWriteWithoutResponse
               characteristic:characteristic];
}

#pragma mark - --------数据加密解密--------
//加密
- (NSData *)AES128Encrypt:(NSData *)plainData key:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128+1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [key getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [plainData length];
    
    int diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    int newSize = 0;
    
    if(diff > 0)
    {
        newSize = dataLength + diff;
    }
    
    char dataPtr[newSize];
    memcpy(dataPtr, [plainData bytes], [plainData length]);
    for(int i = 0; i < diff; i++)
    {
        dataPtr[i + dataLength] = 0x00;
    }
    
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    memset(buffer, 0, bufferSize);
    
    size_t numBytesCrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,   //这里用的 NoPadding的填充方式
                                          //除此以外还有 kCCOptionPKCS7Padding 和 kCCOptionECBMode
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          dataPtr,
                                          sizeof(dataPtr),
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        return resultData;
    }
    free(buffer);
    return nil;
}

//解密
+ (NSData *)AES128Decrypt:(NSData *)plainData key:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [AESIV getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSData *data = plainData;
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        return resultData;
    }
    free(buffer);
    return nil;
}

@end
