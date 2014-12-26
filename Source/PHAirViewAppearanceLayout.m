//
//  PHAirViewLayout.m
//  Pods
//
//  Created by Philip Zhao on 9/27/14.
//
//

#import "PHAirViewAppearanceLayout.h"

@implementation PHAirViewAppearanceLayout

+ (instancetype)defaultAppearanceLayout
{
    PHAirViewAppearanceLayout *l = [PHAirViewAppearanceLayout new];
    l.rowTitleNormalColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1];
    l.rowTitleHighlightColor = [UIColor blackColor];
    l.rowTitleSelectedColor = [UIColor blueColor];
    
    l.sectionTitleColor = [UIColor blackColor];
    
    l.sectionTitleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    l.rowTitleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    
    l.rowHeight = 44;
    l.sectionHeaderHeight = 100;
    
    l.sessionViewLeftPadding = 30;
    l.rowsContentMode = PHAirViewAppearanceLayoutContentModeCenter;
    l.rowsEdgeInsets = UIEdgeInsetsZero;
    l.paddingBetweenRows = 0;
    
    l.sectionHeaderContentHeight = 50;
    l.sectionHeaderContentMode = PHAirViewAppearanceLayoutContentModeCenter;
    l.sectionHeaderEdgeInsets = UIEdgeInsetsMake(40, 0, 0, 0);
  
    l.statusBarStyle = UIStatusBarStyleDefault;
    l.statusBarHidden = NO;
    l.statusBarAnimation = UIStatusBarAnimationNone;
  
    l.interactiveGestureBaseValueInPixel = CGRectGetWidth([UIScreen mainScreen].bounds);
    l.enableLeftViewBouncinessWithOnlyOneSession = YES;
    return l;
}

+ (instancetype)debuggingAppearanceLayout
{
    PHAirViewAppearanceLayout *l = [[self class] defaultAppearanceLayout];
    l.leftViewDebuggingColor = [UIColor brownColor];
    l.rightViewDebuggingColor = [UIColor redColor];
    l.interactiveGestureBaseValueInPixel = 220;
    l.showSessionBorder = YES;
  l.sectionHeaderContentHeight = 100;
  l.sectionHeaderContentMode = PHAirViewAppearanceLayoutContentModeBottom;
    return l;
}
@end
