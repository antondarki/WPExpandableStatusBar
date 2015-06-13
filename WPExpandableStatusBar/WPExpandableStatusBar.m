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
static const CGFloat WPDefaultCloseButtonWidth = 40.0;
static const CGFloat WPDefaultPadding = 10.0;

@interface WPExpandableStatusBar()

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

- (id)init
{
    CGRect frame = [UIApplication sharedApplication].statusBarFrame;
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    self.windowLevel = UIWindowLevelStatusBar - 1;
    self.hidden = NO;
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 0.0;
    
    self.contentView = [[UIView alloc] initWithFrame:self.frame];
    self.contentView.backgroundColor = [UIColor colorWithRed:0.418 green:0.607 blue:1.000 alpha:1.000];
    self.contentView.clipsToBounds = YES;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:self.contentView];
    
    CGRect buttonRect = CGRectMake(CGRectGetWidth(self.contentView.frame) - WPDefaultPadding - WPDefaultCloseButtonWidth,
                                   WPDefaultExpandedHeight,
                                   WPDefaultCloseButtonWidth,
                                   WPDefaultExpandedHeight);
    self.closeButton = [[UIButton alloc] initWithFrame:buttonRect];
    self.closeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [self.closeButton setTitle:@"Hide" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.closeButton];
    
    CGFloat padding = CGRectGetWidth(self.frame) - CGRectGetMinX(self.closeButton.frame);
    
    CGRect titleLableRect = CGRectMake(padding,
                                       WPDefaultExpandedHeight,
                                       CGRectGetWidth(self.contentView.frame) - padding * 2,
                                       WPDefaultExpandedHeight);
    self.titleLabel = [[UILabel alloc] initWithFrame:titleLableRect];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont systemFontOfSize:12.0];
    self.titleLabel.text = @"";
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.titleLabel.numberOfLines = 0;
    [self.contentView addSubview:self.titleLabel];
    
    self.expandHeight = WPDefaultExpandedHeight;
    self.animationDuration = WPDefaultAnimationDuration;
    
    return self;
}

- (void)layoutSubviews
{
    // TODO: Rotating support (to landscape orientation)
    
    if (self.expandable) {
        // update close button frame
        CGFloat buttonPositionX = CGRectGetWidth(self.contentView.frame) - WPDefaultPadding - CGRectGetWidth(self.closeButton.frame);
        CGFloat buttonPositionY = CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(self.closeButton.frame);
        CGFloat buttonWidth = self.closeButton.hidden ? 0.0 : CGRectGetWidth(self.closeButton.frame);
        CGFloat buttonHeight = CGRectGetHeight(self.closeButton.frame);
        
        self.closeButton.frame = CGRectMake(buttonPositionX, buttonPositionY, buttonWidth, buttonHeight);
        
        // calculate and update title label frame
        CGFloat labelPositionX = self.closeButton.hidden ? WPDefaultPadding : CGRectGetWidth(self.frame) - CGRectGetMinX(self.closeButton.frame);
        CGFloat labelPositionY = MAX(CGRectGetHeight([UIApplication sharedApplication].statusBarFrame), CGRectGetMinY(self.titleLabel.frame));
        CGFloat labelWidth = CGRectGetWidth(self.contentView.frame) - labelPositionX * 2;
        CGFloat labelHeight = MIN([self maximumTitleLabelHeight], CGRectGetHeight(self.titleLabel.frame));
        
        self.titleLabel.frame = CGRectMake(labelPositionX, labelPositionY, labelWidth, labelHeight);
    }
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
    if (CGFloatEqualToCGFloat(CGRectGetHeight(self.frame), CGRectGetHeight(statusBarFrame) + self.expandHeight)) {
        return;
    }
    
    statusBarFrame.size.height += self.expandHeight;
    
    UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;
    
    CGRect mainWindowFrame = mainWindow.frame;
    mainWindowFrame.origin.y += self.expandHeight;
    mainWindowFrame.size.height -= self.expandHeight;
    
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
            self.frame = statusBarFrame;
            self.alpha = 1.0;
            
            mainWindow.frame = mainWindowFrame;
            [mainWindow layoutIfNeeded];
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WPStatysBarDidShowNotification object:nil userInfo:userInfo];
            
            if (completion) {
                completion();
            }
        }];
    } else {
        self.frame = statusBarFrame;
        self.alpha = 1.0;
        
        mainWindow.frame = mainWindowFrame;
        [mainWindow layoutIfNeeded];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WPStatysBarDidShowNotification object:nil userInfo:userInfo];
        
        if (completion) {
            completion();
        }
    }
}

- (void)hideOverlayAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectGetHeight(self.frame) <= CGRectGetHeight(statusBarFrame)) {
        return;
    }
    
    UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;
    CGFloat delta = CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(statusBarFrame);
    
    CGRect mainWindowFrame = mainWindow.frame;
    mainWindowFrame.origin.y -= delta;
    mainWindowFrame.size.height += delta;
    
    NSDictionary *userInfo = @{ WPStatusBarTotalDurationUserInfoKey : animated ? @(self.animationDuration) : @(0.0),
                                WPStatusBarBeginRectUserInfoKey : [NSValue valueWithCGRect:self.frame],
                                WPStatusBarEndRectUserInfoKey : [NSValue valueWithCGRect:statusBarFrame],
                                WPStatusBarDelayUserInfoKey : @(0.0),
                                WPStatusBarAnimatedUserInfoKey : @(animated) };

    
    [[NSNotificationCenter defaultCenter] postNotificationName:WPStatusBarWillHideNotification object:nil userInfo:userInfo];
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.frame = statusBarFrame;
            self.alpha = 0.0;
            
            mainWindow.frame = mainWindowFrame;
            mainWindow.rootViewController.view.frame = mainWindowFrame;
            
            [mainWindow layoutIfNeeded];
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
        self.alpha = 0.0;
        self.frame = statusBarFrame;
        
        mainWindow.frame = mainWindowFrame;
        mainWindow.rootViewController.view.frame = mainWindowFrame;
        [mainWindow layoutIfNeeded];
        
        if (!IsIOS8OrMore()) {
            [[UIApplication sharedApplication].delegate.window.rootViewController.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WPStatusBarDidHideNotification object:nil userInfo:userInfo];
        
        if (completion) {
            completion();
        }
    }
}

- (void)closeButtonTouchUpInside:(UIButton *)sender
{
    [self hideOverlayAnimated:YES completion:nil];
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

- (BOOL)expandable
{
    return CGRectGetHeight(self.frame) > CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

#pragma mark - Private

- (CGFloat)maximumTitleLabelHeight
{
    CGFloat height = CGRectGetHeight(self.contentView.frame) - CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    return height;
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
