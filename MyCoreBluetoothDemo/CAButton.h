//
//  CAButton.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/28.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CAButton : UIButton

@property (assign, nonatomic) BOOL isStartSyncAnimation;
@property (assign, nonatomic) BOOL isFinshedAnimation;

- (void)btnStartAnimtion;

- (void)finishedTask;

- (void)canceledTask;


@end
