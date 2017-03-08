//
//  YHTableViewRefreshControl.m
//  refreshDemo
//
//  Created by yanghao on 2017/2/27.
//  Copyright © 2017年 justlike. All rights reserved.
//

#import "YHTableViewRefreshControl.h"

@implementation YHTableViewRefreshControl

@synthesize yRefreshControl;

- (void)dealloc
{
	yRefreshControl = nil;
}

- (YHRefreshControl *)yRefreshControl{
	if(yRefreshControl == nil){
		yRefreshControl = [[YHRefreshControl alloc] init];
		[self addSubview:yRefreshControl];
	}
	
	return yRefreshControl;
}

@end
