//
//  AirView.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/22.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "DataRequest.h"
#import "AirView.h"
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import "StrainerInfoController.h"
#import <SAMKeychain.h>
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SCREEN_WIDTH    self.bounds.size.width
#define SCREEN_HEIGHT   self.bounds.size.height
#define IOS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define weatherKey      @"f57fa7b78b46426d51003c46527e0853"

typedef enum {
    PmLevel1 = 0,
    PmLevel2,
    PmLevel3,
    PmLevel4,
    PmLevel5,
    PmLevel6
}PmLevelState;

static NSDateFormatter *formatter = nil;
@interface AirView ()<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}
@property (nonatomic, strong) UILabel *titleLabel;//标题

@property (nonatomic, strong) UILabel *pmValueLabel;//pm2.5数值显示
@property (nonatomic, strong) UIButton *outsidePmLabel;//户外Pm2.5
@property (nonatomic, strong) UIButton *strainerInfoLabel;//滤网使用时间

@property (nonatomic, strong) UILabel *dateLabel;//日期
@property (nonatomic, strong) UILabel *pmDescLabel;//污染描述

@end


@implementation AirView
-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [self getLabelWith:24 :@"车载PM2.5监测" :[UIColor whiteColor] :CGRectZero :0];
        [self addSubview:_titleLabel];
        
        _outsidePmLabel = [self getBtnWith:18 :@"" :[UIColor whiteColor]];
        [self addSubview:_outsidePmLabel];
        
        _strainerInfoLabel = [self getBtnWith:18 :@"" :[UIColor whiteColor]];
        [_strainerInfoLabel addTarget:self action:@selector(strainerInfoClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_strainerInfoLabel];
        
        _pmValueLabel = [self getLabelWith:36 :@"" :[UIColor whiteColor] :CGRectZero :0];
        [self addSubview:_pmValueLabel];
        
        _dateLabel = [self getLabelWith:15 :@"" :[UIColor whiteColor] :CGRectZero :0];
        [self addSubview:_dateLabel];
        
        _pmDescLabel = [self getLabelWith:20 :@"" :[UIColor whiteColor] :CGRectZero :0];
        [self addSubview:_pmDescLabel];
        
        _ballView = [[BallView alloc] initWithFrame:CGRectMake(22, SCREEN_HEIGHT/2-8, SCREEN_WIDTH-44, 16)];
//        _ballView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
        [self addSubview:_ballView];
        
    }
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = 1000;
    locationManager.desiredAccuracy = 1000;
    if (IOS_8_OR_LATER) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    return self;
}

- (void)strainerInfoClicked {
//    NSLog(@"strainerInfoClicked");
    ViewController *vc = [(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController];
    StrainerInfoController *strainerVc = [[StrainerInfoController alloc] init];
    [vc presentViewController:strainerVc animated:YES completion:nil];
}

#pragma mark - CLLocationManager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    __weak __typeof(self)weakSelf = self;
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = [placemarks lastObject];
        NSDictionary *adressDic = placemark.addressDictionary;
        NSString *cityName = adressDic[@"City"];
        if (cityName!=nil&&![cityName isEqualToString:@""]) {
            [weakSelf requestOutsidePm25dataWithCityName:cityName];
        }
    }];
}

//刷新数据
- (void)reloadDataWithValue:(BlueToothData *)data {
    _pmValueLabel.attributedText = [self getVariousString:[NSString stringWithFormat:@"%.1fug/m³",data.pm25Value] size1:60 size2:20];
    _pmDescLabel.text = [self getPmDesWithValue:data.pm25Value];
   //小球转动
    if (data.pm25Value>999) {
        data.pm25Value = 999.99;
    }
    if (_ballView!=nil) {
        float angel = [self getAngleWithPmValue:data.pm25Value];
        [UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
            _ballView.transform = CGAffineTransformMakeRotation(angel);
        } completion:nil];
                
        //小球爆表
        if (data.pm25Value>=250) {
            [_ballView ballAlarm];
        }else {
            [_ballView setBallColor:[UIColor whiteColor]];
        }
    }
    
    _dateLabel.text = [self getDateStringWithTimeInterval:data.timeStamp];
}


