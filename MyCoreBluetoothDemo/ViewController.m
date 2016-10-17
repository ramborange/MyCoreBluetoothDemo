//
//  ViewController.m
//  MyCoreBluetoothDemo
//
//  Created by ljf on 16/5/20.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "AirView.h"
#import "DataRequest.h"
#import "BlueToothData.h"
#import "BTDataModel.h"
#import "DataSaveHelper.h"
#import "DataRequest.h"
#import "HistoryDataViewController.h"
#import "CAButton.h"
#import "ShareOnce.h"
//#import <SAMKeychain.h>

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define SCREEN_WIDTH    self.view.bounds.size.width
#define SCREEN_HEIGHT   self.view.bounds.size.height

#define GROUP_ID        @"group.com.hanwang.MyCoreBluetoothDemo"

#define MY_DEVICE       @"Hanvon"
#define SERVICE_ID      @"FF12"
#define PM25_CHAR       @"FF02"

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic *pm25Char;
    
    float testPmvalue;
}
@property (nonatomic, strong) CAButton *historyBtn;//进入历史界面按钮

//pm2.5显示的主视图
@property (nonatomic, strong) AirView *airview;

//通知的json
@property (nonatomic, strong) NSMutableDictionary *notifyDic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor blackColor];
    //蓝牙检测到的PM2.5数据
    _notifyDic = [NSMutableDictionary dictionary];
    
    //实时界面
    _airview = [[AirView alloc] initWithFrame:self.view.bounds];
    _airview.backgroundColor = RGBA(2, 123, 216, 1);
    [self.view addSubview:_airview];
   
    //同步历史数据按钮
    _historyBtn = [CAButton buttonWithType:UIButtonTypeCustom];
    _historyBtn.frame = CGRectMake(SCREEN_WIDTH/2-100, SCREEN_HEIGHT-60, 200, 40);
    [_historyBtn setTitle:@"同步历史数据" forState:UIControlStateNormal];
    _historyBtn.layer.cornerRadius = 20;
    _historyBtn.layer.masksToBounds = YES;
    [_historyBtn addTarget:self action:@selector(synHistoryData:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_historyBtn];
    
    testPmvalue = 14.7;
    //测试通道
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(testData) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
//    [SAMKeychain deletePasswordForService:@"time" account:@"strainer"];
}

//同步历史数据
- (void)synHistoryData:(CAButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"同步历史数据"]) {
        //开始同步历史数据
        [btn btnStartAnimtion];
        [self performSelector:@selector(finishedSync) withObject:nil afterDelay:2.0];
        
    }else {
        //进入历史记录界面
        [SVProgressHUD dismiss];
        NSArray *dataArray = [[DataSaveHelper sharedDataSaveHelper] getAllDatas];
        if (dataArray!=nil) {
            [ShareOnce getShareOnce].dataArray = dataArray;
            HistoryDataViewController *vc = [[HistoryDataViewController alloc] init];
            [self presentViewController:vc animated:YES completion:nil];
        }else {
            [SVProgressHUD showInfoWithStatus:@"无历史记录"];
        }
    }
    
}

- (void)finishedSync {
    [_historyBtn finishedTask];
}

- (void)testData {
    testPmvalue += (arc4random()%10/10.0);
    
    BlueToothData *data = [[BlueToothData alloc] init];
    data.pm25Value = testPmvalue;
    data.dataType = @"pm2.5";
    data.timeStamp = [[NSDate date] timeIntervalSince1970];;
    [[DataSaveHelper sharedDataSaveHelper] addData:data];
    
    [_airview reloadDataWithValue:data];
    
}

//屏幕发生旋转会调用
- (void)viewDidLayoutSubviews {
    _airview.frame = self.view.bounds;
    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        _historyBtn.hidden = YES;
    }else {
        _historyBtn.hidden = NO;
    }
}


