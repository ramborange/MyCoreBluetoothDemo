//
//  BlueToothData.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueToothData : NSObject

@property (nonatomic, assign) float pm25Value;
@property (nonatomic, copy) NSString *dataType;
@property (nonatomic, assign) double timeStamp;

@end
