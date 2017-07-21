//
//  PromptView.m
//  Lation2.0
//
//  Created by Azrael on 14-11-4.
//  Copyright (c) 2014年 PICOOC. All rights reserved.
//

#import "PromptView.h"

@interface PromptView()
{
    UILabel * promtLabel;
}
@end

@implementation PromptView

static PromptView * promptView = nil;

+ (PromptView *)shared
{
    if (promptView == nil) {
        promptView = [[PromptView alloc] init];
        promptView.layer.cornerRadius = 10;
        promptView.layer.masksToBounds = YES;
        promptView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    }
    return promptView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/// 提示弹框
- (void)showPromtView:(NSString *)text dissmissAfterDelay:(NSTimeInterval)seconds andView:(UIView *)view
{
    CGSize sizeToFit = [text boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.0]}
                                          context:nil].size;
    int lineNumber = sizeToFit.height / 16;
    
    promtLabel = (UILabel *)[view viewWithTag:9999];
    if (promtLabel &&[promtLabel isKindOfClass:[UILabel class]]) {
        return;
    }
    
    self.frame = CGRectMake(CGRectGetMaxX(view.frame) / 2 - (sizeToFit.width + 60) / 2,
                            view.frame.size.height / 2 - 70,
                            sizeToFit.width + 60,
                            sizeToFit.height + lineNumber * 4  + 40);
    
    promtLabel = [[UILabel alloc] initWithFrame:CGRectMake(10 , 10, sizeToFit.width + 40, sizeToFit.height + lineNumber * 4  + 20)];
    promtLabel.numberOfLines = 0;
    promtLabel.tag = 9999;
    promtLabel.text = text;
    promtLabel.textColor = [UIColor whiteColor];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName:[UIFont systemFontOfSize:16.0], NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:[UIColor whiteColor]};
    promtLabel.attributedText =  [[NSAttributedString alloc]initWithString:text attributes:attributes];
    [promptView addSubview:promtLabel];
    [view addSubview:promptView];
    
    [self performSelector:@selector(removeView) withObject:self afterDelay:seconds];
}

- (void)removeView
{
    if (promtLabel) {
        [promtLabel removeFromSuperview];
        [promptView removeFromSuperview];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
