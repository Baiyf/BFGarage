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
#import "AESCrypto.h"

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
    isJustScan = YES;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];//调用检测蓝牙代理方法
}

//连接指定设备
- (void)connectPeripheralWith:(NSString *)macstring
{
    //1 如果之前有连接，取消掉，连接默认
    if (scPeripheral) {
        [scPeripheral setNotifyValue:NO forCharacteristic:receiveCharateristic];
        receiveCharateristic = nil;
        sendOpenCharateristic = nil;
        sendActivityCharateristic = nil;
        
        [centralManager cancelPeripheralConnection:scPeripheral];
        scPeripheral = nil;
    }
    
    
    //2.如果传入的 mac 地址为空，说明走的是激活方式
    if (!macstring) {
        //2.1 判断蓝牙是否开启
        if (centralManager.state == CBManagerStatePoweredOn) {
            //2.2 判断是否开启扫描
            if (!centralManager.isScanning) {
                isJustScan = NO;
                [self startScanning];
            }else{
                isJustScan = NO;
                for (NSString *mac in deviceDic.allKeys) {
                    if (![self isExist:mac]) {
                        CBPeripheral *peripheral = deviceDic[mac];
                        [centralManager connectPeripheral:peripheral options:nil];
                        [centralManager stopScan];
                        return;
                    }
                }
            }
        }else {
            BFALERT(@"蓝牙状态异常");
        }
        
        return;
    }
    
    //3.如果传入mac 地址不为空，说明走的是直接连接
    if ([deviceDic.allKeys containsObject:macstring]) {
        CBPeripheral *peripheral = deviceDic[macstring];

        //3.1 调用连接设备代理方法
        [centralManager connectPeripheral:peripheral options:nil];
        [centralManager stopScan];
    }else {
        BFALERT(@"未搜索到此设备");
    }
}

#pragma mark - CBCentralManagerDelegate

//检测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (centralManager == central) {
        switch ([central state]) {
            case CBManagerStateUnknown:
                self.logBlock(@"状态未知,即将更新");
                break;
            case CBManagerStatePoweredOff:
                self.logBlock(@"未打开蓝牙");
                if (self.connectionStateBlock) {
                    connectionState = BlueToothConnectionStatePoweredOff;
                    self.connectionStateBlock(BlueToothConnectionStatePoweredOff);
                }
                break;
            case CBManagerStatePoweredOn:
                self.logBlock(@"蓝牙运行正常");
                //蓝牙运行正常，开始扫描设备
                [self startScanning];
                break;
            case CBManagerStateResetting:
                self.logBlock(@"蓝牙正在复位");
                break;
            case CBManagerStateUnauthorized:
                self.logBlock(@"未授权低功耗蓝牙");
                break;
            case CBManagerStateUnsupported:
                self.logBlock(@"此设备不支持蓝牙");
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
    self.logBlock(@"-----------: 扫描设备中.....");

    if ([peripheral.name isEqual:@"SC"]) {
        if ([centralManager isEqual:central]) {
            
            //获取Mac地址
            NSData * macData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            NSString * macString = [[self transformDataToStr:macData withRange:NSMakeRange(0, 12)] mutableCopy];
            
            //将扫描到的加入字典
            [deviceDic setObject:peripheral forKey:macString];
            
            //是否只是扫描
//            if (isJustScan) {
//                
//            }
//            //不是扫描，直接需要连接的
//            else{
                if (![self isExist:macString]) {
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
                    }
                    
                    [centralManager stopScan];
                    
                    NSMutableString * theName = [NSMutableString stringWithFormat:@"Peripheral Info:"];
                    [theName appendFormat:@"Name: %@ ",peripheral.name];
                    [theName appendFormat:@"RSSI: %@ ",RSSI];
                    [theName appendFormat:@"UUID: %@ ",peripheral.identifier];
                    self.logBlock([NSString stringWithFormat:@"蓝牙信息:%@----:\nMac地址:%@----:\n激活状态%@",theName,macStr,activity]);
                }
//            }
        }
    }
}

