//
//  BlueToothConnect.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
//

#import "BlueToothConnect.h"
#import "GarageModel.h"
#import "NSData+BFCrypto.h"

#define UUID_TX  @"0XFFA9"//UUID
#define UUID_ACTIVITY   @"0XFFAA"   //激活app设定
#define UUID_OPEN       @"0XFFAB"   //开锁app设定
#define UUID_AFFIRM     @"0XFFAC"   //app接收

static unsigned char HandShakeKey[16] = {
    0xea, 0x8b, 0x2a, 0x73, 0x16, 0xe9, 0xb0, 0x49,
    0x45, 0xb3, 0x39, 0x28, 0x0a, 0xc3, 0x28, 0x3c,
};

@interface BlueToothConnect()
{
    NSTimer * connectTimer;             //连接超时监听
    
    CBPeripheral       * scPeripheral;  //连接的设备
    CBCentralManager   * centralManager;
    NSString           * macStr;        //蓝牙mac地址
    NSData             * handShakeKey2; //握手密钥2
    
    CBCharacteristic * sendActivityCharateristic;   //激活特征
    CBCharacteristic * sendOpenCharateristic;       //开启特征
    CBCharacteristic * receiveCharateristic;        //接手设备回调特征
    
    BOOL isJustJudge;                   //判断是否是只判断蓝牙是否打开
    BOOL isJustJudgeConnect;            //判断是否蓝牙连接上
    BOOL isActivity;                    //判断是否激活
    
    BlueConnectResult blueConnectResult;
    BlueToothConnectionState connectionState;
}

@property (nonatomic, strong) BlueToothConnectionStateBlock connectionStateBlock;

@end

@implementation BlueToothConnect


///启动蓝牙管理
- (void)startBlueToothWithSucceedBlueBlock:(SucceedBlueBlock)succeed
                                      fail:(FailBlueBlock)fail
                      updateBlueToothState:(BlueToothConnectionStateBlock)blueState
{
    //初始化CBCentralManager，管理中心设备
    self.isStartBlueTooth = YES;
    self.succeedBlueBlock = succeed;
    self.failBlueBlock = fail;
    self.connectionStateBlock = blueState;
    
    isJustJudge = NO;
    isJustJudgeConnect = NO;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];//调用检测蓝牙代理方法
}

///判断蓝牙的状态
- (void)judgeBlueToothState:(BlueStateBlock)blueState
{
    PLog(@"whatlong-2-judgeBlueToothState");
    self.blueStateBlock = blueState;
    isJustJudge = YES;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

///判断蓝牙已经连接上了设备
- (void)judgeBlueToothConnect:(SucceedBlueBlock)succeed fail:(FailBlueBlock)fail
{
    PLog(@"whatlong-3-judgeBlueToothConnect");
    self.isStartBlueTooth = YES;
    self.succeedBlueBlock = succeed;
    self.failBlueBlock = fail;
    isJustJudgeConnect = YES;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBCentralManagerDelegate

//检测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (centralManager == central) {
        switch ([central state]) {
            case CBManagerStateUnknown:
                PLog(@"状态未知,即将更新");
                break;
            case CBManagerStatePoweredOff:
                PLog(@"未打开蓝牙");
                if (self.connectionStateBlock) {
                    connectionState = BlueToothConnectionStatePoweredOff;
                    self.connectionStateBlock(BlueToothConnectionStatePoweredOff,NO);
                }
                break;
            case CBManagerStatePoweredOn:
                PLog(@"蓝牙运行正常");
                if (isJustJudge == YES || isJustJudgeConnect == NO) {
                    [self startScanning];
                }
                break;
            case CBManagerStateResetting:
                PLog(@"蓝牙正在复位");
                break;
            case CBManagerStateUnauthorized:
                PLog(@"未授权低功耗蓝牙");
                break;
            case CBManagerStateUnsupported:
                PLog(@"此设备不支持蓝牙");
                break;
            default:
                break;
        }
        //判断蓝牙的状态
        if (isJustJudge == YES) {
            if ([central state] == CBManagerStatePoweredOn) {
                isJustJudge = NO;    //判断蓝牙是否开启的标识，判断成功需要变为NO
                centralManager.delegate = nil;
                centralManager = nil;
            }
            self.blueStateBlock([central state]);
        }
    }
}

