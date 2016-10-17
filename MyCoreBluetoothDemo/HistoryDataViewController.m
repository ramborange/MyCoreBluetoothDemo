//
//  HistoryDataViewController.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/28.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "HistoryDataViewController.h"
#import "HistoryDataViewCell.h"
#import "ProgressBtn.h"
#import "SVProgressHUD.h"

#import "XWCircleSpreadTransition.h"

#import "BlueToothData.h"
#import "BTDataModel.h"
#import "DataSaveHelper.h"

#import "ShareOnce.h"

#import "DatePickerView.h"

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SCREEN_WIDTH    self.view.bounds.size.width
#define SCREEN_HEIGHT   self.view.bounds.size.height

static NSDateFormatter *formatter = nil;
@interface HistoryDataViewController () <UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIViewControllerTransitioningDelegate>

{
    float percent;
    BOOL isScreenRotating;
}
//历史记录
@property (nonatomic, strong) UICollectionView *collectionview;

@property (nonatomic, assign) NSInteger currentRow;//当前显示的点

@property (nonatomic, strong) DatePickerView *datePickerview;//时间选择
@end

@implementation HistoryDataViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}
//返回一个按钮
- (UIButton *)getBtnWithFrame:(CGRect)rect {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    btn.layer.cornerRadius = rect.size.height/2.0;
    btn.layer.masksToBounds = YES;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:18];
    btn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    btn.layer.borderWidth = 1.0;
    return btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = RGBA(64, 144, 200, 1);
    
    //返回
    UIButton *backBtn = [self getBtnWithFrame:CGRectMake(SCREEN_WIDTH/4-60, SCREEN_HEIGHT-60, 120, 36) title:@"返回实时检测"];
    [backBtn addTarget:self action:@selector(backPreView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    //同步云端历史数据
    ProgressBtn *uploadBtn = [self getBtnWithFrame:CGRectMake(SCREEN_WIDTH*3/4-60, SCREEN_HEIGHT-60, 120, 36) title:@"同步云端数据"];
    uploadBtn.tag = 32;
    [uploadBtn addTarget:self action:@selector(uploadBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:uploadBtn];
    
    //更新最大值
    [self updateMaxValue];

    //历史界面曲线图UI
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionview = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT-200) collectionViewLayout:layout];
    _collectionview.delegate = self;
    _collectionview.dataSource = self;
        _collectionview.showsHorizontalScrollIndicator = NO;
    _collectionview.backgroundColor = RGBA(64, 144, 200, 1);
    [self.view addSubview:_collectionview];
    [_collectionview registerClass:[HistoryDataViewCell class] forCellWithReuseIdentifier:@"collectionviewcellid"];
    
    //时间标签
    UILabel *dateLabel = [self getLabelWith:15 :@"" :[UIColor whiteColor] :CGRectMake(0, 110, SCREEN_WIDTH, 20) :0];
    dateLabel.tag = 11;
    [self.view addSubview:dateLabel];
    
    //数值
    UILabel *valueLabel = [self getLabelWith:20 :@"" :[UIColor whiteColor] :CGRectMake(0, 135, SCREEN_WIDTH, 20) :0];
    valueLabel.font = [UIFont boldSystemFontOfSize:20];
    valueLabel.tag = 12;
    [self.view addSubview:valueLabel];
    
    //污染级别
    UILabel *descLabel = [self getLabelWith:15 :@"" :[UIColor whiteColor] :CGRectMake(0, 160, SCREEN_WIDTH, 20) :0];
    descLabel.tag = 13;
    [self.view addSubview:descLabel];
    
    //滚动至最新的数据
    [self scrollChartViewToTop];
    
    
    //时间选择视图
    _datePickerview = [[DatePickerView alloc] initWithFrame:CGRectMake(-1, -200, SCREEN_WIDTH+2, 300)];
    [_datePickerview.cancelBtn addTarget:self action:@selector(dismissDatePickerView) forControlEvents:UIControlEventTouchUpInside];
    [_datePickerview.commitBtn addTarget:self action:@selector(commitNewDate) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_datePickerview];
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    topView.tag = 25;
    topView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:topView];
    
    //时间选择按钮
    UIButton *dateSelectorBtn = [self getBtnWithFrame:CGRectMake(15, 40, SCREEN_WIDTH-30, 40)];
    dateSelectorBtn.tag = 23;
    dateSelectorBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [dateSelectorBtn addTarget:self action:@selector(dateSelectorBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dateSelectorBtn];
    [self updateDateRange];
    
    [_datePickerview setDateScrollView];
    
    percent = 0.0;
    
}