//连接指定设备成功
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.logBlock(@"-----------: 连接设备成功");
    [connectTimer invalidate];
    
    
    peripheral.delegate = self;
    //扫描所有服务
    [peripheral discoverServices:nil];//调用扫描服务代理方法

    if (self.connectionStateBlock) {
        if ([peripheral.name isEqual:@"SC"]) {
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
    self.logBlock(@"-----------: 连接设备失败");
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
        self.logBlock(@"-----------:蓝牙意外断开");
        connectionState = BlueToothConnectionStateConnectionOff;
    }else
    {
        self.logBlock(@"-----------:蓝牙正常断开");
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
    self.logBlock(@"-----------: 扫描服务");
    for (CBService *aService in peripheral.services)
    {
        //扫描特征
        [peripheral discoverCharacteristics:nil forService:aService];
    }
}

//扫描到特征后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    self.logBlock(@"-----------: 服务特征");
    if (peripheral.identifier == NULL) {
        return;
    }
    if (!error) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_AFFIRM]]) {
                receiveCharateristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                if (!isActivity) {
                    //密钥一
                    NSData *dataKey = [NSData dataWithBytes:HandShakeKey length:16];
                    //发送激活
                    [self sendValueWithKey:dataKey characteristic:sendActivityCharateristic];
                }
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
}

//
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    self.logBlock(@"-----------: 对应特征操作");
    
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
        if (!isActivity) {
            //使用密钥一对返回的数据解密
            NSData *decryptData = [self decryptData:characteristic.value withKey:[NSData dataWithBytes:HandShakeKey length:16]];
            
            self.logBlock([NSString stringWithFormat:@"接收密钥二成功，解密数据:%@",decryptData]);
            
            //判断Mac地址是否匹配
            NSData *dataMac = [decryptData subdataWithRange:NSMakeRange(15, 4)];
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

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSString *errorString = [NSString stringWithFormat:@"特征%@写入出错:%@",[characteristic UUID],[error localizedDescription]];
        self.logBlock(errorString);
    }else {
        NSString *errorString = [NSString stringWithFormat:@"特征%@写入成功",[characteristic UUID]];
        self.logBlock(errorString);
    }
}

#pragma mark - 辅助方法

//开始扫描
- (void)startScanning
{
    self.logBlock(@"-----------: 开始扫描蓝牙设备");
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
//    connectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(connectTimeout:) userInfo:nil repeats:NO];
}

