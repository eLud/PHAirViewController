//
//  PPSubImageButton.m
//  TestLabel
//
//  Created by Philip Zhao on 9/26/14.
//  Copyright (c) 2014 PP. All rights reserved.
//

#import "PPImageTitleButton.h"

@implementation PPImageTitleButton

- (void)setImageForSingleState:(UIImage *)image
{
    [self setImage:image forState:UIControlStateNormal];
    [self setImage:image forState:UIControlStateHighlighted];
    [self setImage:image forState:UIControlStateSelected];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize bsize = [super sizeThatFits:size];
    bsize.width += _titleImagePadding;
    return bsize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect imageFrame = self.imageView.frame;
    CGRect titleFrame = self.titleLabel.frame;

    CGFloat xStartingPoint = 0;
    switch (_buttonContentMode) {
        case PPImageTitleButtonContentModeCenter:
            xStartingPoint = (CGRectGetWidth(self.bounds) - CGRectGetWidth(imageFrame) - CGRectGetWidth(titleFrame) - _titleImagePadding) / 2;
            break;
        case PPImageTitleButtonContentModeLeft:
            xStartingPoint = 0;
            break;
        case PPImageTitleButtonContentModeRight:
            xStartingPoint = CGRectGetWidth(self.bounds) - CGRectGetWidth(imageFrame) - CGRectGetWidth(titleFrame) - _titleImagePadding;
            break;
    }
    
    imageFrame.origin.x = xStartingPoint;
    titleFrame.origin.x = CGRectGetMaxX(imageFrame) + _titleImagePadding;
    
    self.imageView.frame = imageFrame;
    self.titleLabel.frame = titleFrame;
}
@end