//滚动视图至最右边
- (void)scrollChartViewToTop {
    NSInteger row = [ShareOnce getShareOnce].dataArray.count-1;
    if (row>0) {
        [_collectionview scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
        
        _currentRow = row;
        [self setCurrentPointState];
    }
}

//跟新顶部时间范围
- (void)updateDateRange {
    UIButton *dateSelectorBtn = (UIButton *)[self.view viewWithTag:23];
    NSArray *dataArray = [ShareOnce getShareOnce].dataArray;
    BTDataModel *startDataModel = [dataArray firstObject];
    BTDataModel *endDataModel = [dataArray lastObject];
    [ShareOnce getShareOnce].startTimeInterval = startDataModel.timeStamp.doubleValue;
    [ShareOnce getShareOnce].endTimeInterval = endDataModel.timeStamp.doubleValue;
    NSString *startDateStr = [self getDetailDateStr:[startDataModel timeStamp].doubleValue];
    NSString *endDateStr = [self getDetailDateStr:[endDataModel timeStamp].doubleValue];
    NSString *prefix1 = [[startDateStr componentsSeparatedByString:@"年"] firstObject];
    NSString *prefix2 = [[endDateStr componentsSeparatedByString:@"年"] firstObject];
    if ([prefix1 isEqualToString:prefix2]) {
        [dateSelectorBtn setTitle:[NSString stringWithFormat:@"%@ - %@",[[startDateStr componentsSeparatedByString:@"年"] lastObject],[[endDateStr componentsSeparatedByString:@"年"] lastObject]] forState:UIControlStateNormal];
    }else {
        [dateSelectorBtn setTitle:[NSString stringWithFormat:@"%@ - %@",[[startDateStr componentsSeparatedByString:@" "] firstObject],[[endDateStr componentsSeparatedByString:@" "] firstObject]] forState:UIControlStateNormal];

    }
}

//show datePickerView
- (void)showDatePickerView {
    UIButton *btn = (UIButton *)[self.view viewWithTag:23];
    [btn setSelected:YES];
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerview.frame = CGRectMake(-1, 100, SCREEN_WIDTH+2, 300);
    } completion:nil];
}

// dismiss DatePickerView
- (void)dismissDatePickerView {
    UIButton *btn = (UIButton *)[self.view viewWithTag:23];
    [btn setSelected:NO];
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerview.frame = CGRectMake(-1, -200, MIN(SCREEN_WIDTH, SCREEN_HEIGHT)+2, 300);
    } completion:^(BOOL finished) {
        [_datePickerview resetOrginFrame];
    }];
}

//确定时间段后更新数据源
- (void)commitNewDate {
    if (!_datePickerview.minTimeInterval&&!_datePickerview.maxTimeInterval) {
        [SVProgressHUD showInfoWithStatus:@"未选择时间段"];
        return;
    }
    
    NSArray *dataArray = [[DataSaveHelper sharedDataSaveHelper] getDatasBetweenStartTimeInterval:_datePickerview.minTimeInterval endTimeInterval:_datePickerview.maxTimeInterval];
    
    if (dataArray.count) {
        [self dismissDatePickerView];
        [ShareOnce getShareOnce].dataArray = dataArray;
        [_collectionview reloadData];
        [self scrollChartViewToTop];//滚动到最新的数据
        [self updateDateRange];//更新顶部时间范围
    }else {
        [SVProgressHUD showInfoWithStatus:@"该时间段无数据"];
    }
}

//选择时间间隔
- (void)dateSelectorBtnClicked {
    UIButton *btn = (UIButton *)[self.view viewWithTag:23];
    if (!btn.isSelected) {
        [self showDatePickerView];
    }else  {
        [self dismissDatePickerView];
    }
}

