//
//  ShareOnce.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/29.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShareOnce : NSObject
+ (ShareOnce *)getShareOnce;

@property (nonatomic, assign) float maxValue;

@property (nonatomic, assign) NSInteger currentCellRow;

@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, assign) double startTimeInterval;
@property (nonatomic, assign) double endTimeInterval;

@end
