//
//  DatePickerView.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/7/4.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "DatePickerView.h"
#import "ShareOnce.h"
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

typedef enum : NSUInteger {
    StartTimeState = 0,
    EndTimeState,
} TimeSelectionState;

@interface DatePickerView ()
{
    NSDateFormatter *dateFormatter;
    NSInteger currentType;
}
@property (nonatomic, strong) UIButton *startTimeBtn;
@property (nonatomic, strong) UIButton *endTimeBtn;

@end

@implementation DatePickerView

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
        _commitBtn = [self getBtnWithFrame:CGRectMake(20, self.bounds.size.height-50, self.bounds.size.width/2-40, 36) title:@"确定"];
        [self addSubview:_commitBtn];
        
        _cancelBtn = [self getBtnWithFrame:CGRectMake(self.bounds.size.width/2+20, self.bounds.size.height-50, self.bounds.size.width/2-40, 36) title:@"取消"];
        [self addSubview:_cancelBtn];
        
        _startTimeBtn = [self getBtnWithFrame:CGRectMake(20, 40, self.bounds.size.width-40, 40) title:@"选择起始时间"];
        [_startTimeBtn addTarget:self action:@selector(startTimeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        _startTimeBtn.layer.cornerRadius = 5;
        _startTimeBtn.layer.masksToBounds = YES;
        [self addSubview:_startTimeBtn];
        
        _endTimeBtn = [self getBtnWithFrame:CGRectMake(20, 120, self.bounds.size.width-40, 40) title:@"选择结束时间"];
        [_endTimeBtn addTarget:self action:@selector(endTimeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        _endTimeBtn.layer.cornerRadius = 5;
        _endTimeBtn.layer.masksToBounds = YES;
        [self addSubview:_endTimeBtn];
        
    }
    self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    self.layer.borderWidth = 1.0;
    self.backgroundColor = RGBA(242, 242, 242, 1);
    return self;
}

- (void)resetOrginFrame {
    _startTimeBtn.frame = CGRectMake(20, 40, self.bounds.size.width-40, 40);
    [_startTimeBtn setTitle:@"选择起始时间" forState:UIControlStateNormal];
    
    _endTimeBtn.frame = CGRectMake(20, 120, self.bounds.size.width-40, 40);
    [_endTimeBtn setTitle:@"选择结束时间" forState:UIControlStateNormal];
    
    _endTimeBtn.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;
    _startTimeBtn.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;

    _maxTimeInterval = 0;
    _minTimeInterval = 0;
    
    _datePicker.frame = CGRectMake(20, 90, self.bounds.size.width-40, 0);
}

//根据时间戳得到时间字符串
- (NSString *)getDateStringWithDate:(NSDate *)date {
    if (dateFormatter==nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    }
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

//开始时间
-(void)startTimeBtnClicked {
    currentType = StartTimeState;
    _datePicker.frame = CGRectMake(20, 50, self.bounds.size.width-40, 150);
    _datePicker.alpha = 0.0;
    
    _startTimeBtn.layer.borderColor = RGBA(180, 180, 180, 1).CGColor;
    _endTimeBtn.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _startTimeBtn.frame = CGRectMake(20, 10, self.bounds.size.width-40, 30);
        _endTimeBtn.frame = CGRectMake(20, 210, self.bounds.size.width-40, 30);
    } completion:^(BOOL finished) {
        _datePicker.alpha = 1.0;
    }];
}

//结束时间
- (void)endTimeBtnClicked {
    currentType = EndTimeState;
    _datePicker.frame = CGRectMake(20, 90, self.bounds.size.width-40, 150);
    _datePicker.alpha = 0.0;
    
    _endTimeBtn.layer.borderColor = RGBA(180, 180, 180, 1).CGColor;
    _startTimeBtn.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _startTimeBtn.frame = CGRectMake(20, 10, self.bounds.size.width-40, 30);
        _endTimeBtn.frame = CGRectMake(20, 50, self.bounds.size.width-40, 30);
    } completion:^(BOOL finished) {
        _datePicker.alpha = 1.0;
    }];
    
}

//时间变化
- (void)dateValueChanged:(UIDatePicker *)datePicker {
//    NSLog(@"%@",datePicker.date);
    if (currentType==StartTimeState) {
        _minTimeInterval = [datePicker.date timeIntervalSince1970];
        [_startTimeBtn setTitle:[self getDateStringWithDate:datePicker.date] forState:UIControlStateNormal];
    }else {
        _maxTimeInterval = [datePicker.date timeIntervalSince1970];
        [_endTimeBtn setTitle:[self getDateStringWithDate:datePicker.date] forState:UIControlStateNormal];
    }
}

- (void)setDateScrollView {
    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(20, 90, self.bounds.size.width-40, 0)];
    _datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:[[ShareOnce getShareOnce] endTimeInterval]];
    _datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:[ShareOnce getShareOnce].startTimeInterval];
    _datePicker.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;
    [_datePicker addTarget:self action:@selector(dateValueChanged:) forControlEvents:UIControlEventValueChanged];
    _datePicker.layer.borderWidth = 1.0;
    [self addSubview:_datePicker];
}

//返回一个按钮
- (UIButton *)getBtnWithFrame:(CGRect)rect title:(NSString *)text{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    [btn setTitleColor:RGBA(120, 120, 120, 1) forState:UIControlStateNormal];
    [btn setTitle:text forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:18];
    btn.layer.cornerRadius = rect.size.height/2.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderColor = RGBA(220, 220, 220, 1).CGColor;
    btn.layer.borderWidth = 1.0;
    btn.backgroundColor = [UIColor whiteColor];
    [btn setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"btn_bg" ofType:@"png"]] forState:UIControlStateHighlighted];

    return btn;
}

- (void)dealloc {
    _datePicker = nil;
    _startTimeBtn = nil;
    _endTimeBtn = nil;
    _commitBtn = nil;
    _cancelBtn = nil;
}

@end
