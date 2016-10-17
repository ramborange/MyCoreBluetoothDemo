//
//  BallView.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/24.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "BallView.h"

@interface BallView ()

@property (nonatomic, strong) UIView *indicatorView;
@end

@implementation BallView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _indicatorView.layer.cornerRadius = 8;
        _indicatorView.layer.masksToBounds = YES;
        _indicatorView.layer.borderWidth = 1.0;
        _indicatorView.backgroundColor = [UIColor whiteColor];
        _indicatorView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        [self addSubview:_indicatorView];
    }
    return self;
}


- (void)setBallColor:(UIColor *)color {
    _indicatorView.backgroundColor = color;
}

- (void)ballAlarm {
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _indicatorView.backgroundColor = [UIColor redColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            _indicatorView.backgroundColor = [UIColor whiteColor];
        } completion:nil];
    }];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
