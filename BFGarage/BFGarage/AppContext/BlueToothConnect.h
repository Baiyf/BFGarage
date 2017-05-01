//
//  BlueToothConnect.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
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

typedef NS_ENUM(NSInteger, BlueConnectResult) {
    BlueConnectResultBad = 0,
    BlueConnectTimeOut, //链接超时
};


typedef void (^BlueToothConnectionStateBlock) (BlueToothConnectionState state, BOOL hasSmartMatchingData); //蓝牙的连接状态

typedef void (^SucceedBlueBlock)(BlueConnectResult result);

typedef void (^FailBlueBlock)(BlueConnectResult result);

typedef void (^BlueStateBlock)(CBManagerState state); //判断蓝牙的状态


@interface BlueToothConnect : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic * sendActivityCharateristic;
    CBCharacteristic * sendOpenCharateristic;
    CBCharacteristic * receiveCharateristic;
}
@property (nonatomic, assign) BOOL isStartBlueTooth;//判断是否启动蓝牙，如果启动，则无法重复启动

@property (nonatomic, strong) void (^succeedBlueBlock)(BlueConnectResult result);

@property (nonatomic, strong) void (^failBlueBlock)(BlueConnectResult result);

@property (nonatomic, strong) void (^blueStateBlock)(CBManagerState state); //判断蓝牙的状态

//启动蓝牙
- (void)startBlueToothWithSucceedBlueBlock:(SucceedBlueBlock)succeed fail:(FailBlueBlock)fail updateBlueToothState:(BlueToothConnectionStateBlock)blueState;

//判断蓝牙的状态
- (void)judgeBlueToothState:(BlueStateBlock)blueState;

//判断蓝牙已经连接上了设备
- (void)judgeBlueToothConnect:(SucceedBlueBlock)succeed fail:(FailBlueBlock)fail;

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth;

//断开蓝牙
- (void)disconnectPeripheral;

@end
