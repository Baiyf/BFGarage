//
//  BlueToothConnect.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, BlueToothConnectionState) {
    ///---搜索到广播
    BlueToothConnectionStateConnectioning,
    ///---成功连接
    BlueToothConnectionStateConnectionSucceed,
    ///---断开连接
    BlueToothConnectionStateConnectionOff,
    ///---连接超时
    BlueToothConnectionStateConnectionTimeOut,
    ///---连接失败
    BlueToothConnectionStateConnectionFailed,
    ///---未打开蓝牙
    BlueToothConnectionStatePoweredOff,
};

typedef void (^BlueToothConnectionStateBlock) (BlueToothConnectionState state); //蓝牙的连接状态

typedef void (^BlueLogBlock) (NSString *log); //蓝牙的连接状态

@interface BlueToothConnect : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>


//蓝牙状态块
@property (nonatomic, strong) BlueToothConnectionStateBlock connectionStateBlock;

@property (nonatomic, strong) BlueLogBlock logBlock;

//启动蓝牙
- (void)startBlueToothWithBlueToothState:(BlueToothConnectionStateBlock)blueState;

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth;

//连接指定设备
- (void)connectPeripheralWith:(GarageModel *)model;

//断开蓝牙
- (void)disconnectPeripheral;

@end
