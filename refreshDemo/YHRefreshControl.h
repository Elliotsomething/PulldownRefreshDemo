//
//  refreshControl.h
//  refreshDemo
//
//  Created by yanghao on 2017/2/27.
//  Copyright © 2017年 justlike. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YHRefreshControl : UIView
@property (nonatomic, readonly) BOOL refresh;
@property (nonatomic, strong) NSDate *lastRefreshDate;
@property (nonatomic, copy) BOOL (^refreshRequest)(YHRefreshControl *sender);

- (void)beginRefreshing;
- (void)endRefreshing:(BOOL)success;
@end
