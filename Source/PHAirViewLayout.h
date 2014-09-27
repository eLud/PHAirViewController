//
//  PHAirViewLayout.h
//  Pods
//
//  Created by Philip Zhao on 9/27/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PHAirViewLayout : NSObject

@property (nonatomic, assign) CGFloat heightForAirMenuRow;
@property (nonatomic, assign) CGFloat heightForAirMenuSection;
@property (nonatomic, assign) CGFloat paddingBetweenAirMenuRow;

@property (nonatomic, assign) CGFloat paddingBetweenTitleAndThumbnailInRow;
@property (nonatomic, assign) CGFloat paddingBetweenTitleAndThumbnailInSection;

+ (instancetype)defaultLayout;
@end
