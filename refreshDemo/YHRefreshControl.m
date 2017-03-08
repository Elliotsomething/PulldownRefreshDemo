//
//  refreshControl.m
//  refreshDemo
//
//  Created by yanghao on 2017/2/27.
//  Copyright © 2017年 justlike. All rights reserved.
//

#import "YHRefreshControl.h"

#define weak(obj)      __weak typeof(obj) weak##obj = obj
#define strong(obj)    __strong typeof(obj) strong##obj = obj;//通过其他指针来避免block循环引用（成员变量）


static NSString *const kRefreshControlIdle = @"kRefreshControlIdle";
static NSString *const kRefreshControlPulling = @"kRefreshControlPulling";
static NSString *const kRefreshControlRefreshing = @"kRefreshControlRefreshing";
static NSString *const kRefreshControlRefreshDone = @"kRefreshControlRefreshDone";


@interface YHRefreshControl (){
	UIActivityIndicatorView *activityView;
	UIImageView *arrowView;
	UITextView *tips;
	NSString *state;
	NSInteger dragCount;
}
@property (nonatomic, readonly) UITableView *superTableView;
@end


@implementation YHRefreshControl

- (id)init
{
	self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60)];
	if (self)
	{
		tips = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)];
		tips.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
		tips.userInteractionEnabled = NO;
		tips.editable = NO;
		tips.textAlignment = NSTextAlignmentCenter;
		tips.textColor = [UIColor darkGrayColor];
		tips.backgroundColor = [UIColor clearColor];
		tips.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tips.font = [UIFont systemFontOfSize:12.0];
		[self addSubview:tips];
		
		activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityView.center = CGPointMake(self.frame.size.width/2 - 43, tips.center.y);
		activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		activityView.color = [UIColor clearColor];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:activityView.bounds];
		imageView.image = [UIImage imageNamed:@"loading"];
		[self addAnimationWith:imageView];
		[activityView addSubview:imageView];
		[self addSubview:activityView];
		
		arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"refreshArrow"]];
		arrowView.center = CGPointMake(activityView.center.x, tips.center.y);
		[self addSubview:arrowView];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];
		
		[self changeState:kRefreshControlIdle andValue:nil andForce:YES];
	}
	return self;
}
-(void)addAnimationWith:(UIImageView *)imageView
{
	CALayer *layer = imageView.layer;
	CAKeyframeAnimation *animation;
	animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.duration = 0.5f;
	animation.cumulative = YES;
	animation.repeatCount = 100000;
	animation.values = [NSArray arrayWithObjects:
						[NSNumber numberWithFloat:0.0 * M_PI],
						[NSNumber numberWithFloat:0.75 * M_PI],
						[NSNumber numberWithFloat:1.5 * M_PI], nil];
	animation.keyTimes = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0],
						  [NSNumber numberWithFloat:.5],
						  [NSNumber numberWithFloat:1.0], nil];
	//    animation.timingFunctions = [NSArray arrayWithObjects:
	//                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
	//                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], nil];
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
	
	[layer addAnimation:animation forKey:nil];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	//添加到superview时，调整自身的frame
	self.frame = CGRectMake(0, -self.frame.size.height, newSuperview.frame.size.width, self.frame.size.height);
}

