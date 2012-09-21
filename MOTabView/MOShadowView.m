//
//  MOShadowView.m
//  MOTabView
//
//  Created by Jan Christiansen on 9/21/12.
//  Copyright (c) 2012 Monoid - Development and Consulting - Jan Christiansen. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MOShadowView.h"


@implementation MOShadowView


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shadowOffset = CGSizeMake(1, 8);
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.layer.bounds].CGPath;
    }
    return self;
}


#pragma mark - Layout

- (void)layoutSubviews {

    [super layoutSubviews];

    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.layer.bounds].CGPath;
}


@end
