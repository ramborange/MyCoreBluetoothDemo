//
//  StrainerUseTimeView.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/10/11.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "StrainerUseTimeView.h"
#import <QuartzCore/QuartzCore.h>
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height
@interface StrainerUseTimeView()
{
    CAGradientLayer *gradientLayer;
}

@property (nonatomic, strong) UIView *progressview;
@end

@implementation StrainerUseTimeView
-(void)dealloc {
    _progressview = nil;
    _indicatorview = nil;
}

- (void)layoutSubviews {
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        _progressview.frame = CGRectMake(10, 40, SCREEN_HEIGHT-40-20, 30);

    }else {
        _progressview.frame = CGRectMake(10, 40, SCREEN_WIDTH-40-20, 30);
    
    }
    
    for (int i = 0; i<3; i++) {
        float w = _progressview.frame.size.width/3.0;
        UILabel *label = [self viewWithTag:100+i];
        if (i) {
            UIView *line = [self viewWithTag:200+i];
            line.frame = CGRectMake(10+w*i, 40, 0.5, 60);
        }
        label.frame = CGRectMake(10+w*i,80,w,20);
    }
    gradientLayer.frame = _progressview.bounds;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _indicatorview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 20, 20)];
        [_indicatorview setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"use_flag" ofType:@"png"]]];
        [self addSubview:_indicatorview];
        
        _progressview = [[UIView alloc] initWithFrame:CGRectMake(10, 40, [UIScreen mainScreen].bounds.size.width-40-20, 30)];
        _progressview.layer.cornerRadius = 15;
        _progressview.layer.masksToBounds = YES;
        [self addSubview:_progressview];
        
        gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.colors = @[(__bridge id)RGBA(20, 220, 20, 1).CGColor,(__bridge id)RGBA(220, 220, 20, 1).CGColor,(__bridge id)RGBA(220, 20, 20, 1).CGColor];
        gradientLayer.startPoint = CGPointMake(0, 1);
        gradientLayer.endPoint = CGPointMake(1, 1);
        gradientLayer.frame = _progressview.bounds;
        [_progressview.layer addSublayer:gradientLayer];
        
        for (int i=0; i<3; i++) {
            float w = _progressview.frame.size.width/3.0;
            UILabel *label = [self getLabelWith:15 :@[@"3个月以内",@"6个月以内",@"6个月以上"][i] :[UIColor whiteColor] :CGRectMake(10+w*i,80,w,20)];
            label.tag = 100+i;
            [self addSubview:label];
            if (i) {
                UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10+w*i, 40, 0.5, 60)];
                line.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
                line.tag = 200+i;
                [self addSubview:line];
            }
        }
        
    }
    return self;
}

//返回一个label
- (UILabel *)getLabelWith:(NSInteger)fontSize :(NSString *)title :(UIColor*)titleColor :(CGRect)lableRect{
    UILabel *lable = [[UILabel alloc] initWithFrame:lableRect];
    lable.font = [UIFont systemFontOfSize:fontSize];//Light
    lable.text = title;
    lable.textColor = titleColor;
    lable.textAlignment = NSTextAlignmentCenter;
    lable.backgroundColor = [UIColor clearColor];
    return lable;
}

- (void)setProgressWithValue:(CGFloat)percent {
    NSLog(@"setProgressWithValue");
    [UIView animateWithDuration:0.5 animations:^{
        CGRect rect = _indicatorview.frame;
        rect.origin.x = _progressview.frame.size.width*percent;
        if ((rect.origin.x<7.5)||(rect.origin.x>_progressview.frame.size.width-7.5)) {
            rect.origin.y += (7.5-rect.origin.x);
            if (rect.origin.y>27.5) {
                rect.origin.y = 27.5;
            }
        }else {
            rect.origin.y = 20;
        }
        _indicatorview.frame = rect;
    }];
}

@end