- (void)didMoveToSuperview
{
	//添加到superview时，添加观察上层UITableView的contentOffset
	[self.superTableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeFromSuperview
{
	if(self.superTableView)
	{
		//移除时，取消观察contentOffset
		[self.superTableView removeObserver:self forKeyPath:@"contentOffset"];
	}
	
	[super removeFromSuperview];
}


- (void)setTipsString:(NSString *)str
{
	CGSize strSize = [str sizeWithFont:tips.font constrainedToSize:self.frame.size];
	strSize.height += tips.font.capHeight*2;
	
	//设置提示语并垂直居中
	tips.text = str;
	tips.frame = CGRectMake(0, (self.frame.size.height-strSize.height)/2, tips.frame.size.width, strSize.height);
}

- (void)changeStateEx:(NSString *)newState andValue:(id)value
{
	BOOL hasChanged = !(state==newState);
	
	if(newState)
	{
		state = newState;
		
		if([state isEqualToString:kRefreshControlIdle] && hasChanged)
		{
			arrowView.transform = CGAffineTransformMakeRotation(0);
			[activityView stopAnimating];
		}
		else if([state isEqualToString:kRefreshControlPulling])
		{
			
			NSString *str1 = NSLocalizedStringFromTable(@"下拉刷新", @"Common", nil);
			//NSString *str2 = lastRefreshDateString? [NSString stringWithFormat:@"\n%@: %@", NSLocalizedStringFromTable(@"Last refresh date", @"Common", nil), lastRefreshDateString]: @"";
			
			CGAffineTransform t = CGAffineTransformMakeRotation(0);
			if([value CGPointValue].y < -self.frame.size.height)
			{
				str1 = NSLocalizedStringFromTable(@"正在刷新", @"Common", nil);
				t = CGAffineTransformMakeRotation(M_PI);
			}
			
			//            NSString *str = [NSString stringWithFormat:@"%@%@", str1, str2];
			NSString *str = [NSString stringWithFormat:@"%@", str1];
			if([tips.text isEqualToString:str] == NO)
			{
				[self setTipsString:str];
			}
			
			arrowView.hidden = NO;
			
			if(CGAffineTransformEqualToTransform(t, arrowView.transform) == NO)
			{
				[self setTipsString:str];
				[UIView animateWithDuration:0.15 animations:^{
					arrowView.transform = t;
				}];
			}
		}
		else if([state isEqualToString:kRefreshControlRefreshing] && hasChanged)
		{
			NSString *str1 = NSLocalizedStringFromTable(@"正在刷新", @"Common", nil);
			// NSString *str2 = lastRefreshDateString? [NSString stringWithFormat:@"\n%@: %@", NSLocalizedStringFromTable(@"Last refresh date", @"Common", nil), lastRefreshDateString]: @"";
			//            [self setTipsString:[NSString stringWithFormat:@"%@%@", str1, str2]];
			[self setTipsString:[NSString stringWithFormat:@"%@", str1]];
			arrowView.hidden = YES;
			[activityView startAnimating];
		}
		else if([state isEqualToString:kRefreshControlRefreshDone] && hasChanged)
		{
			if([value boolValue])
			{
				[self setTipsString:NSLocalizedStringFromTable(@"刷新完成", @"Common", nil)];
			}
			else
			{
				[self setTipsString:NSLocalizedStringFromTable(@"刷新失败", @"Common", nil)];
			}
			arrowView.hidden = YES;
			[activityView stopAnimating];
		}
	}
}

- (void)changeState:(NSString *)newState andValue:(id)value andForce:(BOOL)force
{
	NSArray *stateMachie = [NSArray arrayWithObjects:kRefreshControlIdle, kRefreshControlPulling, kRefreshControlRefreshing, kRefreshControlRefreshDone, nil];
	if(state && force == NO)
	{
		if([stateMachie containsObject:newState])
		{
			NSUInteger old = [stateMachie indexOfObject:state];
			NSUInteger new = [stateMachie indexOfObject:newState];
			
			if((old+1)%stateMachie.count == new || old == new)
			{
				[self changeStateEx:newState andValue:value];
			}
		}
	}
	else
	{
		[self changeStateEx:newState andValue:value];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"contentOffset"])
	{
		NSValue *offsetValue = [NSValue valueWithCGPoint:self.superTableView.contentOffset];
		
		if(self.superTableView.contentOffset.y > -self.frame.size.height)
		{
			if(-self.frame.size.height != self.frame.origin.y)
			{
				self.frame = CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height);
			}
		}
		else
		{
			self.frame = CGRectMake(0, self.superTableView.contentOffset.y, self.frame.size.width, self.frame.size.height);
		}
		
		if(self.superTableView.dragging)
		{
			if(![state isEqualToString:kRefreshControlPulling] || self.superTableView.contentOffset.y < 0)
			{
				[self changeState:kRefreshControlPulling andValue:offsetValue andForce:NO];
			}
			
			dragCount++;
		}
		else if(self.superTableView.decelerating)
		{
			if(self.refresh)
			{
				if(self.superTableView.contentOffset.y < -self.frame.size.height/2 && dragCount > 1)
				{
					[self.superTableView setContentOffset:CGPointMake(0, -self.frame.size.height) animated:YES];
					
				}
			}
			else
			{
				if([state isEqualToString:kRefreshControlPulling]
				   && CGAffineTransformEqualToTransform(arrowView.transform, CGAffineTransformMakeRotation(0)) == NO)
				{
					if(self.refreshRequest && self.refreshRequest(self))
					{
						[self changeState:kRefreshControlRefreshing andValue:offsetValue andForce:NO];
						
						
						//						if (!kFlagDebug){
						weak(self);
						[UIView animateWithDuration:0.3 animations:^{
							[weakself.superTableView setContentOffset:CGPointMake(0, -self.frame.size.height)];
						}];
						//						}else{
						//
						//							[self.superTableView setContentOffset:CGPointMake(0, -self.frame.size.height) animated:YES];
						//						}
						
					}
				}
				else
				{
					//滚动停止时，如果不在刷新状态，就强制进入到默认状态
					[self changeState:kRefreshControlIdle andValue:offsetValue andForce:YES];
				}
			}
			
			dragCount = 0;
		}
	}
}

- (BOOL)refresh
{
	return [state isEqualToString:kRefreshControlRefreshing];
}

- (UITableView *)superTableView
{
	NSAssert([self.superview isKindOfClass:[UITableView class]] || self.superview == nil, @"%@'s superview should be a UITableView, but now is %@", self.class, self.superview.class);
	
	return (UITableView *)self.superview;
}

- (void)beginRefreshing
{
	[self changeState:kRefreshControlRefreshing andValue:nil andForce:YES];
	
	if(CGPointEqualToPoint(self.superTableView.contentOffset, CGPointMake(0, 0)))
	{
		[self.superTableView setContentOffset:CGPointMake(0, -self.frame.size.height) animated:YES];
		
	}
}

- (void)endRefreshing:(BOOL)success
{
	[self changeState:kRefreshControlRefreshDone andValue:[NSNumber numberWithBool:success] andForce:NO];
	
	__weak typeof(self) weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		if(weakSelf.refresh == NO && weakSelf.superTableView.dragging == NO)
		{
			if(CGPointEqualToPoint(weakSelf.superTableView.contentOffset, CGPointMake(0, -weakSelf.frame.size.height)))
			{
				//- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;自带的动画是transition动画（会另开一个动画线程，当reload的时候会打断动画的执行），UIView的属性的动画是在主线程执行的不会被打断，所以改用属性动画；
				//				if (!kFlagDebug){
				[UIView animateWithDuration:0.3 animations:^{
					[weakSelf.superTableView setContentOffset:CGPointZero];
				}];
				//				}else{
				//					[weakSelf.superTableView setContentOffset:CGPointZero animated:YES];
				//
				//				}
				
			}
			
			[weakSelf changeState:kRefreshControlIdle andValue:nil andForce:NO];
		}
	});
}

@end
