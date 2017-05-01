//
//  AppContext.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
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
        self.garageArray = [[NSMutableArray alloc] init];
        self.blueConnet = [[BlueToothConnect alloc] init];
        
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
                [self preloadData];
            }
        }
    }
    return self;
}

//添加数据
- (void)addNewGarage:(GarageModel *)model
{
    [self.garageArray addObject:model];
    //数据持久化到本地
    [NSKeyedArchiver archiveRootObject:self.garageArray toFile:CACHEPATH];
}

//删除数据
- (void)deleteGarage:(NSInteger)index
{
    [self.garageArray removeObjectAtIndex:index];
    
    //还有数据，持久化到本地
    if (self.garageArray.count>0) {
        [NSKeyedArchiver archiveRootObject:self.garageArray toFile:CACHEPATH];
    }//没有数据，直接删除本地文件
    else{
        [[NSFileManager defaultManager] removeItemAtPath:CACHEPATH error:nil];
    }
}

- (void)connectGarage:(GarageModel *)model
{
    
}

#pragma mark - 假数据
- (void)preloadData{
    GarageModel *model1 = [[GarageModel alloc] init];
    model1.isOwner = YES;
    model1.macStr = @"设备1";
    
    GarageModel *model2 = [[GarageModel alloc] init];
    model2.isOwner = YES;
    model2.macStr = @"设备2";
    
    [self.garageArray addObject:model1];
    [self.garageArray addObject:model2];
}

@end
