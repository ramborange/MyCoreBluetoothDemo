//
//  DataSaveHelper.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "DataSaveHelper.h"
#define STOREPATH [NSHomeDirectory() stringByAppendingString:@"/Documents/historyData.sqlite1"]

static DataSaveHelper *dataSaveHelper = nil;
@implementation DataSaveHelper
@synthesize context;
@synthesize results;

+ (DataSaveHelper *)sharedDataSaveHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataSaveHelper = [[DataSaveHelper alloc] init];
    });
    return dataSaveHelper;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self initCoreData];
    }
    return self;
}

-(void)dealloc {
    self.results.delegate = nil;
}

//初始化CoreData
- (void)initCoreData
{
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:STOREPATH];
    NSLog(@"url path:%@",url.path);
    
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                       NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES],
                                       NSInferMappingModelAutomaticallyOption, nil];
    //搜索工程中所有的.xcdatamodeld文件，并加载所有的实体到一个managedObjectModel实例中
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    // 创建持久化数据存储协调器
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    // 创建一个SQLite数据库作为数据存储
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:optionsDictionary error:&error]) {
        NSLog(@"Error: %@",[error localizedDescription]);
    }else{
        NSLog(@"successful...");
        // 创建托管对象上下文
        self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [self.context setPersistentStoreCoordinator:persistentStoreCoordinator];
    }
}

- (void)addData:(BlueToothData*)data {
    BTDataModel *model = [self getDataWith:data.timeStamp];
    if (nil != model) {
        [self removeData:model];
    }
    BTDataModel *dataModel = (BTDataModel *)[NSEntityDescription insertNewObjectForEntityForName:@"BTDataModel" inManagedObjectContext:self.context];
    dataModel.pm25Value = [NSNumber numberWithFloat:data.pm25Value];
    dataModel.dataType = data.dataType;
    dataModel.timeStamp = [NSNumber numberWithDouble:data.timeStamp];
    //save the data
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"Error: %@",[error localizedDescription]);
    }
}


- (NSArray *)getDatasBetweenStartTimeInterval:(double)start endTimeInterval:(double)end {
    [NSFetchedResultsController deleteCacheWithName:@"Root2"];
    self.results = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BTDataModel" inManagedObjectContext:self.context]];
    
    //增加一个筛选条件
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:descriptors];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp >= %f && timeStamp <= %f",start,end];
    fetchRequest.predicate = predicate;
    
    //设置结果集
    NSError *error = nil;
    self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                       managedObjectContext:self.context
                                                         sectionNameKeyPath:nil cacheName:@"Root2"];
    self.results.delegate = self;
    //FIXME:经常在此崩溃
    if (![[self results] performFetch:&error]) {
        NSLog(@"Error: %@",[error localizedDescription]);
    }
    
    if (!self.results.fetchedObjects.count) {
        //        NSLog(@"has no results...");
        return nil;
    }else{
        NSArray *returnArray =self.results.fetchedObjects;
        self.results = nil;
        return returnArray;
    }

}

- (NSArray *)getAllDatas {
    [NSFetchedResultsController deleteCacheWithName:@"Root1"];
    self.results = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BTDataModel" inManagedObjectContext:self.context]];
    
    //增加一个筛选条件
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:descriptors];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp > 0"];
    fetchRequest.predicate = predicate;
    
    //设置结果集
    NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:101 userInfo:nil];
    self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                       managedObjectContext:self.context
                                                         sectionNameKeyPath:nil cacheName:@"Root1"];
    self.results.delegate = self;
    //FIXME:经常在此崩溃
    if (![[self results] performFetch:&error]) {
        NSLog(@"Error: %@",[error localizedDescription]);
    }
    
    if (!self.results.fetchedObjects.count) {
        //        NSLog(@"has no results...");
        return nil;
    }else{
        NSArray *returnArray =self.results.fetchedObjects;
        self.results = nil;
        return returnArray;
    }
}

- (void)removeData:(BTDataModel*)dataModel {
    //删除
    [self.context deleteObject:dataModel];
    
    //保存
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"error :%@",[error localizedDescription]);
    }
}

- (BTDataModel*)getDataWith:(double)timeStamp {
    BTDataModel *result;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BTDataModel" inManagedObjectContext:self.context]];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:descriptors];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp == %lld",timeStamp];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
    self.results.delegate = self;
    if (![[self results] performFetch:&error]) {
        NSLog(@"Error: %@",[error localizedDescription]);
    }
    
    if (!self.results.fetchedObjects.count) {
        //        NSLog(@"has no results...");
        return nil;
    }else if([self.results.fetchedObjects count] > 1){
        
    }
    
    result = [self.results.fetchedObjects objectAtIndex:0];
    
    return result;
}

#pragma mark - 保存信息
- (void)saveUpdate {
    NSError *error;
    if (self.context) {
        if ([self.context hasChanges]) {
            if (![self.context save:&error]) {
                NSLog(@"remove msg error:%@",[error localizedDescription]);
            }
        }
    }
    
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    
}

@end
