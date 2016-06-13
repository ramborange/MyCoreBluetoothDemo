//
//  AppDelegate.h
//  MyCoreBluetoothDemo
//
//  Created by ljf on 16/5/20.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) ViewController *rootViewController;

-(void)receiveData:(NSMutableDictionary*)dataDic;
@end

