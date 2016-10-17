//
//  DatePickerView.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/7/4.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DatePickerView : UIView

@property (nonatomic, strong) UIButton *commitBtn;

@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, assign) double maxTimeInterval;
@property (nonatomic, assign) double minTimeInterval;

@property (nonatomic, strong) UIDatePicker *datePicker;


- (void)setDateScrollView;

- (void)resetOrginFrame;
@end