- (NSDateFormatter *)getDateFormatter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (formatter==nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        }
    });
    
    return formatter;
}

- (NSString *)getDateStringWithTimeInterval:(double)timeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *dateFormatter = [self getDateFormatter];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

//返回一个label
- (UILabel *)getLabelWith:(NSInteger)fontSize :(NSString *)title :(UIColor*)titleColor :(CGRect)lableRect :(NSInteger)lines{
    UILabel *lable = [[UILabel alloc] initWithFrame:lableRect];
    lable.font = [UIFont systemFontOfSize:fontSize];//Light
    if (title!=nil) {
        lable.text = title;
    }
    lable.textColor = titleColor;
    lable.numberOfLines = lines;
    lable.textAlignment = NSTextAlignmentCenter;
    lable.backgroundColor = [UIColor clearColor];
    return lable;
}

//返回一个button
- (UIButton *)getBtnWith:(NSInteger)fontSize :(NSString *)title :(UIColor *)titleColor {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [btn setTitleColor:titleColor forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    return btn;
}

- (void)layoutSubviews {
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {//横向
        _titleLabel.hidden = YES;
        _outsidePmLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH/2-(SCREEN_HEIGHT/2-20), SCREEN_HEIGHT);
        _strainerInfoLabel.frame = CGRectMake(SCREEN_WIDTH/2+(SCREEN_HEIGHT/2-20), 0, SCREEN_WIDTH/2-(SCREEN_HEIGHT/2-20), SCREEN_HEIGHT);
        _pmValueLabel.frame = CGRectMake(80, (SCREEN_HEIGHT-100)/2, SCREEN_WIDTH-160, 100);
        _dateLabel.frame = CGRectMake(100, 60, SCREEN_WIDTH-200, (SCREEN_HEIGHT-60)/2-60);
        _pmDescLabel.frame = CGRectMake(SCREEN_WIDTH/2-60, SCREEN_HEIGHT/2+(SCREEN_HEIGHT-120)/4-15, 120, 30);
    }else {//纵向
        _titleLabel.hidden = NO;
        _titleLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT/2-(SCREEN_WIDTH/2-30));
        _outsidePmLabel.frame = CGRectMake(0, SCREEN_HEIGHT/2+SCREEN_WIDTH/2-30, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-SCREEN_WIDTH/2-30);
        _strainerInfoLabel.frame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2+SCREEN_WIDTH/2-30, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-SCREEN_WIDTH/2-30);
        _pmValueLabel.frame = CGRectMake(40, (SCREEN_HEIGHT-100)/2, SCREEN_WIDTH-80, 100);
        _dateLabel.frame = CGRectMake(50, SCREEN_HEIGHT/2-(SCREEN_WIDTH/2-30), SCREEN_WIDTH-100, (SCREEN_HEIGHT-60)/2-(SCREEN_HEIGHT/2-(SCREEN_WIDTH/2-30)));
        _pmDescLabel.frame = CGRectMake(SCREEN_WIDTH/2-60, SCREEN_HEIGHT/2+(SCREEN_WIDTH/2-30)/2-15, 120, 30);
    }

//    [_outsidePmLabel setAttributedTitle:[self getVariousString:[NSString stringWithFormat:@"户外：%d ug/m³",103] size1:18 size2:12] forState:UIControlStateNormal];
    [_strainerInfoLabel setAttributedTitle:[self getStrainerString] forState:UIControlStateNormal];
}

- (NSInteger)getStrainerUseDays {
    NSString *pw = [SAMKeychain passwordForService:@"time" account:@"strainer"];
    if (pw==nil) {
        return -1;
    }else {
        NSTimeInterval date = pw.doubleValue;
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970] - date;
        NSInteger days = now/(24*60*60);
        return days;
    }
}

