//
//  BTDataModel.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface BTDataModel : NSManagedObject
@property (nonatomic, strong) NSNumber *pm25Value;
@property (nonatomic, copy) NSString *dataType;
@property (nonatomic, strong) NSNumber *timeStamp;
@end
