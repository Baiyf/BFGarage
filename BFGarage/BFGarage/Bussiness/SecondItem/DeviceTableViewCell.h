//
//  DeviceTableViewCell.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^DisplayQRBlock) (NSIndexPath *indexPath);

@interface DeviceTableViewCell : UITableViewCell
@property (nonatomic, strong) NSIndexPath *cellIndex;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) DisplayQRBlock qrBlock;
@end
