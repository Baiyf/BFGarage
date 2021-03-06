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

@interface BlueToothConnect : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

//蓝牙状态块
@property (nonatomic, strong) BlueToothConnectionStateBlock connectionStateBlock;

//启动蓝牙
- (void)startBlueToothWithBlueToothState:(BlueToothConnectionStateBlock)blueState;

//连接指定设备 model有值说明是连接，nil说明是激活
- (void)connectPeripheralWith:(GarageModel *)model;


/*------------- 下面的方法目前没有用到 --------------*/

//立即停止蓝牙 --- 在页面退出或者释放的时候调用，同时把所有的block赋空
- (void)stopBlueTooth;
//断开蓝牙
- (void)disconnectPeripheral;

@end
