//
//  PPSubImageButton.h
//  TestLabel
//
//  Created by Philip Zhao on 9/26/14.
//  Copyright (c) 2014 PP. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PPImageTitleButtonContentModeLeft,
    PPImageTitleButtonContentModeCenter,
    PPImageTitleButtonContentModeRight,
} PPImageTitleButtonContentMode;

@interface PPImageTitleButton : UIButton
@property (nonatomic, assign) CGFloat titleImagePadding;
@property (nonatomic, assign) PPImageTitleButtonContentMode buttonContentMode;

@property (nonatomic, assign) BOOL constrainImage;

- (void)setImageForSingleState:(UIImage *)image;
@end