#pragma mark - 屏幕发生旋转
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //重新绘制airview里的内容
    if (_airview.ballView!=nil) {
        [_airview.ballView removeFromSuperview];
        _airview.ballView = nil;
    }
    _historyBtn.frame = CGRectMake(SCREEN_WIDTH/2-100, SCREEN_HEIGHT-60, 200, 40);

    if (SCREEN_WIDTH>SCREEN_HEIGHT) {
        //横屏
        _airview.ballView = [[BallView alloc] initWithFrame:CGRectMake(_airview.bounds.size.width/2-(_airview.bounds.size.height/2-30)-8, _airview.bounds.size.height/2-8, _airview.bounds.size.height-44, 16)];
        [_airview addSubview:_airview.ballView];
    }else {
        _airview.ballView = [[BallView alloc] initWithFrame:CGRectMake(22, _airview.bounds.size.height/2-8, _airview.bounds.size.width-44, 16)];
        [_airview addSubview:_airview.ballView];
        
    }
    [_airview setNeedsDisplay];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_centreManager!=nil) {
        if (_centreManager.isScanning) {
            [SVProgressHUD showWithStatus:@"搜索设备中"];
        }
    }
   
    CGFloat window_width = [UIScreen mainScreen].bounds.size.width;
    CGFloat window_height = [UIScreen mainScreen].bounds.size.height;
    
    _airview.frame = CGRectMake(0, 0, window_width, window_height);
    //重新绘制airview里的内容
    if (_airview.ballView!=nil) {
        [_airview.ballView removeFromSuperview];
        _airview.ballView = nil;
    }
    _historyBtn.frame = CGRectMake(window_width/2-100, window_height-60, 200, 40);
    
    if (window_width>window_height) {
        //横屏
        _historyBtn.hidden = YES;
        _airview.ballView = [[BallView alloc] initWithFrame:CGRectMake(_airview.bounds.size.width/2-(_airview.bounds.size.height/2-30)-8, _airview.bounds.size.height/2-8, _airview.bounds.size.height-44, 16)];
        [_airview addSubview:_airview.ballView];
    }else {
        _historyBtn.hidden = NO;
        _airview.ballView = [[BallView alloc] initWithFrame:CGRectMake(22, _airview.bounds.size.height/2-8, _airview.bounds.size.width-44, 16)];
        [_airview addSubview:_airview.ballView];
        
    }
    [_airview setNeedsDisplay];
    
}

#pragma mark - 连接BlueNRG设备
- (void)connectBlueNRGDeviceWithPeripheral:(CBPeripheral *)peripheral {
    //连接某个外设
    [_centreManager connectPeripheral:peripheral options:nil];
    peripheral.delegate = self;
}

#pragma mark -cbcentralmanager delegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    //保存扫描到的外围设备
    //判断当前数组中不包含扫描到的此设备才保存
    NSLog(@"查找设备");
    if (peripheral.name!=NULL) {
        NSString *peripheralName = [[NSString alloc] initWithString:peripheral.name];
        if ([peripheralName containsString:MY_DEVICE]) {
            //找到了我们需要的外设
            _peripheral = peripheral;
            [SVProgressHUD showWithStatus:@"发现设备，连接中"];
            [self connectBlueNRGDeviceWithPeripheral:peripheral];
        }
    }
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
//    NSLog(@"did Update state");
    //检测代理方法
    if (central.state == CBCentralManagerStatePoweredOn) {
        [_centreManager scanForPeripheralsWithServices:nil options:nil];
//        NSLog(@"手机蓝牙处于可用状态");
        [SVProgressHUD showWithStatus:@"搜索设备中"];
        [_centreManager scanForPeripheralsWithServices:nil options:nil];
    }
    if (central.state==CBCentralManagerStatePoweredOff) {
        [SVProgressHUD showInfoWithStatus:@"请打开手机蓝牙"];
        [self disconnectBleDevice];
    }
    if (central.state==CBCentralManagerStateUnsupported) {
        [SVProgressHUD showInfoWithStatus:@"设备不受支持"];
        [self disconnectBleDevice];
    }
//    NSLog(@"state:%ld central:%@",central.state,central);
}

//连接外部设备成功调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [SVProgressHUD showSuccessWithStatus:@"已连接上设备"];
    //连接上了设备
    
    //停止扫描
    [central stopScan];

    //扫描外设中的服务
    [peripheral discoverServices:nil];
    
}

//连接外设失败调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接失败");
    [SVProgressHUD showInfoWithStatus:@"连接断开,请靠近蓝牙设备"];
    //自动重连

    [self performSelector:@selector(connectMyBleDevice) withObject:nil afterDelay:1.5];
