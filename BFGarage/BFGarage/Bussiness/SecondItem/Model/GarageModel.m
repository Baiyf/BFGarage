//
//  GarageModel.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/25.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "GarageModel.h"

@implementation GarageModel

//对变量编码
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:@(self.selected) forKey:@"selected"];
    [coder encodeObject:self.macStr forKey:@"macStr"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.secretKey2 forKey:@"secretKey2"];
    [coder encodeBool:self.isowner forKey:@"isowner"];
    //... ... other instance variables
}
//对变量解码
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.selected = [[coder decodeObjectForKey:@"selected"] boolValue];
        self.macStr = [coder decodeObjectForKey:@"macStr"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.secretKey2 = [coder decodeObjectForKey:@"secretKey2"];
        if ([coder containsValueForKey:@"isowner"]) {
            self.isowner = [coder decodeBoolForKey:@"isowner"];
        }else {
            self.isowner = YES;
        }
    }
    
    return self;
}


@end
