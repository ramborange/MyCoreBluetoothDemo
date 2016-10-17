//
//  ViewController.h
//  MyCoreBluetoothDemo
//
//  Created by ljf on 16/5/20.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface ViewController : UIViewController
@property (nonatomic, strong) CBCentralManager *centreManager;//中心管理者
@property (nonatomic, strong) CBPeripheral *peripheral;//外设

@property (nonatomic, assign) CGRect buttonFrame;//进入历史界面按钮frame

//搜索外设
- (void)connectMyBleDevice;
@end

