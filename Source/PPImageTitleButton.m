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
    [self.titleLabel  sizeToFit];
    CGRect titleFrame = self.titleLabel.frame;

    if (_constrainImage) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat minSize = MIN(imageFrame.size.width, imageFrame.size.height);
        imageFrame.size = CGSizeMake(minSize, minSize);
    }

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
    imageFrame.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(imageFrame)) / 2;
    titleFrame.origin.x = CGRectGetMaxX(imageFrame) + _titleImagePadding;
    titleFrame.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(titleFrame)) / 2;
    
    self.imageView.frame = imageFrame;
    self.titleLabel.frame = titleFrame;
}
@end
