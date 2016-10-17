//
//  HistoryDataViewCell.m
//  MyCoreBluetoothDemo
//
//  Created by ramborange on 16/6/27.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import "HistoryDataViewCell.h"
#import "DataSaveHelper.h"
#import "BTDataModel.h"

#import "ShareOnce.h"

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@implementation HistoryDataViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor whiteColor];
        _lineView.alpha = 0.0;
        [self.contentView addSubview:_lineView];
    }
    self.backgroundColor = [UIColor clearColor];
    return self;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    NSInteger idx = self.tag-100;
//    NSLog(@"__%ld",self.tag);
    NSArray *datas = [ShareOnce getShareOnce].dataArray;
    BTDataModel *dataModel = datas[idx];
    
//    self.backgroundColor = [self getPmColorWithValue:dataModel.pm25Value.floatValue];
    
    float height = (dataModel.pm25Value.floatValue/[ShareOnce getShareOnce].maxValue)*self.bounds.size.height;
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    if ([ShareOnce getShareOnce].currentCellRow==idx) {
        CGContextAddArc(context, 5, self.bounds.size.height-height, 5.0, 0, M_PI*2, 0);
        float orginY = self.bounds.size.height*(1-1/1.2);
        float lineHeight = self.bounds.size.height-height-orginY;
        if (lineHeight>50) {
            _lineView.frame = CGRectMake(5, orginY, 0.5, lineHeight);
        }else {
            _lineView.frame = CGRectMake(5, self.bounds.size.height-height, 0.5, height);
        }
    }else {
        CGContextAddArc(context, 2, self.bounds.size.height-height, 2.0, 0, M_PI*2, 0);
    }
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGPoint point = CGPointMake(0, self.bounds.size.height-height);
    if (idx<datas.count-1) {
        BTDataModel *dataModelNext = datas[idx+1];
        float heightNext = (dataModelNext.pm25Value.floatValue/[ShareOnce getShareOnce].maxValue)*self.bounds.size.height;
        CGPoint pointNext = CGPointMake(self.bounds.size.width, self.bounds.size.height-heightNext);
        
        CGContextMoveToPoint(context, point.x, point.y);
        CGContextAddLineToPoint(context, pointNext.x, pointNext.y);
        CGContextDrawPath(context, kCGPathStroke);
    }
    
}


@end
