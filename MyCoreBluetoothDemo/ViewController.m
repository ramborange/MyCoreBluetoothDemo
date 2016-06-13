//
//  ViewController.m
//  MyCoreBluetoothDemo
//
//  Created by ljf on 16/5/20.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SVProgressHUD.h"
#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>


#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define SCREEN_WIDTH    self.view.bounds.size.width
#define SCREEN_HEIGHT   self.view.bounds.size.height

#define GROUP_ID                @"group.com.hanwang.MyCoreBluetoothDemo"

#define ST_DEVICE               @"Hanvon"
#define MY_DEVICE               @"BlueNRG"

#define ACCELERATION_SERVICE    "1BC5D5A5-0200-B49A-E111-3ACF806E3602"
#define FREEFALL_CHAR           "1BC5D5A5-0200-FC8F-E111-4ACFA0783EE2"
#define ACCELERATION_CHAR       "1BC5D5A5-0200-36AC-E111-4BCF801B0A34"
#define ENVIRONMENTAL_SERVICE   "1BC5D5A5-0200-D082-E211-77E4401A8242"
#define PM25_CHAR               "1BC5D5A5-0200-0B84-E211-8BE480C420CD"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic *pm25Char;
    
    BOOL acceleration_found;
    BOOL freefall_acceleration;
    
    NSTimer *_timer;//定时器  刷新数据
}
@property (nonatomic, strong) NSMutableArray *peripherals;//外围设备
@property (nonatomic, strong) CBCentralManager *centreManager;//中心管理者
@property (nonatomic, strong) UITableView *tableview;//展示数据
@property (nonatomic, strong) CBPeripheral *peripheral;//外设

@property (nonatomic, strong) UILabel *pm25Label;

//通知的json
@property (nonatomic, strong) NSMutableDictionary *notifyDic;
@end

@implementation ViewController
//懒加载重写getter方法
- (NSMutableArray *)peripherals {
    if (!_peripherals) {
        _peripherals = [NSMutableArray arrayWithCapacity:0];
    }
    return _peripherals;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"未连接设备";
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    _peripherals = [NSMutableArray arrayWithCapacity:0];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"查找设备" style:UIBarButtonItemStylePlain target:self action:@selector(leftBtnItemClicked)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"开始刷新" style:UIBarButtonItemStylePlain target:self action:@selector(rightBtnItemClicked)];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    _tableview = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableview.tableFooterView = [[UIView alloc] init];
    _tableview.delegate = self;
    _tableview.dataSource = self;
//    [self.view addSubview:_tableview];

    //蓝牙检测到的PM2.5数据
    _pm25Label = [self getLabelWith:100 :@"" :[UIColor darkGrayColor] :CGRectMake(0, SCREEN_HEIGHT/2-60, SCREEN_WIDTH, 120) :0];
    [self.view addSubview:_pm25Label];
    
    _notifyDic = [NSMutableDictionary dictionary];

    //开始连接BlueNRG 设备
    [self leftBtnItemClicked];
    
}

//返回一个label
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

#pragma mark - 从特征中读取数据
- (void)rightBtnItemClicked {
    //读取数据 如果当前外设非空 则开始刷新读取设备的数据
    if (_peripheral!=nil) {
        if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"开始刷新"]) {
            if (_timer!=nil) {
                [_timer invalidate];
                _timer = nil;
            }
            _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanEnvironment) userInfo:nil repeats:YES];
            [_timer fire];
            [self.navigationItem.rightBarButtonItem setTitle:@"停止刷新"];
        }else {
            [_timer invalidate];
            _timer = nil;
            [self.navigationItem.rightBarButtonItem setTitle:@"开始刷新"];
        }
    }else {
        [SVProgressHUD showErrorWithStatus:@"无设备连接"];
        [self.navigationItem.leftBarButtonItem setTitle:@"查找设备"];
    }
}

#pragma mark - tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    CBPeripheral *peripheral = _peripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}

#pragma mark - 连接BlueNRG设备
- (void)connectBlueNRGDeviceWithPeripheral:(CBPeripheral *)peripheral {
    //连接某个外设
    [_centreManager connectPeripheral:peripheral options:nil];
    peripheral.delegate = self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _peripheral = _peripherals[indexPath.row];
    [SVProgressHUD showWithStatus:@"连接中"];
    //tableview 点击某个外设 并连接
    [_centreManager connectPeripheral:_peripheral options:nil];
    _peripheral.delegate = self;
    
    [_tableview deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -cbcentralmanager delegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    //保存扫描到的外围设备
    //判断当前数组中不包含扫描到的此设备才保存
    NSLog(@"查找设备");
    if (![_peripherals containsObject:peripheral]) {
        if (peripheral.name!=NULL) {
            [_peripherals addObject:peripheral];
            NSString *peripheralName = [[NSString alloc] initWithString:peripheral.name];
            if ([peripheralName containsString:ST_DEVICE]||[peripheralName containsString:MY_DEVICE]) {
                [SVProgressHUD showSuccessWithStatus:@"已发现BlueNRG设备"];
                _peripheral = peripheral;
                [SVProgressHUD showWithStatus:@"发现设备，连接中"];
                [self connectBlueNRGDeviceWithPeripheral:peripheral];
            }
        }
    }
    
    [_tableview reloadData];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"did Update state");
    //检测代理方法
    if (central.state == UIGestureRecognizerStateFailed) {
        [_centreManager scanForPeripheralsWithServices:nil options:nil];
        NSLog(@"手机蓝牙处于可用状态");
    }
    NSLog(@"state:%ld central:%@",central.state,central);
}

