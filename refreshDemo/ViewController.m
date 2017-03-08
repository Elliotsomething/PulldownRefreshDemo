//
//  ViewController.m
//  refreshDemo
//
//  Created by yanghao on 2017/2/27.
//  Copyright © 2017年 justlike. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
	YHRefreshControl *yRefreshControl;
	void(^refreshCallBack)(void);
}
@property (nonatomic) BOOL pullDownSucess;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	
	self.tableView = [[YHTableViewRefreshControl alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64) style:UITableViewStylePlain];
	self.tableView.backgroundColor = [UIColor whiteColor];
//	self.tableView
		
	[self.view addSubview:self.tableView];
	
	
	yRefreshControl = [self.tableView yRefreshControl];
	
	__weak typeof(self) weakSelf = self;
	[yRefreshControl setRefreshRequest:^BOOL(YHRefreshControl *sender) {
		return [weakSelf refreshWithCallBack:^{
			[sender endRefreshing:weakSelf.pullDownSucess];
		}];
	}];
	
	
	
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark -pullup refresh-
-(BOOL)refreshWithCallBack:(void(^)(void))callBack
{
	refreshCallBack = callBack;
	[self pullDownRefreshData];
	return YES;
}


- (void)pullDownRefreshData
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self pullDownRefreshSucess:YES];
	});
}

- (void)pullDownRefreshSucess:(BOOL)sucess
{
	[self pullDownRefreshSucess:sucess andMore:YES];
}


- (void)pullDownRefreshSucess:(BOOL)sucess andMore:(BOOL)more
{
	__weak typeof(self)weakSelf = self;
	__weak typeof(refreshCallBack)weakRefreshCallBack = refreshCallBack;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
	
		
		weakSelf.pullDownSucess = sucess;
		
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[weakSelf.tableView reloadData];
		});
		
		
		if (weakRefreshCallBack) {
			weakRefreshCallBack();
		}
	
	});
}

@end
