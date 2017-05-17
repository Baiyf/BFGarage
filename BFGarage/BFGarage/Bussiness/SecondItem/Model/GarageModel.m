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
    [coder encodeObject:@(self.isOwner) forKey:@"isOwner"];
    [coder encodeObject:self.macStr forKey:@"macStr"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.secretKey2 forKey:@"secretKey2"];
    //... ... other instance variables
}
//对变量解码
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.isOwner = [[coder decodeObjectForKey:@"isOwner"] boolValue];
        self.macStr = [coder decodeObjectForKey:@"macStr"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.secretKey2 = [coder decodeObjectForKey:@"secretKey2"];
    }
    
    return self;
}


@end
