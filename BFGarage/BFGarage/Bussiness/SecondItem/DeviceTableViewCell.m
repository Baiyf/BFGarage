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
    // Initialization code  51 172 224
    
    self.QRbutton.layer.borderColor = [UIColor colorWithRed:51.0/255.0f green:172.0/255.0f blue:224.0/255.0f alpha:1.0].CGColor;
    self.QRbutton.layer.borderWidth = 1.0f;
    self.QRbutton.layer.cornerRadius = 3.0f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)displayQrcode:(id)sender {
    if (self.qrBlock) {
        self.qrBlock(self.cellIndex);
    }
}

@end
