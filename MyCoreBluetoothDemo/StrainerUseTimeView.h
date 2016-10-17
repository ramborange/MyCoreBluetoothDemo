//
//  StrainerUseTimeView.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/10/11.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StrainerUseTimeView : UIView
@property (nonatomic, strong) UIImageView *indicatorview;

- (void)setProgressWithValue:(CGFloat)percent;

@end
