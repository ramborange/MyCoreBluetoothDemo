//
//  DataRequest.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/24.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^responseDataBlock)(id obj,NSString *type,NSError *error);

@interface DataRequest : NSObject

//get获取数据
+ (void)getDataUseGetUrl:(NSString *)url type:(NSString *)requestID finished:(responseDataBlock)responseData;

//post获取数据
+ (void)getDataUsePostUrl:(NSString *)url param:(NSDictionary*)paramDic type:(NSString *)requestID finished:(responseDataBlock)responseData;

@end
