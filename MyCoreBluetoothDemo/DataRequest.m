//
//  DataRequest.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/24.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "DataRequest.h"

@implementation DataRequest

//通过get获取数据
+ (void)getDataUseGetUrl:(NSString *)url type:(NSString *)requestID finished:(responseDataBlock)responseData {
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        responseData(obj,requestID,connectionError);
    }];
}

//通过Post获取数据
+ (void)getDataUsePostUrl:(NSString *)url param:(NSDictionary*)paramDic type:(NSString *)requestID finished:(responseDataBlock)responseData {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    [urlRequest setHTTPMethod:@"POST"];
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:paramDic options:NSJSONWritingPrettyPrinted error:nil];
    [urlRequest setHTTPBody:bodyData];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        responseData(obj,requestID,connectionError);
    }];
    
}

@end
