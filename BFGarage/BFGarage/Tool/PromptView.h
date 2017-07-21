//
//  PromptView.h
//  Lation2.0
//
//  Created by Azrael on 14-11-4.
//  Copyright (c) 2014年 PICOOC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PromptView : UIView

+ (PromptView *)shared;

/// 提示弹框
- (void)showPromtView:(NSString *)text dissmissAfterDelay:(NSTimeInterval)seconds andView:(UIView *)view;

@end