//截取信息
- (NSString *)transformDataToStr:(NSData *)macData withRange:(NSRange)range
{
    NSString * str = [[[[NSString stringWithFormat:@"%@",macData]
                        stringByReplacingOccurrencesOfString: @"<" withString: @""]
                       stringByReplacingOccurrencesOfString: @">" withString: @""]
                      stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSMutableString * macString = nil;
    macString = [NSMutableString stringWithFormat:@"%@",[str substringWithRange:range]];
    return [macString uppercaseString];
}

//发送数据，data为发送的数据，type传定值CBCharacteristicWriteWithResponse
- (CBCharacteristicWriteType)sendTransparentData:(NSData *)data
                                            type:(CBCharacteristicWriteType)type
                                  characteristic:(CBCharacteristic *)characteristic{
    self.logBlock([NSString stringWithFormat:@"加密后:%@",data]);
    
    if (characteristic == nil) {
        return CBCharacteristicWriteWithResponse;
    }
    CBCharacteristicWriteType actualType = type;
    if (type == CBCharacteristicWriteWithResponse) {
        if (!(characteristic.properties & CBCharacteristicPropertyWrite))
            actualType = CBCharacteristicWriteWithResponse;
    }
    else {
        if (!(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse))
            actualType = CBCharacteristicWriteWithoutResponse;
    }
    [scPeripheral writeValue:data forCharacteristic:characteristic type:actualType];
    return actualType;
}

//链接超时
- (void)connectTimeout:(NSTimer *)time
{
    self.logBlock(@"-------------------: 扫描计时器显示连接超时");
    
    if (self.connectionStateBlock) {
        connectionState = BlueToothConnectionStateConnectionTimeOut;
        self.connectionStateBlock(BlueToothConnectionStateConnectionTimeOut);
    }
    [self disconnectPeripheral];
}

//断开蓝牙
- (void)disconnectPeripheral
{
    self.logBlock(@"-------------------: 断开与设备的蓝牙连接");
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
    self.logBlock(@"-------------------: 退出页面时停止蓝牙");
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
//    NSMutableData *sendData=[NSMutableData data];
//    for (int i=0; i<10; i++) {
//        int x = arc4random() % 16;
//        NSString *hexString = [self ToHex:x];
//        NSData *hexData = [self hexToBytes:hexString];
//        [sendData appendData:hexData];
//    }
//    if (macStr.length==12) {
//        [sendData appendData:[self hexToBytes:macStr]];
//    }
//    
//    unsigned char dat[16];
//    memcpy(dat, [sendData bytes], 16);
//    
//    unsigned char chainCipherBlock[16];
//    unsigned char *shakeKey = (unsigned char *)[key bytes];    unsigned char i;
//    for(i=0;i<16;i++)
//    {
//        AES_Key_Table[i]= shakeKey[i];
//    }
//    memset(chainCipherBlock,0x00,sizeof(chainCipherBlock));
//    
//    //加密后的数据
//    aesEncInit();
//    aesEncrypt(dat, chainCipherBlock); //AES加密，数组dat里面的新内容就是加密后的数据。
    
//    Byte bytes[20] = {0x00,0x00,0x00,0x00,
//        0x00,0x00,0x00,0x00,
//        0x00,0x00,0x00,0x00,
//        0x00,0x00,0xfa,0x63,
//        0x51,0x56,0xbb,0x74};
    
    
    Byte bytes[20];
    //10位随机数作头部 + 6位十六进制MAC + 4位0 共20位
    {
        int bytesLenght = 0;
        //10位随机数
        for (bytesLenght = 0; bytesLenght < 10; bytesLenght ++) {
            int x = arc4random() % 256;
            NSString *hexString = [self ToHex:x];
            const char *s = [hexString UTF8String];
            Byte byte = (Byte)strtol(s, NULL, 16);
            bytes[bytesLenght] = byte;
        }
        //6位Mac地址
        for (int idx = 0; idx+2 <= macStr.length; idx+=2) {
            NSRange range = NSMakeRange(idx, 2);
            NSString* hexStr = [macStr substringWithRange:range];
            const char *s = [hexStr UTF8String];
            Byte byte = (Byte)strtol(s, NULL, 16);
            bytes[bytesLenght] = byte;
            bytesLenght ++;
        }
        //4位0
        bytes[16] = 0x00;
        bytes[17] = 0x00;
        bytes[18] = 0x00;
        bytes[19] = 0x00;
    }
    
    
    unsigned char dat[20];
    memcpy(dat, bytes, 20);
    
    unsigned char chainCipherBlock[16];
    unsigned char *shakeKey = (unsigned char *)[key bytes];
    unsigned char i;
    for(i=0;i<16;i++)
    {
        AES_Key_Table[i]= shakeKey[i];
    }
    memset(chainCipherBlock,0x00,sizeof(chainCipherBlock));
    
    //加密后的数据
    aesEncInit();
    aesEncrypt(dat, chainCipherBlock);
    aesEncrypt(dat+16, chainCipherBlock);
    
    self.logBlock([NSString stringWithFormat:@"特征:%@",characteristic]);
    self.logBlock([NSString stringWithFormat:@"加密前:%@",[NSData dataWithBytes:bytes length:20]]);
    [self sendTransparentData:[NSData dataWithBytes:dat length:20]
                         type:CBCharacteristicWriteWithResponse
               characteristic:characteristic];
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key{
    unsigned char dat[32];
    memcpy(dat, [data bytes], 32);
    
    unsigned char chainCipherBlock[16];
    //    unsigned char *shakeKey = (unsigned char *)[key bytes];
    //    unsigned char shakeKey[16] = HandShakeKey;
    unsigned char i;
    for(i=0;i<16;i++)
    {
        //        AES_Key_Table[i]= shakeKey[i];
        AES_Key_Table[i] = HandShakeKey[i];
    }

    memset(chainCipherBlock,0x00,sizeof(chainCipherBlock));//ÕâÀïÒªÖØÐÂ³õÊ¼»¯Çå¿Õ
    aesDecInit();//ÔÚÖ´ÐÐ½âÃÜ³õÊ¼»¯Ö®Ç°¿ÉÒÔÎªAES_Key_Table¸³ÖµÓÐÐ§µÄÃÜÂëÊý¾Ý
    aesDecrypt(dat, chainCipherBlock);//AES½âÃÜ£¬ÃÜÎÄÊý¾Ý´æ·ÅÔÚdatÀïÃæ£¬¾­½âÃÜ¾ÍÄÜµÃµ½Ö®Ç°µÄÃ÷ÎÄ¡£
    aesDecrypt(dat+16, chainCipherBlock);
    NSData *decryptData = [NSData dataWithBytes:dat length:32];
    return decryptData;
}

//判断是否是已添加设备
- (BOOL)isExist:(NSString *)macString
{
    BOOL exist = NO;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.macStr=%@",macString];
    NSArray *predicateArray = [[AppContext sharedAppContext].garageArray filteredArrayUsingPredicate:predicate];
    if (predicateArray.count!=0) {
        exist = YES;
    }
    
    return exist;
}

//16进制字符串转为 data
- (NSData *)hexToBytes:(NSString *)str
{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= str.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [str substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

//将十进制转化为十六进制
- (NSString *)ToHex:(int)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    //不够一个字节凑0
    if(str.length == 1){
        return [NSString stringWithFormat:@"0%@",str];
    }else{
        return str;
    }
}

@end
