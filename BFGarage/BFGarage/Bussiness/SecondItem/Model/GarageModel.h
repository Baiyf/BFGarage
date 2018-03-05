//
//  GarageModel.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/25.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GarageModel : NSObject

@property (nonatomic, strong) NSString *macStr;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *secretKey2;
@property (nonatomic, assign) BOOL isowner;

//配合编辑界面做的
@property (nonatomic, assign) BOOL selected;

@end
