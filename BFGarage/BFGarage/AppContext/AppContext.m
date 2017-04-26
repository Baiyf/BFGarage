//
//  AppContext.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.autohome. All rights reserved.
//

#import "AppContext.h"

#define CACHEPATH [GET_CACHE_DIR stringByAppendingPathComponent:@"CACHE"]

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
        
        NSFileManager *filemanager = [NSFileManager defaultManager];
        if ([filemanager fileExistsAtPath:CACHEPATH]) {
            NSArray *cacheList = [NSKeyedUnarchiver unarchiveObjectWithFile:CACHEPATH];
            if (cacheList.count>0) {
                [self.garageArray addObjectsFromArray:cacheList];
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

@end
