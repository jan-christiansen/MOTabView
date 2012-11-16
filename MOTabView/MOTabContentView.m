//
//  MOTabContentView.m
//  MOTabView
//
//  Created by Jan Christiansen on 6/20/12.
//  Copyright (c) 2012, Monoid - Development and Consulting - Jan Christiansen
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following
//  disclaimer in the documentation and/or other materials provided
//  with the distribution.
//
//  * Neither the name of Monoid - Development and Consulting - 
//  Jan Christiansen nor the names of other
//  contributors may be used to endorse or promote products derived
//  from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <QuartzCore/QuartzCore.h>

#import "MOTabContentView.h"
#import "MOShadowView.h"


static const CGFloat kDeselectedScale = 0.6f;
static const CGFloat kDeselectedOriginY = 20;


@implementation MOTabContentView {

    UIView *_containerView;
    UIView *_contentView;

    UIButton *_deleteButton;

    float _visibility;

    UITapGestureRecognizer *_tapRecognizer;
}


#pragma mark - Intialization

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        // a container which is scaled
        _containerView = [[MOShadowView alloc] initWithFrame:self.bounds];
//        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_containerView];

        _tapRecognizer = [[UITapGestureRecognizer alloc]
                          initWithTarget:self
                          action:@selector(handleTap)];
        [_containerView addGestureRecognizer:_tapRecognizer];

        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.frame = CGRectMake(0, 0, 30, 30);
        [_deleteButton setImage:[UIImage imageNamed:@"closeButton"]
                       forState:UIControlStateNormal];
        [_deleteButton addTarget:self
                          action:@selector(handleClose)
                forControlEvents:UIControlEventTouchUpInside];
        _deleteButton.center = self.frame.origin;
        _deleteButton.alpha = 0;
        [self insertSubview:_deleteButton aboveSubview:_containerView];

        [self deselectNonAnimated];
    }
    return self;
}


#pragma mark - Getting and Setting Properties

- (CGRect)frame {

    return super.frame;
}

- (void)setFrame:(CGRect)frame {

    _containerView.transform = CGAffineTransformIdentity;

    super.frame = frame;

    if (!_isSelected) {
        float deselectedTranslation = kDeselectedOriginY - frame.origin.y;
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, deselectedTranslation);
        CGAffineTransform transform = CGAffineTransformScale(translation, kDeselectedScale, kDeselectedScale);
        _containerView.transform = transform;
    }

    [self recenterDeleteButton];
}

- (float)visibility {

    return _visibility;
}

- (void)setVisibility:(float)visibility {

    _visibility = visibility;
    _deleteButton.alpha = visibility;
    self.alpha = MAX(visibility, 0.5);
}

- (UIView *)contentView {

    return _contentView;
}

- (void)setContentView:(UIView *)contentView {

    // if user interactions are disabled (because the view is minimized/deselected)
    // we have to disable the interactions of the new content view as well
    contentView.userInteractionEnabled = _contentView.userInteractionEnabled;

    // we remove the old content view  and add the new one
    [_contentView removeFromSuperview];
    _contentView = contentView;
    [_containerView addSubview:_contentView];
}


#pragma mark - Handling Actions

- (void)handleTap {

    [_delegate tabContentViewDidTapView:self];
}

- (void)handleClose {

    [self.delegate tabContentViewDidTapDelete:self];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)__unused event {

    return ((CGRectContainsPoint(_deleteButton.frame, point)
             || CGRectContainsPoint(_containerView.frame, point)));
}


#pragma mark - Utility Methods

- (void)recenterDeleteButton {

    CGPoint newCenter = CGPointMake(_containerView.frame.origin.x,
                                    _containerView.frame.origin.y);
    _deleteButton.center = newCenter;
}


#pragma mark - Selecting and Deselecting

- (void)selectAnimated:(BOOL)animated {

    [self recenterDeleteButton];

    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [self selectNonAnimated];
                         }
                         completion:^(BOOL __unused finished) {
                             _tapRecognizer.enabled = NO;
                             [_delegate tabContentViewDidSelect:self];
                         }];
    } else {
        [self selectNonAnimated];
        _tapRecognizer.enabled = NO;
        [_delegate tabContentViewDidSelect:self];
    }

    _isSelected = YES;
}

- (void)selectNonAnimated {

    _containerView.transform = CGAffineTransformIdentity;

    [self recenterDeleteButton];
    _deleteButton.alpha = 0;

    _contentView.userInteractionEnabled = YES;
}

- (void)deselectAnimated:(BOOL)animated {

    [self recenterDeleteButton];

    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [self deselectNonAnimated];
                         }
                         completion:^(BOOL __unused finished){
                             _tapRecognizer.enabled = YES;
                             [_delegate tabContentViewDidDeselect:self];
                         }];
    } else {
        [self deselectNonAnimated];
        _tapRecognizer.enabled = YES;
        [_delegate tabContentViewDidDeselect:self];
    }

    _isSelected = NO;
}

- (void)deselectNonAnimated {

    float deselectedTranslation = kDeselectedOriginY - self.frame.origin.y;
    CGAffineTransform translation = CGAffineTransformMakeTranslation(0, deselectedTranslation);
    CGAffineTransform transform = CGAffineTransformScale(translation, kDeselectedScale, kDeselectedScale);
    _containerView.transform = transform;

    [self recenterDeleteButton];
    _deleteButton.alpha = 1;

    _contentView.userInteractionEnabled = NO;
}


@end
