//
//  GarageModel.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/25.
//  Copyright © 2017年 com.autohome. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GarageModel : NSObject

@property (nonatomic, assign) BOOL isOwner;
@property (nonatomic, strong) NSString *macStr;
@property (nonatomic, strong) NSString *secretKey1;
@property (nonatomic, strong) NSString *secretKey2;

@end