//    if (_peripheral!=nil) {
//        [_centreManager connectPeripheral:_peripheral options:nil];
//    }
}

#pragma mark - CBPeripheral delegate
//服务所在的外设
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"扫描服务");
    //获取从外设中扫描到所有服务
        //拿到需要的服务
        //从需要的服务中查找需要的特征
            //扫描特征
    for (int i=0; i<peripheral.services.count; i++) {
        CBService *service = [peripheral.services objectAtIndex:i];
        if ([service.UUID.UUIDString isEqualToString:SERVICE_ID]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    
}

//只要扫描特征就会调用
//特征所属的外设 特征所属的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"扫描特征");
    //拿到服务中的所有的特征
    if([service.UUID.UUIDString isEqualToString:SERVICE_ID]) {
        for (int i=0; i<service.characteristics.count; i++) {
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
            if ([characteristic.UUID.UUIDString isEqualToString:PM25_CHAR]) {
                pm25Char = characteristic;
            }
        }
        [self scanEnvironment];
    }
}

//读取外设中的数据
-(void)scanEnvironment {
    if (pm25Char!=nil) {
//        [self.peripheral readValueForCharacteristic:pm25Char];
        
        [self.peripheral setNotifyValue:YES forCharacteristic:pm25Char];
    }
}

#pragma mark - 发送消息成功
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"发送消息的回调 error：%@",error);
    if (!error) {
        [SVProgressHUD showSuccessWithStatus:@"发送消息成功"];
    }
}

#pragma mark - 处理蓝牙发送过来的数据
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"接收到数据  value: %@",descriptor.value);
    
}

#pragma mark - 读取蓝牙特征中的数据
- (void)peripheral:(CBPeripheral *)mperipheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic==pm25Char) {
        //NSUInteger bytesToConvert = [characteristic.value length];
        //把接受的数据转化为字节的形式 数据格式为整形
        const unsigned int *uuidBytes = [characteristic.value bytes];
        //去整形的第三位即是pm2.5的值
        unsigned int char3 = uuidBytes[2];
        //数值除以100得到最终的需要的值
        float pm25Value = char3/100.0;
        
        //        NSInteger pm25 = [self littleEndianCharToInt24WithFirst:uuidBytes[0] second:uuidBytes[1] andThird:uuidBytes[2]];
        
        BlueToothData *data = [[BlueToothData alloc] init];
        data.pm25Value = pm25Value;
        data.dataType = @"pm2.5";
        data.timeStamp = [[NSDate date] timeIntervalSince1970];
        [[DataSaveHelper sharedDataSaveHelper] addData:data];
        
        //刷新数据
        [_airview reloadDataWithValue:data];
        
        
        [_notifyDic setObject:@(pm25Value) forKey:@"PM25"];
    }
    
    NSUserDefaults *shared = [[NSUserDefaults standardUserDefaults] initWithSuiteName:GROUP_ID];
    [shared setObject:_notifyDic forKey:@"WidgetData"];
    [shared synchronize];
}



- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
}

#pragma mark - 搜索外设
- (void)searchBleDevice {
    //先停止之前的
    if (_peripheral!=nil) {
        [self disconnectBleDevice];
    }
    
    //设置中心设备 利用中心设备扫描外部设备
    _centreManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionShowPowerAlertKey:@(NO)}];
    
    //如果指定数组 则只扫描数组中设备
//    [SVProgressHUD showWithStatus:@"搜索设备中"];
//    [_centreManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - 停止搜索或者断开连接
- (void)disconnectBleDevice {
    if (_centreManager!=nil) {
//        [_centreManager stopScan];

        if (_peripheral!=nil) {
            [_centreManager cancelPeripheralConnection:_peripheral];
            _peripheral = nil;
        }
        _centreManager.delegate = nil;
        _centreManager = nil;
    }
}


#pragma mark - 导航栏左右按钮点击事件
- (void)connectMyBleDevice {
    //搜索设备
    [self searchBleDevice];
}


- (void)dealloc {
    _peripheral = nil;
    _centreManager = nil;
    _airview = nil;
    NSLog(@"%s",__func__);
}

- (CGRect)buttonFrame{
    return _historyBtn.frame;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
