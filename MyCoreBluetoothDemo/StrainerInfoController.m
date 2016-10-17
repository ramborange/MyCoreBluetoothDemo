//
//  StrainerInfoController.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/10/11.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "StrainerInfoController.h"
#import "SVProgressHUD.h"
#import "StrainerUseTimeView.h"
#import <SAMKeychain.h>
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SCREEN_WIDTH    self.view.bounds.size.width
#define SCREEN_HEIGHT   self.view.bounds.size.height

@interface StrainerInfoController ()<UIAlertViewDelegate>

@property (nonatomic, strong) StrainerUseTimeView *sv;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *resetBtn;
@property (nonatomic, strong) UIButton *backBtn;
@end

@implementation StrainerInfoController
-(void)dealloc {
    _sv = nil;
    _infoLabel = nil;
    _titleLabel = nil;
    _resetBtn = nil;
    _backBtn = nil;
}


- (void)viewDidLayoutSubviews {
//    NSLog(@"viewDidLayoutSubviews");
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {//横向
        _titleLabel.frame = CGRectMake(0, 20, self.view.bounds.size.width, 30);
        _sv.frame = CGRectMake(self.view.bounds.size.width/2-(self.view.bounds.size.height-40)/2, self.view.bounds.size.height/2-60, self.view.bounds.size.height-40, 120);
        _infoLabel.frame = CGRectMake(0, 70, self.view.bounds.size.width, 20);
        _resetBtn.frame = CGRectMake(self.view.bounds.size.width/2+50, self.view.bounds.size.height/2+100, 120, 44);
        _backBtn.frame = CGRectMake(self.view.bounds.size.width/2-160, self.view.bounds.size.height/2+100, 88, 44);
    }else {
        _titleLabel.frame = CGRectMake(0, 80, self.view.bounds.size.width, 30);
        _sv.frame = CGRectMake(20, self.view.bounds.size.height/2-100, self.view.bounds.size.width-40, 120);
        _infoLabel.frame = CGRectMake(0, 140, self.view.bounds.size.width, 20);
        _resetBtn.frame = CGRectMake(self.view.bounds.size.width/2-60, self.view.bounds.size.height/2+120, 120, 44);
        _backBtn.frame = CGRectMake(self.view.bounds.size.width/2-44, self.view.bounds.size.height/2+200, 88, 44);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = RGBA(2, 123, 216, 1);
    
    _titleLabel = [self getLabelWith:24 :@"滤网使用状态" :[UIColor whiteColor] :CGRectMake(0, 80, self.view.bounds.size.width, 30)];
    [self.view addSubview:_titleLabel];
    
    NSString *pw = [SAMKeychain passwordForService:@"time" account:@"strainer"];
    _infoLabel = [self getLabelWith:15 :@"" :[UIColor whiteColor] :CGRectMake(0, 140, self.view.bounds.size.width, 20)];
    [self.view addSubview:_infoLabel];
    if (pw!=nil) {
        _infoLabel.text = [NSString stringWithFormat:@"当前累计使用%ld天",(long)[self getDaysWith:pw]];
    }else {
        _infoLabel.text = @"还未启用滤网";
    }
    
    _sv = [[StrainerUseTimeView alloc] init];
    _sv.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    _sv.layer.cornerRadius = 10;
    _sv.layer.masksToBounds = YES;
    [self.view addSubview:_sv];

    _resetBtn = [self getBtnWithFrame:CGRectMake(self.view.bounds.size.width/2-60, self.view.bounds.size.height/2+120, 120, 44) title:@""];
    if (pw!=nil) {
        [_resetBtn setTitle:@"重置滤网" forState:UIControlStateNormal];
        _resetBtn.backgroundColor = RGBA(222, 79, 10, 1);
        [_resetBtn addTarget:self action:@selector(resetBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }else {
        [_resetBtn setTitle:@"启用滤网" forState:UIControlStateNormal];
        _resetBtn.backgroundColor = RGBA(66, 168, 48, 1);
        [_resetBtn addTarget:self action:@selector(resetBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:_resetBtn];
    
    _backBtn = [self getBtnWithFrame:CGRectMake(self.view.bounds.size.width/2-44, self.view.bounds.size.height/2+200, 88, 44) title:@"返回"];
    _backBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    [_backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(back)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];

    if (pw!=nil) {
        _sv.indicatorview.hidden = NO;
        NSInteger useDays = [self getDaysWith:pw];
        float percent = (float)(useDays/(9*30));
        [_sv setProgressWithValue:percent];
    }else {
        _sv.indicatorview.hidden = YES;
    }
}

- (NSInteger)getDaysWith:(NSString *)timeInterval {
    NSTimeInterval date = timeInterval.doubleValue;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] - date;
    NSInteger days = now/(24*60*60);
    return days;
}

- (void)resetBtnClicked {
    if ([_resetBtn.titleLabel.text isEqualToString:@"重置滤网"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前滤网计时将清零并关闭！" message:@"" delegate:self cancelButtonTitle:@"撤销" otherButtonTitles:@"继续", nil];
        [alert show];
    }else {
        [self setTime];
        [SVProgressHUD showSuccessWithStatus:@"启用成功"];
        _sv.indicatorview.hidden = NO;
        _infoLabel.text = @"当前累计使用0天";
        [_sv setProgressWithValue:0.0];

        [_resetBtn setTitle:@"重置滤网" forState:UIControlStateNormal];
        _resetBtn.backgroundColor = RGBA(222, 79, 10, 1);
    }
}

- (void)setTime {
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
    NSString *dateString = @(date).stringValue;
    [SAMKeychain setPassword:dateString forService:@"time" account:@"strainer"];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex) {
        [self setTime];
        [SVProgressHUD showSuccessWithStatus:@"重置成功"];
        _sv.indicatorview.hidden = YES;
        [_sv setProgressWithValue:0.0];
        _infoLabel.text = @"还未启用滤网";
        [SAMKeychain deletePasswordForService:@"time" account:@"strainer"];
        
        [_resetBtn setTitle:@"启用滤网" forState:UIControlStateNormal];
        _resetBtn.backgroundColor = RGBA(66, 168, 48, 1);
    }
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//返回一个button
- (UIButton *)getBtnWithFrame:(CGRect)rect title:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.layer.cornerRadius = rect.size.height/2.0;
    btn.layer.masksToBounds = YES;
    [btn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [btn.layer setBorderWidth:1.0];
    return btn;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
