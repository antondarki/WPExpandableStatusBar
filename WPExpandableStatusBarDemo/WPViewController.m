//
//  WPViewController.m
//  WPExpandableStatusBarDemo
//
//  Created by Anton Zdorov on 5/31/15.
//  Copyright (c) 2015 Webparadox, LLC. All rights reserved.
//

#import "WPViewController.h"
#import "WPExpandableStatusBar.h"


@interface WPViewController ()

@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (weak, nonatomic) IBOutlet UILabel *val1;
@property (weak, nonatomic) IBOutlet UILabel *val2;

@property (weak, nonatomic) IBOutlet UIStepper *stepper1;
@property (weak, nonatomic) IBOutlet UIStepper *stepper2;

@property (strong, nonatomic) WPExpandableStatusBar *expandableStatusBar;

@end

@implementation WPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.expandableStatusBar = [WPExpandableStatusBar sharedInstance];
    
    self.val1.text = @"";
    self.val2.text = @"";
}

- (IBAction)actionButtonTap:(id)sender
{
    CGFloat duration = self.stepper1.value;
    CGFloat expandValue = self.stepper2.value;
    
    self.expandableStatusBar.expandHeight = expandValue;
    self.expandableStatusBar.animationDuration = duration;
    
    if (self.expandableStatusBar.expandable) {
        [self.expandableStatusBar hideOverlayAnimated:YES completion:^{
            [self.actionButton setTitle:@"Show" forState:UIControlStateNormal];
        }];
    } else {
        [self.expandableStatusBar showOverlayAnimated:YES completion:^{
            [self.actionButton setTitle:@"Hide" forState:UIControlStateNormal];
        }];
    }
}

- (IBAction)stepper1Tap:(UIStepper *)sender
{
    self.val1.text = [NSString stringWithFormat:@"%f", sender.value];
}

- (IBAction)stepper2Tap:(UIStepper *)sender
{
    self.val2.text = [NSString stringWithFormat:@"%lu", (NSInteger)sender.value];
}

@end
