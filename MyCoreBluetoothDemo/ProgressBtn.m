//
//  ProgressBtn.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/29.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "ProgressBtn.h"
#import "SVProgressHUD.h"

@interface ProgressBtn ()
@property (nonatomic, strong) UIView *progressView;
@end

@implementation ProgressBtn

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 36)];
        _progressView.backgroundColor = [UIColor colorWithRed:45/255.0 green:174/255.0 blue:81/255.0 alpha:0.8];
        _progressView.layer.borderWidth = 0.5;
        _progressView.layer.borderColor = [UIColor greenColor].CGColor;
        [self addSubview:_progressView];
    }
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    self.layer.borderWidth = 1.0;
    return self;
}

- (void)setSelected {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.3 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _progressView.frame = CGRectMake(0, 0, self.bounds.size.width, 36);
    } completion:nil];
    
}

- (void)setProgressWithPercent:(CGFloat)percent {
    if (percent>=1.0) {
        [SVProgressHUD showSuccessWithStatus:@"同步成功"];
    }
    float width = self.bounds.size.width*percent;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _progressView.frame = CGRectMake(0, 0, width, 36);
    } completion:^(BOOL finished) {
        if (percent>=1.0) {
            [self setTitle:@"同步云端数据" forState:UIControlStateNormal];
            [UIView animateWithDuration:0.3 animations:^{
                _progressView.alpha = 0.0;
            } completion:^(BOOL finished) {
                _progressView.alpha = 1.0;
                _progressView.frame = CGRectMake(0, 0, 0, 36);
            }];
        }
    }];
}

@end