//连接外部设备成功调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [SVProgressHUD dismiss];
    self.navigationItem.title = [NSString stringWithFormat:@"已连接【%@】",_peripheral.name];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    //停止扫描
    [central stopScan];

    //扫描外设中的服务
    [peripheral discoverServices:nil];
    
}

//连接外设失败调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接失败");
    //自动重连
    [_centreManager connectPeripheral:_peripheral options:nil];
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
        if ([[self representativeString:service.UUID] isEqualToString:[NSString stringWithUTF8String:ACCELERATION_SERVICE]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        } else if ([[self representativeString:service.UUID] isEqualToString:[NSString stringWithUTF8String:ENVIRONMENTAL_SERVICE]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    
}

//只要扫描特征就会调用
//特征所属的外设 特征所属的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"扫描特征");
    //拿到服务中的所有的特征
    if ([[self representativeString:service.UUID] isEqualToString:[NSString stringWithUTF8String:ACCELERATION_SERVICE]]) {
        for (int i=0; i<service.characteristics.count; i++) {
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
            if ([[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:ACCELERATION_CHAR]] ||
                [[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:FREEFALL_CHAR]]) {
                if ([[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:ACCELERATION_CHAR]]) {
                    acceleration_found = YES;
                } else if ([[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:FREEFALL_CHAR]]) {
                    freefall_acceleration = YES;
                }
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    } else if ([[self representativeString:service.UUID] isEqualToString:[NSString stringWithUTF8String:ENVIRONMENTAL_SERVICE]]) {
        for (int i=0; i<service.characteristics.count; i++) {
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
            if ([[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:PM25_CHAR]]) {
               
                if ([[self representativeString:characteristic.UUID] isEqualToString:[NSString stringWithUTF8String:PM25_CHAR]]) {
                    pm25Char = characteristic;
                }
            }
        }
        [self rightBtnItemClicked];
    }
}

//读取外设中的数据
-(void)scanEnvironment {
    if (pm25Char!=nil) {
        [self.peripheral readValueForCharacteristic:pm25Char];
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


#pragma mark - 解析数据---------------------
- (NSString *)representativeString:(CBUUID*)uuid
{
    NSData *data = [uuid data];
    
    NSUInteger bytesToConvert = [data length];
    
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSInteger currentByteIndex = bytesToConvert-1; currentByteIndex >= 0; currentByteIndex--)
    {
        switch (currentByteIndex)
        {
            case 12:
            case 10:
            case 8:
            case 6:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return [outputString uppercaseString];
}

//大端转小端
-(NSInteger)littleEndianCharToIntWithFirst:(unsigned char)char1 andSecond:(unsigned char)char2 {
    long tmp;
    NSInteger result;
    
    tmp = (long)char2 << 8 | char1;
    if (tmp < 32768)
        result = tmp;
    else
        result = tmp - 65536;
    return result;
}

-(NSInteger)littleEndianCharToInt24WithFirst:(unsigned char)char1 second:(unsigned char)char2 andThird:(unsigned char)char3 {
    long tmp;
    //int result;
    
    tmp = (long)char3 << 16 | char2 << 8 | char1;
    return tmp;
}
////////////////////////////////////////


#pragma mark - 读取蓝牙特征中的数据
- (void)peripheral:(CBPeripheral *)mperipheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic==pm25Char) {
        //NSUInteger bytesToConvert = [characteristic.value length];
        const unsigned char *uuidBytes = [characteristic.value bytes];
        
        NSInteger pm25 = [self littleEndianCharToInt24WithFirst:uuidBytes[0] second:uuidBytes[1] andThird:uuidBytes[2]];
        NSString *textString = [NSString stringWithFormat:@"%.2fug/m³",pm25/100.0];
        NSInteger unitStringLength = [@"ug/m³" length];
        _pm25Label.attributedText = [self getVariousString:textString unitLength:unitStringLength];

        [_notifyDic setObject:@(pm25/100.0) forKey:@"PM25"];

    }
    
    NSUserDefaults *shared = [[NSUserDefaults standardUserDefaults] initWithSuiteName:GROUP_ID];
    [shared setObject:_notifyDic forKey:@"WidgetData"];
    [shared synchronize];
}

//一个字符串中不同的字体样式
- (NSMutableAttributedString *)getVariousString:(NSString *)textString unitLength:(NSInteger)length{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:textString];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HDZK-GLXLZT-05" size:100] range:NSMakeRange(0,textString.length-length)];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HDZK-GLXLZT-05" size:20] range:NSMakeRange(textString.length-length,length)];
    return str;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
}


#pragma mark - 导航栏左右按钮点击事件
- (void)leftBtnItemClicked {
    //扫描外设
    if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"查找设备"]) {
        [SVProgressHUD showWithStatus:@"正在查找附近设备"];
        [self.navigationItem.leftBarButtonItem setTitle:@"断开连接"];
        //设置中心设备
        //设置代理
        _centreManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        //利用中心设备扫描外部设备
        
        //如果指定数组 则只扫描数组中设备
        [_centreManager scanForPeripheralsWithServices:nil options:nil];
    }else {
        [SVProgressHUD dismiss];
        [_centreManager stopScan];
        if (_peripheral!=nil) {
            NSLog(@"dis connect start");
            [_centreManager cancelPeripheralConnection:_peripheral];
        }
        _peripheral = nil;
        _peripherals = [NSMutableArray arrayWithCapacity:0];
        [_tableview reloadData];
        _pm25Label.text = nil;
        [self.navigationItem.leftBarButtonItem setTitle:@"查找设备"];
        [self.navigationItem.rightBarButtonItem setTitle:@"开始刷新"];
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)dealloc {
    _tableview = nil;
    _peripheral = nil;
    _centreManager = nil;
    
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
