//
//  BlueToothConnect.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
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
    NSMutableDictionary  * deviceDic;   //搜索到的设备列表
    
    CBCharacteristic * sendActivityCharateristic;   //激活特征
    CBCharacteristic * sendOpenCharateristic;       //开启特征
    CBCharacteristic * receiveCharateristic;        //接手设备回调特征
    
    BOOL isJustScan;                    //只是判断扫描
    BOOL isActivity;                    //判断是否激活
    BOOL isStartBlueTooth;              //判断是否启动蓝牙，如果启动，则无法重复启动
    
    BlueToothConnectionState connectionState;
}

@end

@implementation BlueToothConnect

///启动蓝牙管理
- (void)startBlueToothWithBlueToothState:(BlueToothConnectionStateBlock)blueState
{
    //初始化CBCentralManager，管理中心设备
    isStartBlueTooth = YES;
    self.connectionStateBlock = blueState;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];//调用检测蓝牙代理方法
}

//连接指定设备
- (void)connectPeripheralWith:(NSString *)macstring
{
    if ([deviceDic.allKeys containsObject:macstring]) {
        CBPeripheral *peripheral = deviceDic[macstring];
        [centralManager connectPeripheral:peripheral options:nil];//调用连接设备代理方法
        
        [centralManager stopScan];
    }else {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@""
                                                           message:@"未搜索到此设备"
                                                          delegate:nil
                                                 cancelButtonTitle:@"确定"
                                                 otherButtonTitles:nil];
        [alertView show];
    }
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
                    self.connectionStateBlock(BlueToothConnectionStatePoweredOff);
                }
                break;
            case CBManagerStatePoweredOn:
                PLog(@"蓝牙运行正常");
                //蓝牙运行正常，开始扫描设备
                [self startScanning];
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
    }
}

//扫描成功发现设备广播时的回调，是scanForPeripheralsWithServices的回调代理
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    PLog(@"-------------------: 扫描设备中.....");

    if ([peripheral.name isEqual:@"SD"]) {
        if ([centralManager isEqual:central]) {
            
            //获取Mac地址
            NSData * macData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            NSString * macString = [[self transformDataToStr:macData withRange:NSMakeRange(0, 11)] mutableCopy];
            
            //是否只是扫描
            if (isJustScan) {
                //将扫描到的加入字典
                [deviceDic setObject:peripheral forKey:macString];
            }
            //不是扫描，直接需要连接的
            else{
                
                //需要连接的设备
                scPeripheral = peripheral;
                scPeripheral.delegate = self;
                
                macStr = macString;
                
                //获取激活状态
                NSString *activity = [self transformDataToStr:macData withRange:NSMakeRange(12, 2)];
                if ([activity isEqualToString:@"01"]) {
                    isActivity = YES;//已激活
                    //已激活的需要判断Mac地址
                    
                }else {
                    isActivity = NO;//未激活
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
}

//连接指定设备成功
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    PLog(@"-------------------: 连接设备成功");
    [connectTimer invalidate];
    
    
    peripheral.delegate = self;
    //扫描所有服务
    [peripheral discoverServices:nil];//调用扫描服务代理方法

    if (self.connectionStateBlock) {
        if ([peripheral.name isEqual:@"SD"]) {
            connectionState = BlueToothConnectionStateConnectionSucceed;
            self.connectionStateBlock(connectionState);
        }
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

//断开连接
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    //如果非正常断开，把蓝牙释放掉，重新扫瞄
    if (error != nil) {
        PLog(@"蓝牙意外断开");
        connectionState = BlueToothConnectionStateConnectionOff;
    }else
    {
        PLog(@"蓝牙正常断开");
        connectionState = BlueToothConnectionStateConnectionOff;
    }

    if (self.connectionStateBlock) {
        self.connectionStateBlock(connectionState);
    }
}

#pragma mark - CBPeripheralDelegate
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
    if (!deviceDic) {
        deviceDic = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    [deviceDic removeAllObjects];
    
    NSDictionary * options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [centralManager scanForPeripheralsWithServices:nil options:options];//扫描到广播调用代理方法
    
    if (self.connectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectioning;
        self.connectionStateBlock(BlueToothConnectionStateConnectioning);
    }

    //开一个定时器监控连接超时的情况
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(connectTimeout:) userInfo:nil repeats:NO];
}

//截取信息
- (NSString *)transformDataToStr:(NSData *)macData withRange:(NSRange)range
{
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
    PLog(@"-------------------: 扫描计时器显示连接超时");
    
    if (self.connectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectionTimeOut;
        self.connectionStateBlock(BlueToothConnectionStateConnectionTimeOut);
    }
    [self disconnectPeripheral];
}

//断开蓝牙
- (void)disconnectPeripheral
{
    PLog(@"-------------------: 断开与设备的蓝牙连接");
    if (scPeripheral != nil) {//如果扫描到设备，self.scPeripheral不为空
        [self performBlock:^{
            [centralManager cancelPeripheralConnection:scPeripheral];
        } afterDelay:0.5];
    }else
    {
        if (self.connectionStateBlock) {
            self.connectionStateBlock(BlueToothConnectionStateConnectionOff);
        }
    }
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(fireBlockAfterDelay:)
               withObject:block
               afterDelay:delay];
    
}
- (void)fireBlockAfterDelay:(void (^)(void))block {
    block();
}

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth {
    PLog(@"-------------------: 退出页面时停止蓝牙");
    if (centralManager != nil) {//如果扫描到设备，self.scPeripheral不为空
        [centralManager stopScan];
        [centralManager cancelPeripheralConnection:scPeripheral];
    }
    
    if (connectTimer) {
        [connectTimer invalidate];
    }
    
    if (self.connectionStateBlock) {
        self.connectionStateBlock = nil;
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