- (NSMutableAttributedString *)getStrainerString {
    NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString:@"滤网状态 ："];
    NSTextAttachment *attch = [[NSTextAttachment alloc] init];
    NSInteger useDays = [self getStrainerUseDays];
    if (useDays<0) {
        attch.image = [UIImage imageNamed:@"lw_state0"];
    }else {
        if (useDays<=30) {
            attch.image = [UIImage imageNamed:@"lw_state1"];
        }else if (useDays>30&&useDays<=60) {
            attch.image = [UIImage imageNamed:@"lw_state2"];
        }else {
            attch.image = [UIImage imageNamed:@"lw_state3"];
        }
    }
    attch.bounds = CGRectMake(0, -3, 20, 20);
    // 创建带有图片的富文本
    NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:attch];
    [attri appendAttributedString:string];
    [attri addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],NSForegroundColorAttributeName:[UIColor whiteColor]} range:NSMakeRange(0, [attri.string length])];
    
    return attri;
}

//请求户外数据
- (void)requestOutsidePm25dataWithCityName:(NSString *)cityName {
    [DataRequest getDataUseGetUrl:[NSString stringWithFormat:@"http://op.juhe.cn/onebox/weather/query?cityname=%@&key=%@",cityName,weatherKey] type:@"outsideData" finished:^(id obj, NSString *type, NSError *error) {
        if (!error) {
//            NSLog(@"%@",obj);
            NSDictionary *responseDic = (NSDictionary *)obj;
            if ([responseDic[@"reason"] isEqualToString:@"successed!"]) {
                NSDictionary *pm25Dic = responseDic[@"result"][@"data"][@"pm25"];
                NSInteger pm25Value = [pm25Dic[@"pm25"][@"curPm"] integerValue];
                [_outsidePmLabel setAttributedTitle:[self getVariousString:[NSString stringWithFormat:@"户外：%ld ug/m³",pm25Value] size1:18 size2:12] forState:UIControlStateNormal];
            }
        }
    }];
}

//一个字符串中不同的字体样式
- (NSMutableAttributedString *)getVariousString:(NSString *)textString size1:(CGFloat)size1 size2:(CGFloat)size2 {
    NSInteger unitLength = [@"ug/m³" length];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:textString];
    [str addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:size1] range:NSMakeRange(0,textString.length-unitLength)];
    [str addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:size2] range:NSMakeRange(textString.length-unitLength,unitLength)];
    [str addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} range:NSMakeRange(0, [textString length])];
    return str;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
