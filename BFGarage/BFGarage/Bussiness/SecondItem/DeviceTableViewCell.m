//
//  DeviceTableViewCell.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "DeviceTableViewCell.h"

@implementation DeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width-70;
    self.deleteWidthConstraint.constant = self.qrWidthConstraint.constant = 1.0 * screenWidth / 2;
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        [self.qrButton.titleLabel setFont:[UIFont systemFontOfSize:10.0]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)editNameButtonOnClicked:(id)sender {
    if (self.editBlock) {
        self.editBlock(self.cellIndex);
    }
}

- (IBAction)deleteButtonOnClicked:(id)sender {
    if (self.deleteBlock) {
        self.deleteBlock(self.cellIndex);
    }
}

- (IBAction)displayQrcode:(id)sender {
    if (self.qrBlock) {
        self.qrBlock(self.cellIndex);
    }
}

@end
