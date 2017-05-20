//
//  BFLogView.m
//  BFGarage
//
//  Created by baiyufei on 2017/5/13.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "BFLogView.h"

@interface BFLogView () {
    UIButton *_expand;
    UIButton *_cancel;
    UIButton *_clear;
    UITextView *_textView;
}

@end

@implementation BFLogView

-(id)init{
    if (self=[super init]) {
        CGRect screenRect = [UIScreen mainScreen].bounds;
        _textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 65, screenRect.size.width, screenRect.size.height-65)];
        _textView.editable=NO;
        _textView.dataDetectorTypes=UIDataDetectorTypeLink;
        
        _cancel=[UIButton buttonWithType:UIButtonTypeSystem];
        [_cancel setFrame:CGRectMake(0, 0, 60, 64)];
        _cancel.titleEdgeInsets = UIEdgeInsetsMake(15, 0, 0, 0);
        [_cancel setTitle:@"返回" forState:UIControlStateNormal];
        [_cancel addTarget:self action:@selector(closeList:) forControlEvents:UIControlEventTouchUpInside];
        
        _clear=[UIButton buttonWithType:UIButtonTypeSystem];
        [_clear setFrame:CGRectMake(screenRect.size.width-60, 0, 60, 64)];
        _clear.titleEdgeInsets = UIEdgeInsetsMake(15, 0, 0, 0);
        [_clear setTitle:@"清空" forState:UIControlStateNormal];
        [_clear addTarget:self action:@selector(clearList:) forControlEvents:UIControlEventTouchUpInside];
        
        
        [self performSelector:@selector(loadRequestAnalysis) withObject:self afterDelay:5];
    }
    return self;
}

-(void)loadRequestAnalysis
{
    CGRect screenRect = [UIScreen mainScreen].bounds;
    _expand=[UIButton buttonWithType:UIButtonTypeSystem];
    [_expand setFrame:CGRectMake(screenRect.size.width - 27, screenRect.size.height - 44, 27, 44)];
    [_expand setTitle:@">" forState:UIControlStateNormal];
    [_expand addTarget:self action:@selector(expandList:) forControlEvents:UIControlEventTouchUpInside];
    [[[UIApplication sharedApplication]windows][0] addSubview:_expand];
}

static UIView *instance = nil;
+ (void)getInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance =[[UIView alloc]init];
        
        CGRect screenRect = [UIScreen mainScreen].bounds;
        instance.backgroundColor=[UIColor whiteColor];
        instance.frame=screenRect;
    });
}

- (void)setLog:(NSString *)string {
    _textView.text = [_textView.text stringByAppendingFormat:@"\n%@ %@",[NSDate date],string];
}

-(void)closeList:(UIButton *)btn {
    [btn.superview removeFromSuperview];
    [[[UIApplication sharedApplication]windows][0] addSubview:_expand];
}

-(void)clearList:(UIButton *)btn {
    _textView.text = @"";
}

- (void)expandList:(UIButton *)btn {
    [btn removeFromSuperview];
    [BFLogView getInstance];
    [instance addSubview:_textView];
    [instance addSubview:_cancel];
    [[[UIApplication sharedApplication]windows][0] addSubview:instance];
    if(instance.superview&&![[[instance.superview subviews] objectAtIndex:[instance.superview subviews].count-1] isEqual:instance])
    {
        [instance.superview bringSubviewToFront:instance];
    }
}

@end