//扫描成功发现设备广播时的回调，是scanForPeripheralsWithServices的回调代理
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    PLog(@"whatlong-6-centralManager");

    if ([peripheral.name isEqual:@"SD"]) {
        if ([centralManager isEqual:central]) {
            scPeripheral = peripheral;
            scPeripheral.delegate = self;
            
            //获取Mac地址
            NSData * macData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            macStr = [[self transformDataToStr:macData withRange:NSMakeRange(0, 11)] mutableCopy];
        
            //获取激活状态
            NSString *activity = [self transformDataToStr:macData withRange:NSMakeRange(12, 2)];
            if ([activity isEqualToString:@"01"]) {
                isActivity = YES;//已激活
                //已激活的需要判断Mac地址
                
            }else {
                isActivity = NO;//未激活
                isJustJudgeConnect = NO;
                [centralManager connectPeripheral:peripheral options:nil];//调用连接设备代理方法
                //存储Mac地址和固定密钥1
            }
            
            [centralManager stopScan];
            
            
            NSMutableString * theName = [NSMutableString stringWithFormat:@"Peripheral Info:"];
            [theName appendFormat:@"Name: %@ ",peripheral.name];
            [theName appendFormat:@"RSSI: %@ ",RSSI];
            [theName appendFormat:@"UUID: %@ ",peripheral.identifier];
            PLog(@"name:%@----:%@----:%@",theName,macStr,activity);
        }
    }
}

//连接指定设备成功
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    PLog(@"whatlong-8-centralManager");
    [connectTimer invalidate];
    
    if (isJustJudgeConnect == YES) {
        [self disconnectPeripheral];
        return;
    }
    peripheral.delegate = self;
    //扫描所有服务
    [peripheral discoverServices:nil];//调用扫描服务代理方法

    if (self.connectionStateBlock) {
        if ([peripheral.name isEqual:@"SD"]) {
            connectionState = BlueToothConnectionStateConnectionSucceed;
        }
        self.connectionStateBlock(connectionState,NO);
    }
}

//连接指定设备失败
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    PLog(@"-------------------: 连接设备失败");
    [connectTimer invalidate];
    [self disconnectPeripheral];
}

//对设备扫描服务，扫瞄到服务后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    PLog(@"-------------------: 扫描服务");
    for (CBService *aService in peripheral.services)
    {
        //扫描特征
        [peripheral discoverCharacteristics:nil forService:aService];
    }
}

//扫描到特征后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    PLog(@"-------------------: 服务特征");
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
    //特征扫瞄完连接成功
    PLog(@"\%@\%@\%@",[CBUUID UUIDWithString:UUID_AFFIRM],[CBUUID UUIDWithString:UUID_ACTIVITY],[CBUUID UUIDWithString:UUID_OPEN]);
}

//
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    PLog(@"-------------------: 对应特征操作");
    
    //激活
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ACTIVITY]]) {
        //如果未激活
        if (!isActivity) {
            //密钥一
            NSData *dataKey = [NSData dataWithBytes:HandShakeKey length:16];
            //发送激活
            [self sendValueWithKey:dataKey characteristic:sendActivityCharateristic];
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
                handShakeKey2 = [characteristic.value subdataWithRange:NSMakeRange(0, 16)];
                [self sendValueWithKey:handShakeKey2 characteristic:sendActivityCharateristic];
            }
        }//第二步验证成功
        else if (!isActivity && characteristic.value.length==2){
            isActivity = YES;
            
            //加入本地缓存列表
            GarageModel *model = [[GarageModel alloc] init];
            model.isOwner = YES;
            model.macStr = macStr;
            model.secretKey2 = handShakeKey2;
            [[AppContext sharedAppContext] addNewGarage:model];
        }
    }
}

#pragma mark - 辅助方法

//开始扫描
- (void)startScanning
{
    PLog(@"-------------------: 开始扫描蓝牙设备");
    NSDictionary * options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [centralManager scanForPeripheralsWithServices:nil options:options];//扫描到广播调用代理方法
    
    if (self.connectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectioning;
        self.connectionStateBlock(BlueToothConnectionStateConnectioning,NO);
    }

    //开一个定时器监控连接超时的情况
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(connectTimeout:) userInfo:nil repeats:NO];
}

