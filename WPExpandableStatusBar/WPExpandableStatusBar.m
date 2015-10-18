//
//  WPExpandableStatusBar.m
//
//  Created by Anton Zdorov.
//  Copyright (c) 2015 Webparadox, LLC. All rights reserved.
//


#import "WPExpandableStatusBar.h"


NSString * const WPStatysBarWillShowNotification = @"WPStatysBarWillShowNotification";
NSString * const WPStatysBarDidShowNotification = @"WPStatysBarDidShowNotification";

NSString * const WPStatusBarWillHideNotification = @"WPStatusBarWillHideNotification";
NSString * const WPStatusBarDidHideNotification = @"WPStatusBarDidHideNotification";

NSString * const WPStatusBarDidTapNotification = @"WPStatusBarDidTapNotification";

NSString * const WPStatusBarTotalDurationUserInfoKey = @"WPStatusBarTotalDurationUserInfoKey";
NSString * const WPStatusBarBeginRectUserInfoKey = @"WPStatusBarBeginRectUserInfoKey";
NSString * const WPStatusBarEndRectUserInfoKey = @"WPStatusBarEndRectUserInfoKey";
NSString * const WPStatusBarDelayUserInfoKey = @"WPStatusBarDelayUserInfoKey";
NSString * const WPStatusBarAnimatedUserInfoKey = @"WPStatusBarAnimatedUserInfoKey";

static const CGFloat WPDefaultExpandedHeight = 20.0;
static const CGFloat WPDefaultAnimationDuration = 0.5;


@interface WPExpandableStatusBar()

@property (nonatomic, strong, readwrite) UIView *contentView;

@end

@implementation WPExpandableStatusBar

+ (instancetype)sharedInstance
{
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.userInteractionEnabled || self.hidden || CGFloatEqualToCGFloat(self.alpha, 0.0)) {
        return nil;
    }
    
    if (!self.expanded) {
        return nil;
    }
    
    if (![self.contentView pointInside:point withEvent:event]) {
        return nil;
    }
    
    for (UIView *view in [self.contentView.subviews reverseObjectEnumerator]) {
        CGPoint convertedPoint = [self.contentView convertPoint:point toView:view];
        UIView *subview = [view hitTest:convertedPoint withEvent:event];
        
        if (subview) {
            return subview;
        }
    }
    
    return self.contentView;
}

- (id)init
{
    CGRect frame = [UIApplication sharedApplication].delegate.window.bounds;
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    self.windowLevel = UIWindowLevelStatusBar - 1;
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 1.0;
    
    self.contentView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
    self.contentView.backgroundColor = [UIColor colorWithRed:0.418 green:0.607 blue:1.000 alpha:1.000];
    self.contentView.clipsToBounds = YES;
    self.contentView.alpha = 0.0;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:self.contentView];
    
    self.expandHeight = WPDefaultExpandedHeight;
    self.animationDuration = WPDefaultAnimationDuration;
    
    [self makeKeyAndVisible];
    
    return self;
}

// workaround
// or use custom modal transition style

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(frame))]) {
        CGRect rect = [[change valueForKey:NSKeyValueChangeNewKey] CGRectValue];
        if (rect.origin.y == -20.0) {
            rect.origin.y = 0.0;
            rect.size.height = CGRectGetHeight([UIApplication sharedApplication].delegate.window.frame);
            
            [UIApplication sharedApplication].delegate.window.rootViewController.view.frame = rect;
            [[UIApplication sharedApplication].delegate.window.rootViewController.view layoutIfNeeded];
        }
    }
}