//更新最大值
-(void)updateMaxValue {
    NSArray *datas = [ShareOnce getShareOnce].dataArray;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (BTDataModel *model in datas) {
        [array addObject:model.pm25Value];
    }
    float max = [self getMaxValueWith:array];
    [ShareOnce getShareOnce].maxValue = max;
}

- (CGFloat)getMaxValueWith:(NSArray *)array {
    NSNumber *max = [array valueForKeyPath:@"@max.floatValue"];
    return (max.floatValue)*1.2;
}

//返回一个Button
- (ProgressBtn *)getBtnWithFrame:(CGRect)rect title:(NSString *)title {
    ProgressBtn *btn = [ProgressBtn buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    btn.layer.cornerRadius = rect.size.height/2;
    btn.layer.masksToBounds = YES;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    return btn;
}

//上传历史数据
- (void)uploadBtnClicked {
    ProgressBtn *btn = (ProgressBtn *)[self.view viewWithTag:32];
    if (percent<=1.0) {
        [btn setTitle:@"同步中..." forState:UIControlStateNormal];

        percent+=0.1;
        [btn setProgressWithPercent:percent];
        
        __weak __typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf uploadBtnClicked];
        });
        
    }else {
        percent = 0.0;
    }
}

//返回上一界面
- (void)backPreView:(ProgressBtn *)btn {
    [btn setSelected];
    __weak __typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf back];
    });
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//一个字符串中不同的字体样式
- (NSMutableAttributedString *)getVariousString:(NSString *)textString size1:(CGFloat)size1 size2:(CGFloat)size2 {
    NSInteger unitLength = [@"ug/m³" length];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:textString];
    [str addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:size1] range:NSMakeRange(0,textString.length-unitLength)];
    [str addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:size2] range:NSMakeRange(textString.length-unitLength,unitLength)];
    return str;
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

#pragma mark - UISCrollView Delegate {
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!isScreenRotating) {
        float offsetX = scrollView.contentOffset.x+SCREEN_WIDTH;
        //    NSLog(@"scroll total: %f",offsetX);
        _currentRow = offsetX/(SCREEN_WIDTH/10.0);
        _currentRow-=1;
        
        if (_currentRow<[ShareOnce getShareOnce].dataArray.count) {
            [ShareOnce getShareOnce].currentCellRow = _currentRow;
            
            //确定了当前滚动的row
            [self setCurrentPointState];
        }
    }
}

//设置当前点的状态
- (void)setCurrentPointState {
    [self updateValueInfoWithRow:_currentRow];
    
    HistoryDataViewCell *cell = (HistoryDataViewCell *)[_collectionview cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:0]];
    [cell setNeedsDisplay];
}

//刷新上面的数据信息显示
- (void)updateValueInfoWithRow:(NSInteger)index {
    UILabel *date = (UILabel *)[self.view viewWithTag:11];
    UILabel *value = (UILabel *)[self.view viewWithTag:12];
    UILabel *desc = (UILabel *)[self.view viewWithTag:13];
    
    NSArray *datas = [ShareOnce getShareOnce].dataArray;
    BTDataModel *dataModel = datas[index];
    date.text = [self getDateStringWithTimeInterval:dataModel.timeStamp.doubleValue];
    value.attributedText = [self getVariousString:[NSString stringWithFormat:@"%.1f ug/m³",dataModel.pm25Value.floatValue] size1:20 size2:12];
    desc.text = [self getPmDesWithValue:dataModel.pm25Value.floatValue];
}

- (NSDateFormatter *)getDateFormatter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (formatter==nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        }
    });
    
    return formatter;
}

//根据时间戳得到时间字符串
- (NSString *)getDateStringWithTimeInterval:(double)timeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *dateFormatter = [self getDateFormatter];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

- (NSString *)getDetailDateStr:(double)timeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH点mm分"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}


