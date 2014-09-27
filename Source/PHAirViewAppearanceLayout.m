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
    l.titleNormalColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1];
    l.titleHighlightColor = [UIColor blackColor];
    l.titleSelectedColor = [UIColor blackColor];
    
    l.sectionTitleColor = [UIColor blackColor];
    
    l.sectionTitleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    l.rowTitleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    
    l.heightAirMenuRow = 44;
    l.heightAirMenuSection = 80;
    
    l.sessionViewLeftPadding = 30;
    l.rowsContentMode = PHAirViewAppearanceLayoutContentModeCenter;
    l.rowsEdgeInsets = UIEdgeInsetsZero;
    l.paddingBetweenRows = 0;
    
    l.sectionContentHeight = 80;
    l.sectionContentMode = PHAirViewAppearanceLayoutContentModeCenter;
    l.sectionEdgeInsets = UIEdgeInsetsMake(40, 0, 0, 0);
    return l;
}
@end
