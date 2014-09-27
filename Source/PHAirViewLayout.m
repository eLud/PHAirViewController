//
//  PHAirViewLayout.m
//  Pods
//
//  Created by Philip Zhao on 9/27/14.
//
//

#import "PHAirViewLayout.h"

@implementation PHAirViewLayout

+ (instancetype)defaultLayout
{
    PHAirViewLayout *l = [PHAirViewLayout new];
    l.heightForAirMenuRow = 44;
    return l;
}
@end
