//
//  WPExpandableStatusBar.h
//
//  Created by Anton Zdorov.
//  Copyright (c) 2015 Webparadox, LLC. All rights reserved.
//


#import <UIKit/UIKit.h>


extern NSString * const WPStatysBarWillShowNotification;
extern NSString * const WPStatysBarDidShowNotification;

extern NSString * const WPStatusBarWillHideNotification;
extern NSString * const WPStatusBarDidHideNotification;

extern NSString * const WPStatusBarDidTapNotification;

// keys for fetch data from notification's user info dictionary

// Animations duration. NSNumber wrapper over CGFloat value
extern NSString * const WPStatusBarTotalDurationUserInfoKey;

// Begin status bar rect. NSValue wrapper over CGRect value
extern NSString * const WPStatusBarBeginRectUserInfoKey;

// End status bar rect. NSValue wrapper over CGRect value
extern NSString * const WPStatusBarEndRectUserInfoKey;

// Delay before animations. NSNumber wrapper over CGFloat value
extern NSString * const WPStatusBarDelayUserInfoKey;

// Animated or not. NSNumber wrapper over BOOL value
extern NSString * const WPStatusBarAnimatedUserInfoKey;


@interface WPExpandableStatusBar : UIWindow

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *titleLabel;

// Height of expanding of overlay view
@property (nonatomic, assign) CGFloat expandHeight;

// Total duration of show / hide animation.
// 50% of this value set alpha animation, 50% - expand animation
@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, assign, readonly) BOOL expandable;

+ (instancetype)sharedInstance;

- (void)showOverlayAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)hideOverlayAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end
