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

// Appearance
@property (nonatomic, strong) UIColor * titleNormalColor;
@property (nonatomic, strong) UIColor * titleHighlightColor;
@property (nonatomic, strong) UIColor * titleSelectedColor;

@property (nonatomic, strong) UIColor * sectionTitleColor;

@property (nonatomic, strong) UIFont *sectionTitleFont;
@property (nonatomic, strong) UIFont *rowTitleFont;

// Layout
@property (nonatomic, assign) CGFloat heightAirMenuRow;
@property (nonatomic, assign) CGFloat heightAirMenuSection;

@property (nonatomic, assign) CGFloat paddingBetweenThumbnailAndTitleInSection;
@property (nonatomic, assign) CGFloat paddingBetweenThumbnailAndTitleInRow;

@property (nonatomic, assign) CGFloat sessionViewLeftPadding;
@property (nonatomic, assign) PHAirViewAppearanceLayoutContentMode rowsContentMode; /** Only allow Top and Center */
@property (nonatomic, assign) UIEdgeInsets rowsEdgeInsets; // only left would use; top would apply if rowsContentMode set to Top
@property (nonatomic, assign) CGFloat paddingBetweenRows;

@property (nonatomic, assign) PHAirViewAppearanceLayoutContentMode sectionContentMode; /** Allow all values*/
@property (nonatomic, assign) UIEdgeInsets sectionEdgeInsets;
@property (nonatomic, assign) CGFloat sectionContentHeight;

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation statusBarAnimation;

// by default it is the screen size
@property (nonatomic, assign) CGFloat interactiveGestureBaseValueInPixel;

@property (nonatomic, assign) BOOL enableLeftViewBouncinessWithOnlyOneSession;

// Debugging session
@property (nonatomic, strong) UIColor *leftViewDebuggingColor;
@property (nonatomic, strong) UIColor *rightViewDebuggingColor;
+ (instancetype)defaultAppearanceLayout;

+ (instancetype)debuggingAppearanceLayout;
@end