- (NSString *)transformDataToStr:(NSData *)macData withRange:(NSRange)range
{
    PLog(@"whatlong-7-transformMacDataToStr");
    NSString * str = [NSString stringWithFormat:@"%@",macData];
    NSMutableString * macString = nil;
    macString = [NSMutableString stringWithFormat:@"%@",[str substringWithRange:range]];
    return [macString uppercaseString];
}

//发送数据，data为发送的数据，type传定值CBCharacteristicWriteWithResponse
- (CBCharacteristicWriteType)sendTransparentData:(NSData *)data
                                            type:(CBCharacteristicWriteType)type
                                  characteristic:(CBCharacteristic *)characteristic{
    PLog(@"[MyPeripheral] sendTransparentData:%@", data);
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
    [scPeripheral writeValue:data forCharacteristic:characteristic type:actualType];
    return actualType;
}

//链接超时
- (void)connectTimeout:(NSTimer *)time
{
    PLog(@"whatlong-21-connectTimeout");
    
    if (self.connectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectionTimeOut;
        self.connectionStateBlock(BlueToothConnectionStateConnectionTimeOut,NO);
    }
    [self disconnectPeripheral];
}

//断开蓝牙
- (void)disconnectPeripheral
{
    PLog(@"whatlong-22-disconnectPeripheral");
    PLog(@"蓝牙断开");
    if (scPeripheral != nil) {//如果扫描到设备，self.scPeripheral不为空
        [self performBlock:^{
            [centralManager cancelPeripheralConnection:scPeripheral];
        } afterDelay:0.5];
    }else
    {
        blueConnectResult = BlueConnectTimeOut;
        if (self.failBlueBlock) {
            self.failBlueBlock(blueConnectResult);
        }
    }
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    PLog(@"whatlong-23-performBlock");
    [self performSelector:@selector(fireBlockAfterDelay:)
               withObject:block
               afterDelay:delay];
    
}
- (void)fireBlockAfterDelay:(void (^)(void))block {
    block();
}

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth {
    PLog(@"whatlong-24-stopBlueTooth");
    if (centralManager != nil) {//如果扫描到设备，self.scPeripheral不为空
        [centralManager stopScan];
        [centralManager cancelPeripheralConnection:scPeripheral];
    }
    
    if (connectTimer) {
        [connectTimer invalidate];
    }
    
    if (self.failBlueBlock) {
        self.failBlueBlock = nil;
    }
    
    if (self.connectionStateBlock) {
        self.connectionStateBlock = nil;
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
    //如果非正常断开，把蓝牙释放掉，重新扫瞄
    if (error != nil) {
        PLog(@"蓝牙意外断开");
        self.failBlueBlock(blueConnectResult);
        
        if (self.connectionStateBlock) {
            connectionState = BlueToothConnectionStateConnectionOff;
        }
    }else
    {
        PLog(@"蓝牙正常断开");
        if (blueConnectResult == BlueConnectTimeOut) {
            self.failBlueBlock(blueConnectResult);
        }
        
        if (self.connectionStateBlock) {
            connectionState = BlueToothConnectionStateConnectionOff;
        }
    }
}

//发送命令 14位随机数作头部加上6位MAC组成20bytes，使用密钥加密
- (void)sendValueWithKey:(NSData *)key characteristic:(CBCharacteristic *)characteristic
{
    NSString *randomStr = @"";
    for (int i=0; i<14; i++) {
        int x = arc4random() % 10;
        randomStr = [randomStr stringByAppendingFormat:@"%d",x];
    }
    if (macStr.length==12) {
        randomStr = [randomStr stringByAppendingFormat:@"%@",[macStr substringWithRange:NSMakeRange(6, 6)]];
    }

    NSData * theData = [randomStr dataUsingEncoding:NSUTF8StringEncoding];
    //加密后的数据
    NSData * encryptData = [theData AES128EncryptedDataUsingKey:key error:nil];
    [self sendTransparentData:encryptData
                         type:CBCharacteristicWriteWithoutResponse
               characteristic:characteristic];
}

@end
