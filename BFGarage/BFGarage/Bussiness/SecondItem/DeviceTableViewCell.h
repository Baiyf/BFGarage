//
//  DeviceTableViewCell.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^EditNameBlock) (NSIndexPath *indexPath);
typedef void (^DeleteDeviceBlock) (NSIndexPath *indexPath);
typedef void (^DisplayQRBlock) (NSIndexPath *indexPath);

@interface DeviceTableViewCell : UITableViewCell
@property (nonatomic, strong) NSIndexPath *cellIndex;

@property (nonatomic, weak) IBOutlet UIButton *qrButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *qrWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *deleteWidthConstraint;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) EditNameBlock editBlock;
@property (nonatomic, strong) DeleteDeviceBlock deleteBlock;
@property (nonatomic, strong) DisplayQRBlock qrBlock;
@end
