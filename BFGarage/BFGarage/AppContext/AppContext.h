//
//  AppContext.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GarageModel.h"

@interface AppContext : NSObject

@property(nonatomic, strong) NSMutableArray *garageArray;

+ (AppContext *)sharedAppContext;

- (void)addNewGarage:(GarageModel *)model;

- (void)deleteGarage:(NSInteger)index;

- (void)connectGarage:(GarageModel *)model;
@end
