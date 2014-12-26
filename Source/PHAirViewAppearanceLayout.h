//
//  PHAirViewLayout.h
//  Pods
//
//  Created by Philip Zhao on 9/27/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PHAirViewAppearanceLayoutContentModeTop,
    PHAirViewAppearanceLayoutContentModeCenter,
    PHAirViewAppearanceLayoutContentModeBottom,
} PHAirViewAppearanceLayoutContentMode;

@interface PHAirViewAppearanceLayout : NSObject

// Configure row title.
@property (nonatomic, strong) UIColor *rowTitleNormalColor;
@property (nonatomic, strong) UIColor *rowTitleHighlightColor;
@property (nonatomic, strong) UIColor *rowTitleSelectedColor;
@property (nonatomic, strong) UIFont *rowTitleFont;

// Configure section title
@property (nonatomic, strong) UIColor * sectionTitleColor;
@property (nonatomic, strong) UIFont *sectionTitleFont;

// Configure section header layout.
// The relative position of headerContent inside the allocated space.
@property (nonatomic, assign) PHAirViewAppearanceLayoutContentMode sectionHeaderContentMode; /** Allow all values*/
// the padding for headerContent.
@property (nonatomic, assign) UIEdgeInsets sectionHeaderEdgeInsets;
// the actual size of sectionHeaderContent height
@property (nonatomic, assign) CGFloat sectionHeaderContentHeight;
// the total spacing for sectionHeaderContent
@property (nonatomic, assign) CGFloat sectionHeaderHeight;
// Padding between thumbnail and title in section header content.
@property (nonatomic, assign) CGFloat paddingBetweenThumbnailAndTitleInSection;

// Configure row layout
// The height of each row
@property (nonatomic, assign) CGFloat rowHeight;
// The relative position of rowContent inside the allocated space.
@property (nonatomic, assign) PHAirViewAppearanceLayoutContentMode rowsContentMode; /** Only allow Top and Center */
@property (nonatomic, assign) UIEdgeInsets rowsEdgeInsets; // only left would use; top would apply if rowsContentMode set to Top
// Padding between thumbnail and title in row content.
@property (nonatomic, assign) CGFloat paddingBetweenThumbnailAndTitleInRow;
// The space between each row.
@property (nonatomic, assign) CGFloat paddingBetweenRows;

// SessionView Left edge
@property (nonatomic, assign) CGFloat sessionViewLeftPadding;

// Configure status bar
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation statusBarAnimation;

// by default it is the screen size
@property (nonatomic, assign) CGFloat interactiveGestureBaseValueInPixel;

@property (nonatomic, assign) BOOL enableLeftViewBouncinessWithOnlyOneSession;

// View Debugging. Should disable Release mode.
@property (nonatomic, strong) UIColor *leftViewDebuggingColor;
@property (nonatomic, strong) UIColor *rightViewDebuggingColor;
@property (nonatomic, assign) BOOL showSessionBorder;

+ (instancetype)defaultAppearanceLayout;

+ (instancetype)debuggingAppearanceLayout;
@end