#pragma mark - 点击某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"click cell: %ld",indexPath.row);
    [ShareOnce getShareOnce].currentCellRow = indexPath.row;
    [self updateValueInfoWithRow:indexPath.row];
    
    HistoryDataViewCell *cell = (HistoryDataViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    [cell setNeedsDisplay];//圆点变大
    
    __weak __typeof(cell)weakCell = cell;
    [UIView animateWithDuration:0.5 animations:^{
        weakCell.lineView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 animations:^{
            weakCell.lineView.alpha = 0.0; 
        }];
    }];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

#pragma mark - UICollectionviewFlowLayout Delegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_collectionview.bounds.size.width/10.0, _collectionview.bounds.size.height);
}

#pragma mark - UICollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[ShareOnce getShareOnce].dataArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HistoryDataViewCell *cell = (HistoryDataViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"collectionviewcellid" forIndexPath:indexPath];
    
    NSArray *datas = [ShareOnce getShareOnce].dataArray;
    BTDataModel *model = datas[indexPath.row];
    cell.backgroundColor = [self getPmColorWithValue:model.pm25Value.floatValue];
    
    cell.tag = indexPath.row+100;
    [cell setNeedsDisplay];
    return cell;
}

- (UIColor *)getPmColorWithValue:(CGFloat)value {
    if (value<=35) {
        return RGBA(61, 196, 84, 0.6);
    }else if (value<=75){
        return RGBA(255, 222, 41, 0.6);
    }else if (value<=115){
        return RGBA(255, 150, 57, 0.6);
    }else if (value<=150){
        return RGBA(255, 86, 58, 0.6);
    }else if (value<=250){
        return RGBA(175, 96, 179, 0.6);
    }else{
        return RGBA(102, 80, 22, 0.6);
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


//屏幕发生旋转会调用
- (void)viewDidLayoutSubviews {
    UIButton *dateSelectorBtn = (UIButton *)[self.view viewWithTag:23];
    UIView *topView = [self.view viewWithTag:25];

    UILabel *date = (UILabel *)[self.view viewWithTag:11];
    UILabel *value = (UILabel *)[self.view viewWithTag:12];
    UILabel *desc = (UILabel *)[self.view viewWithTag:13];
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        dateSelectorBtn.hidden = YES;
        topView.hidden = YES;
        _datePickerview.hidden = YES;
        _collectionview.frame = self.view.bounds;
        date.frame = CGRectMake(0, 10, SCREEN_WIDTH, 20);
        value.frame = CGRectMake(0, 35, SCREEN_WIDTH, 20);
        desc.frame = CGRectMake(0, 60, SCREEN_WIDTH, 20);
    }else {
        dateSelectorBtn.hidden = NO;
        topView.hidden = NO;
        _datePickerview.hidden = NO;
        _collectionview.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT-200);
        date.frame = CGRectMake(0, 110, SCREEN_WIDTH, 20);
        value.frame = CGRectMake(0, 140, SCREEN_WIDTH, 20);
        desc.frame = CGRectMake(0, 165, SCREEN_WIDTH, 20);
    }

    [_collectionview reloadData];
   
    [_collectionview scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    [self setCurrentPointState];
}

//屏幕发生旋转
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissDatePickerView];
    
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        _collectionview.frame = self.view.bounds;
    }else {
        _collectionview.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT-200);
    }
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)_collectionview.collectionViewLayout;
    flow.itemSize = CGSizeMake(_collectionview.bounds.size.width/10.0, _collectionview.bounds.size.height);
    _collectionview.collectionViewLayout = flow;
    [_collectionview.collectionViewLayout invalidateLayout];

    
    isScreenRotating = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    isScreenRotating = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 转场动画代理 UIViewControllerAnimatedTransitioning Delegate1
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [XWCircleSpreadTransition transitionWithTransitionType:XWCircleSpreadTransitionTypePresent];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [XWCircleSpreadTransition transitionWithTransitionType:XWCircleSpreadTransitionTypeDismiss];
}



-(void)dealloc {
    _collectionview.delegate = nil;
    _collectionview.dataSource = nil;
    _collectionview = nil;
    _datePickerview.commitBtn = nil;
    _datePickerview.cancelBtn = nil;
    _datePickerview = nil;
    NSLog(@":%s",__func__);
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
