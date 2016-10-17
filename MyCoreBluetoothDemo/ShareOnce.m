//
//  ShareOnce.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/29.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "ShareOnce.h"

static ShareOnce *once = nil;
@implementation ShareOnce
+ (ShareOnce *)getShareOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        once = [[ShareOnce alloc] init];
    });
    return once;
}
@end
