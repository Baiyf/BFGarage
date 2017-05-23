//
//  AppContext.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GarageModel.h"
#import "BFLogView.h"

@interface AppContext : NSObject

@property (nonatomic, strong) BFLogView *logView;
@property (nonatomic, strong) NSMutableArray *garageArray;

+ (AppContext *)sharedAppContext;

// 添加激活成功的设备到本地
- (void)addNewGarage:(GarageModel *)model;

// 删除本地保存的设备
- (void)deleteGarage:(NSInteger)index;

// 直接连接固定设备,如果为空时,为激活进入
- (void)connectGarage:(GarageModel *)model;
@end
