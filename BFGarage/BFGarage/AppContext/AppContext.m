//
//  AppContext.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "AppContext.h"
#import "BlueToothConnect.h"

#define CACHEPATH [GET_CACHE_DIR stringByAppendingPathComponent:@"CACHE"]

@interface AppContext ()
@property (nonatomic, strong) BlueToothConnect *blueConnet;

@end

@implementation AppContext

static AppContext *shareAppContext = nil;
+ (AppContext *)sharedAppContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareAppContext = [[AppContext alloc] init];
    });
    return shareAppContext;
}

- (id)init {
    self = [super init];
    if (self)
    {
        self.logView = [[BFLogView alloc] init];
        
        self.garageArray = [[NSMutableArray alloc] init];
        self.blueConnet = [[BlueToothConnect alloc] init];
        [self.blueConnet startBlueToothWithBlueToothState:^(BlueToothConnectionState state) {
            BFLog(@"\n*********\n    蓝牙状态:%ld\n*********",(long)state);
            
            switch (state) {
                case BlueToothConnectionStatePoweredOff:
                {
//                    BFALERT(@"蓝牙未开启");
                }
                    break;
                default:
                    break;
            }
        }];
        
        NSFileManager *filemanager = [NSFileManager defaultManager];
        if ([filemanager fileExistsAtPath:CACHEPATH]) {
            NSArray *cacheList = [NSKeyedUnarchiver unarchiveObjectWithFile:CACHEPATH];
            if (cacheList.count>0) {
                [self.garageArray addObjectsFromArray:cacheList];
            }
        }
        
        //线下环境，无数据时显示假数据
        if (ALL_SWITCH) {
            
        }else {
            if (self.garageArray.count == 0) {
//                [self preloadData];
            }
        }
    }
    return self;
}

//添加数据
- (void)addNewGarage:(GarageModel *)model
{
    if (model) {
        [self.garageArray addObject:model];
    }
    //数据持久化到本地
    [NSKeyedArchiver archiveRootObject:self.garageArray toFile:CACHEPATH];
}

//删除数据
- (void)deleteGarage:(NSInteger)index
{
    if (self.garageArray.count>index) {
        [self.garageArray removeObjectAtIndex:index];
    }
    
    //还有数据，持久化到本地
    if (self.garageArray.count>0) {
        [NSKeyedArchiver archiveRootObject:self.garageArray toFile:CACHEPATH];
    }//没有数据，直接删除本地文件
    else{
        [[NSFileManager defaultManager] removeItemAtPath:CACHEPATH error:nil];
    }
}

//连接某个设备
- (void)connectGarage:(GarageModel *)model
{
    [self.blueConnet connectPeripheralWith:model];
}

#pragma mark - 假数据
- (void)preloadData{
    GarageModel *model1 = [[GarageModel alloc] init];
    model1.macStr = @"AABBCCDDEEFF";
    model1.name = @"设备1";
    model1.secretKey2 = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
    
    GarageModel *model2 = [[GarageModel alloc] init];
    model2.macStr = @"AABBCCDD00FF";
    model2.name = @"设备2";
    model2.secretKey2 = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.garageArray addObject:model1];
    [self.garageArray addObject:model2];
}

@end