- (void)showOverlayAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGFloatEqualToCGFloat(CGRectGetHeight(self.contentView.frame), CGRectGetHeight(statusBarFrame) + self.expandHeight)) {
        return;
    }
    
    statusBarFrame.size.height += self.expandHeight;
    
    UIView *mainView = [UIApplication sharedApplication].delegate.window.rootViewController.view;
    CGRect mainViewFrame = mainView.frame;
    
    mainViewFrame.origin.y += self.expandHeight;
    mainViewFrame.size.height -= self.expandHeight;
    
    NSDictionary *userInfo = @{ WPStatusBarTotalDurationUserInfoKey : animated ? @(self.animationDuration) : @(0.0),
                                WPStatusBarBeginRectUserInfoKey : [NSValue valueWithCGRect:[UIApplication sharedApplication].statusBarFrame],
                                WPStatusBarEndRectUserInfoKey : [NSValue valueWithCGRect:statusBarFrame],
                                WPStatusBarDelayUserInfoKey : @(0.0),
                                WPStatusBarAnimatedUserInfoKey : @(animated) };
    
    if (!IsIOS8OrMore()) {
        [[UIApplication sharedApplication].delegate.window.rootViewController.view addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:NSKeyValueObservingOptionNew context:nil];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:WPStatysBarWillShowNotification object:nil userInfo:userInfo];
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.contentView.frame = statusBarFrame;
            self.contentView.alpha = 1.0;
            
            mainView.frame = mainViewFrame;
            [mainView layoutIfNeeded];
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WPStatysBarDidShowNotification object:nil userInfo:userInfo];
            
            if (completion) {
                completion();
            }
        }];
    } else {
        self.contentView.frame = statusBarFrame;
        self.contentView.alpha = 1.0;
        
        mainView.frame = mainViewFrame;
        [mainView layoutIfNeeded];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WPStatysBarDidShowNotification object:nil userInfo:userInfo];
        
        if (completion) {
            completion();
        }
    }
}

- (void)hideOverlayAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectGetHeight(self.contentView.frame) <= CGRectGetHeight(statusBarFrame)) {
        return;
    }
    
    UIView *mainView = [UIApplication sharedApplication].delegate.window.rootViewController.view;
    CGFloat delta = CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(statusBarFrame);
    
    CGRect mainViewFrame = mainView.frame;
    mainViewFrame.origin.y -= delta;
    mainViewFrame.size.height += delta;
    
    NSDictionary *userInfo = @{ WPStatusBarTotalDurationUserInfoKey : animated ? @(self.animationDuration) : @(0.0),
                                WPStatusBarBeginRectUserInfoKey : [NSValue valueWithCGRect:self.contentView.frame],
                                WPStatusBarEndRectUserInfoKey : [NSValue valueWithCGRect:statusBarFrame],
                                WPStatusBarDelayUserInfoKey : @(0.0),
                                WPStatusBarAnimatedUserInfoKey : @(animated) };

    
    [[NSNotificationCenter defaultCenter] postNotificationName:WPStatusBarWillHideNotification object:nil userInfo:userInfo];
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.contentView.frame = statusBarFrame;
            self.contentView.alpha = 0.0;
            
            mainView.frame = mainViewFrame;
            
            [mainView layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (!IsIOS8OrMore()) {
                [[UIApplication sharedApplication].delegate.window.rootViewController.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:WPStatusBarDidHideNotification object:nil userInfo:userInfo];
            
            if (completion) {
                completion();
            }
        }];
    } else {
        self.contentView.alpha = 0.0;
        self.contentView.frame = statusBarFrame;
        
        mainView.frame = mainViewFrame;
        [mainView layoutIfNeeded];
        
        if (!IsIOS8OrMore()) {
            [[UIApplication sharedApplication].delegate.window.rootViewController.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WPStatusBarDidHideNotification object:nil userInfo:userInfo];
        
        if (completion) {
            completion();
        }
    }
}

#pragma mark - Getters / Setters

- (void)setExpandHeight:(CGFloat)expandHeight
{
    NSAssert(expandHeight >= 0.0, @"Max height value for expanded overlay must be great or equal to zero value");
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(expandHeight))];
    
    _expandHeight = expandHeight;
    
    [self didChangeValueForKey:NSStringFromSelector(@selector(expandHeight))];
}

- (void)setAnimationDuration:(CGFloat)animationDuration
{
    NSAssert(animationDuration >= 0.0, @"Duration of expanding overlay must be positive float number value");
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(animationDuration))];
    
    _animationDuration = animationDuration;
    
    [self didChangeValueForKey:NSStringFromSelector(@selector(animationDuration))];
}

- (BOOL)expanded
{
    return CGRectGetHeight(self.contentView.frame) > CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

#pragma mark - Utilities

BOOL CGFloatEqualToCGFloat(CGFloat a, CGFloat b)
{
    return (fabs((a) - (b)) < FLT_EPSILON);
}

BOOL IsIOS8OrMore(void)
{
    CGFloat deviceVersion = [[UIDevice currentDevice].systemVersion floatValue];
    return deviceVersion >= 8.0f;
}

@end
