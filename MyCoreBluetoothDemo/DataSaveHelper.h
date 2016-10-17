//
//  DataSaveHelper.h
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueToothData.h"
#import "BTDataModel.h"

@interface DataSaveHelper : NSObject<NSFetchedResultsControllerDelegate>
{
    NSManagedObjectContext *context;
    NSFetchedResultsController *results;
}
@property (nonatomic,retain) NSManagedObjectContext *context;
@property (nonatomic,retain) NSFetchedResultsController *results;

+ (DataSaveHelper *)sharedDataSaveHelper;

- (void)addData:(BlueToothData*)data;
- (NSArray *)getAllDatas;
- (void)removeData:(BTDataModel*)dataModel;
- (BTDataModel*)getDataWith:(double)timeStamp;

//根据时间段 返回数据
- (NSArray *)getDatasBetweenStartTimeInterval:(double)start endTimeInterval:(double)end;

//保存更新
- (void)saveUpdate;

@end
