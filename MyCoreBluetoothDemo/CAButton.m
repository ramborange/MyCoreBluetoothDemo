//
//  CAButton.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/28.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "CAButton.h"

#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

@implementation CAButton

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    if (_isStartSyncAnimation) {
        CGContextAddArc(context, self.bounds.size.width/2, self.bounds.size.height/2, self.bounds.size.height/2-4, 0, M_PI*1.6, 0);
        CGContextDrawPath(context, kCGPathStroke);
    }else {
//        CGContextAddArc(context, self.bounds.size.width/2, self.bounds.size.height/2, self.bounds.size.height/2-4, 0, M_PI*1.6, 0);
        CGContextDrawPath(context, kCGPathStroke);
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:45/255.0 green:174/255.0 blue:81/255.0 alpha:0.8]];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:15];
    }
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    self.layer.borderWidth = 1.0;
    return self;
}

- (void)btnStartAnimtion {
    self.enabled = NO;
    CGRect rect = self.frame;
    CGRect rect2 = CGRectMake(rect.origin.x+rect.size.width/2-rect.size.height/2, rect.origin.y, rect.size.height, rect.size.height);
   
    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        weakSelf.frame = rect2;
    } completion:^(BOOL finished) {
        [self setTitle:nil forState:UIControlStateNormal];
        _isStartSyncAnimation = YES;
        [self setNeedsDisplay];
        [UIView animateWithDuration:0.15 delay:0.0 usingSpringWithDamping:0.3 initialSpringVelocity:10 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            weakSelf.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                weakSelf.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
            weakSelf.isFinshedAnimation = NO;
            [weakSelf startRotation];
        }];
    }];
}

- (void)startRotation {
    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        weakSelf.transform = CGAffineTransformRotate(weakSelf.transform, M_PI);
    } completion:^(BOOL finished) {
        if (!weakSelf.isFinshedAnimation) {
            [weakSelf startRotation];
        }
    }];
}

- (void)finishedTask {
    _isFinshedAnimation = YES;
    _isStartSyncAnimation = NO;
    [self setNeedsDisplay];
    
    self.transform = CGAffineTransformMakeRotation(0);
    [self setTitle:@"查看历史记录" forState:UIControlStateNormal];

    
    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.35 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.frame = CGRectMake(SCREEN_WIDTH/2-100, SCREEN_HEIGHT-60, 200, 40);
    } completion:^(BOOL finished) {
        weakSelf.enabled = YES;
    }];

}

- (void)canceledTask {

}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect bounds = self.bounds;
    //若原热区小于44x44，则放大热区，否则保持原大小不变
    CGFloat widthDelta = MAX(44.0 - bounds.size.width, 0);
    CGFloat heightDelta = MAX(44.0 - bounds.size.height, 0);
    bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
    return CGRectContainsPoint(bounds, point);
}

@end
