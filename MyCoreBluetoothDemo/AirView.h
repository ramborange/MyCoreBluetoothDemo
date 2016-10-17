//
//  AirView.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/22.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BallView.h"
#import "BlueToothData.h"

@interface AirView : UIView

@property (nonatomic, strong) BallView *ballView;//污染指示


////搜索设备
//- (void)startSearchDevice;
//- (void)endSearchDevice;
//
////搜索到设备 输入配对密码 连接
//- (void)enterBlindNumberWith:(NSInteger)num;
//- (void)endBlind;

//配对成功 返回数据
- (void)reloadDataWithValue:(BlueToothData *)data;

//断开了设备的连接
//- (void)disConnectDeivce;

- (void)strainerSettingImgAnimated;


@end