//    CGContextSetLineCap(context, kCGLineCapRound);
//    CGFloat lengths[] = {1,5};
//    CGContextSetLineDash(context, 1.0, lengths, 2);
    
    
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        CGContextSetLineWidth(context, 1.0);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-45, 0, M_PI*2, 0);
        CGContextDrawPath(context, kCGPathStroke);
        
        CGContextSetLineWidth(context, 20.0);
        //优
        CGContextSetStrokeColorWithColor(context, RGBA(61, 196, 84, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI, M_PI+M_PI*2*(1/6.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //良
        CGContextSetStrokeColorWithColor(context, RGBA(255, 222, 41, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI+M_PI*2*(1/6.0),M_PI+M_PI*2*(1/3.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //轻度
        CGContextSetStrokeColorWithColor(context, RGBA(255, 150, 57, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI+M_PI*2*(1/3.0), M_PI+M_PI, 0);
        CGContextDrawPath(context, kCGPathStroke);
        //中度
        CGContextSetStrokeColorWithColor(context, RGBA(255, 86, 58, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI+M_PI, M_PI+M_PI*2*(2/3.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //重度
        CGContextSetStrokeColorWithColor(context, RGBA(175, 96, 179, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI+M_PI*2*(2/3.0), M_PI+M_PI*2*(5/6.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //严重
        CGContextSetStrokeColorWithColor(context, RGBA(102, 80, 22, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_HEIGHT/2-30, M_PI+M_PI*2*(5/6.0), M_PI+M_PI*2, 0);
        CGContextDrawPath(context, kCGPathStroke);
        

    }else {
        CGContextSetLineWidth(context, 1.0);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-45, 0, M_PI*2, 0);
        CGContextDrawPath(context, kCGPathStroke);
        
        CGContextSetLineWidth(context, 20.0);
        //优
        CGContextSetStrokeColorWithColor(context, RGBA(61, 196, 84, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI, M_PI+M_PI*2*(1/6.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //良
        CGContextSetStrokeColorWithColor(context, RGBA(255, 222, 41, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI+M_PI*2*(1/6.0), M_PI+M_PI*2*(1/3.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //轻度
        CGContextSetStrokeColorWithColor(context, RGBA(255, 150, 57, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI+M_PI*2*(1/3.0), M_PI+M_PI, 0);
        CGContextDrawPath(context, kCGPathStroke);
        //中度
        CGContextSetStrokeColorWithColor(context, RGBA(255, 86, 58, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI+M_PI, M_PI+M_PI*2*(2/3.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //重度
        CGContextSetStrokeColorWithColor(context, RGBA(175, 96, 179, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI+M_PI*2*(2/3.0), M_PI+M_PI*2*(5/6.0), 0);
        CGContextDrawPath(context, kCGPathStroke);
        //严重
        CGContextSetStrokeColorWithColor(context, RGBA(102, 80, 22, 1).CGColor);
        CGContextAddArc(context, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2-30, M_PI+M_PI*2*(5/6.0), M_PI+M_PI*2, 0);
        CGContextDrawPath(context, kCGPathStroke);
    }
}

#pragma mark - 根部不同pm2.5数值大小获取不同颜色
- (UIColor *)getPmColorWithValue:(CGFloat)value {
    if (value<=35) {
        return RGBA(61, 196, 84, 1);
    }else if (value<=75){
        return RGBA(255, 222, 41, 1);
    }else if (value<=115){
        return RGBA(255, 150, 57, 1);
    }else if (value<=150){
        return RGBA(255, 86, 58, 1);
    }else if (value<=250){
        return RGBA(175, 96, 179, 1);
    }else{
        return RGBA(102, 80, 22, 1);
    }
}

#pragma mark -PM当前等级
-(NSInteger)getPMLevelWithValue:(CGFloat)value {
    if (value<=35) {
        return PmLevel1;
    }else if (value<=75){
        return PmLevel2;
    }else if (value<=115){
        return PmLevel3;
    }else if (value<=150){
        return PmLevel4;
    }else if (value<=250){
        return PmLevel5;
    }else{
        return PmLevel6;
    }
}

- (CGFloat)getAngleWithPmValue:(CGFloat)value {
    NSInteger currentLevel = [self getPMLevelWithValue:value];
    float angel = M_PI*2*(currentLevel/6.0);
    if (value<=35) {
        return angel+=((value/35.0)*(M_PI/3));
    }else if (value<=75){
        return angel+=(((value-35)/40.0)*(M_PI/3));
    }else if (value<=115){
        return angel+=(((value-75)/40.0)*(M_PI/3));
    }else if (value<=150){
        return angel+=(((value-115)/35.0)*(M_PI/3));
    }else if (value<=250){
        return angel+=(((value-150)/100.0)*(M_PI/3));
    }else{
        return angel+=(((value-250)/750)*(M_PI/3));
    }
}

#pragma mark - 得到PM2.5的不同描述
- (NSString *)getPmDesWithValue:(CGFloat)value {
    if (value<=35) {
        return @"空气优";
    }else if (value<=75){
        return @"空气良";
    }else if (value<=115){
        return @"轻度污染";
    }else if (value<=150){
        return @"中度污染";
    }else if (value<=250){
        return @"重度污染";
    }else{
        return @"严重污染";
    }
}

-(void)dealloc {
    _titleLabel = nil;
    _strainerInfoLabel = nil;
    _outsidePmLabel = nil;
    _dateLabel = nil;
    _pmValueLabel = nil;
    _pmDescLabel = nil;
    
}


@end
