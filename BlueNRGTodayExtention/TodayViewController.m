//
//  TodayViewController.m
//  BlueNRGTodayExtention
//
//  Created by ljf on 16/5/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#define GROUP_ID   @"group.com.hanwang.MyCoreBluetoothDemo"
#define SCREEN_WIDTH    self.view.bounds.size.width
#define SCREEN_HEIGHT   self.view.bounds.size.height
@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UILabel *pm25Label;
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 100);

    UILabel *pmTitleLabel = [self getLabelWith:40 :@"pm2.5" :[UIColor whiteColor] :CGRectMake(0, 20, SCREEN_WIDTH/2, 60) :1];
    [self.view addSubview:pmTitleLabel];
    
    _pm25Label = [self getLabelWith:40 :@"" :[UIColor whiteColor] :CGRectMake(SCREEN_WIDTH/2, 20, SCREEN_WIDTH/2, 60) :1];
    [self.view addSubview:_pm25Label];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = self.view.bounds;
    [btn addTarget:self action:@selector(enterApp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [self.view.layer setBorderWidth:0.5];
    [self.view.layer setBorderColor:[UIColor colorWithWhite:1.0 alpha:0.6].CGColor];
}

//刷新数据
- (void)updateWidgetData {
    NSUserDefaults *shared = [[NSUserDefaults standardUserDefaults] initWithSuiteName:GROUP_ID];
    NSDictionary *dataDic= [shared objectForKey:@"WidgetData"];

    NSString *textString = [NSString stringWithFormat:@"%.2f ug/m³",[dataDic[@"PM25"] floatValue]];
    NSInteger unitStringLength = [@"ug/m³" length];
    _pm25Label.attributedText = [self getVariousString:textString unitLength:unitStringLength];
    
}

//一个字符串中不同的字体样式
- (NSMutableAttributedString *)getVariousString:(NSString *)textString unitLength:(NSInteger)length{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:textString];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HDZK-GLXLZT-05" size:40] range:NSMakeRange(0,textString.length-length)];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HDZK-GLXLZT-05" size:20] range:NSMakeRange(textString.length-length,length)];
    return str;
}

- (void)enterApp {
    [self.extensionContext openURL:[NSURL URLWithString:@"MyCoreBluetoothDemoWidget://"] completionHandler:^(BOOL success) {
        NSLog(@"open url result:%d",success);
    }];
}

// 一般默认的View是从图标的右边开始的...如果你想变换,就要实现这个方法
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    //UIEdgeInsets newMarginInsets = UIEdgeInsetsMake(defaultMarginInsets.top, defaultMarginInsets.left - 16, defaultMarginInsets.bottom, defaultMarginInsets.right);
    //return newMarginInsets;
    //return UIEdgeInsetsZero; // 完全靠到了左边....
    return UIEdgeInsetsZero;
}

- (UILabel *)getLabelWith:(NSInteger)fontSize :(NSString *)title :(UIColor*)titleColor :(CGRect)lableRect :(NSInteger)lines{
    UILabel *lable = [[UILabel alloc] initWithFrame:lableRect];
    lable.font = [UIFont fontWithName:@"HDZK-GLXLZT-05" size:fontSize];
    lable.text = title;
    lable.textColor = titleColor;
    lable.numberOfLines = lines;
    lable.textAlignment = NSTextAlignmentCenter;
    lable.backgroundColor = [UIColor clearColor];
    return lable;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateWidgetData];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateWidgetData) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    
    [self updateWidgetData];
    completionHandler(NCUpdateResultNewData);
}

@end
