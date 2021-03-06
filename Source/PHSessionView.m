//
//  PHSessionView.m
//  PHAirTransaction
//
//  Created by Ta Phuoc Hai on 1/7/14.
//  Copyright (c) 2014 Phuoc Hai. All rights reserved.
//

#import "PHSessionView.h"
#import "PPImageTitleButton.h"
@implementation PHSessionView

#pragma mark - property

- (PPImageTitleButton*)titleButton
{
    if (!_titleButton) {
        _titleButton = [[PPImageTitleButton alloc] initWithFrame:CGRectZero];
        _titleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self addSubview:_titleButton];
    }
    return _titleButton;
}

- (UIView*)containView
{
    if (!_containView) {
        _containView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_containView];
    }
    return _containView;
}

#pragma mark - clean up

- (void)dealloc
{
    [_titleButton removeFromSuperview];
    _titleButton = nil;
    [_containView removeFromSuperview];
    _containView = nil;
}

@end
