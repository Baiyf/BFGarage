//
//  GarageModel.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/25.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GarageModel : NSObject

@property (nonatomic, assign) BOOL isOwner;
@property (nonatomic, strong) NSString *macStr;
@property (nonatomic, strong) NSData *secretKey2;

@end
