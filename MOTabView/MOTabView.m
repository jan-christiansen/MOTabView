//
//  MOTabView.m
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
#import "MOScrollView.h"
#import "MOTabView.h"
#import "MOTabContentView.h"


// colors used for the gradient in the background
static const float kLightGrayRed = 0.57;
static const float kLightGrayGreen = 0.63;
static const float kLightGrayBlue = 0.68;

static const float kDarkGrayRed = 0.31;
static const float kDarkGrayGreen = 0.41;
static const float kDarkGrayBlue = 0.48;

static const float kWidthFactor = 0.73;


@implementation MOTabView {

    // cache whehter delegate responds to methods
    BOOL _delegateRespondsToDidSelect;
    BOOL _delegateRespondsToDidDeselect;

    id<MOTabViewDataSource> _dataSource;

    // states whether the current center view is selected
    BOOL _currentViewIsSelected;

    // index of the current center view
    int _currentIndex;

    UIView *_backgroundView;
    MOScrollView *_scrollView;
    UIPageControl *_pageControl;

    MOTabContentView *_leftTabContentView;
    MOTabContentView *_centerTabContentView;
    MOTabContentView *_rightTabContentView;

    MOTabViewEditingStyle _editingStyle;

    // timing function used for scrolling
    CAMediaTimingFunction *_timingFunction;
    
    BOOL _hideFinalTabContentView;
}


@synthesize delegate = _delegate;


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {

    // timing function used to scroll the MOScrollView
    // testing all timing functions of MOScrollView
//    _timingFunction = [CAMediaTimingFunction
//                       functionWithName:kCAMediaTimingFunctionDefault];
//    _timingFunction = [CAMediaTimingFunction
//                       functionWithName:kCAMediaTimingFunctionEaseIn];
//    _timingFunction = [CAMediaTimingFunction
//                       functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    _timingFunction = [CAMediaTimingFunction
//                       functionWithName:kCAMediaTimingFunctionEaseOut];
    _timingFunction = [CAMediaTimingFunction
                       functionWithName:kCAMediaTimingFunctionLinear];

    // background view
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];

    // gradient background
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = _backgroundView.bounds;
    UIColor *lightGray = [UIColor colorWithRed:kLightGrayRed
                                         green:kLightGrayGreen
                                          blue:kLightGrayBlue
                                         alpha:1.0];
    UIColor *darkGray = [UIColor colorWithRed:kDarkGrayRed
                                        green:kDarkGrayGreen
                                         blue:kDarkGrayBlue
                                        alpha:1.0];

    gradientLayer.colors = [NSArray arrayWithObjects:(id) lightGray.CGColor, (id) darkGray.CGColor, nil];
    [_backgroundView.layer addSublayer:gradientLayer];

    [self addSubview:_backgroundView];

    // page control
    CGRect pageControlFrame = CGRectMake(0, 350, 320, 36);
    _pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    _pageControl.numberOfPages = 2;
    _pageControl.hidesForSinglePage = YES;
    _pageControl.defersCurrentPageDisplay = YES;
    [_pageControl addTarget:self
                     action:@selector(changePage:)
           forControlEvents:UIControlEventValueChanged];

    [self insertSubview:_pageControl aboveSubview:_backgroundView];

    // scrollview
    _scrollView = [[MOScrollView alloc] initWithFrame:self.bounds];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.contentSize = self.bounds.size;

#warning hack!
    _scrollView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.01];
    // paging of the scrollview is implemented by using the delegate methods

    [self insertSubview:_scrollView aboveSubview:_pageControl];
}

#pragma Getting and Setting Properties

- (id<MOTabViewDataSource>)dataSource {

    return _dataSource;
}

- (void)setDataSource:(id<MOTabViewDataSource>)dataSource {

    // when the data source is set, views are initializes
    _dataSource = dataSource;

    [self updatePageControl];

    _currentIndex = 0;

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
    _scrollView.contentSize = CGSizeMake((1 + kWidthFactor * (numberOfViews-1)) * self.bounds.size.width,
                                         self.bounds.size.height);

    // initialize center view
    if (numberOfViews > 0) {
        UIView *contentView = [_dataSource tabView:self viewForIndex:0];

        _centerTabContentView = [[MOTabContentView alloc] initWithFrame:self.bounds];
        _centerTabContentView.deletable = YES;
        _centerTabContentView.delegate = self;
        [_centerTabContentView addContentView:contentView];
        [_centerTabContentView selectAnimated:NO];
        _scrollView.scrollEnabled = NO;
        [_scrollView addSubview:_centerTabContentView];

        // initialize right view
        if (numberOfViews > 1) {

            [self addNewRightView];
        }
    }

    _currentViewIsSelected = YES;
}

- (id<MOTabViewDelegate>)delegate {

    return _delegate;
}

- (void)setDelegate:(id<MOTabViewDelegate>)delegate {

    _delegate = delegate;

    _delegateRespondsToDidSelect = [_delegate respondsToSelector:@selector(tabView:didSelectViewAtIndex:)];
    _delegateRespondsToDidDeselect = [_delegate respondsToSelector:@selector(tabViewDidDeselectView:)];

    if (_delegateRespondsToDidSelect) {

        [_delegate tabView:self didSelectViewAtIndex:_currentIndex];
    }
}


#pragma mark - PageControl

- (void)updatePageControl {

    _pageControl.currentPage = _currentIndex;
    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
    _pageControl.numberOfPages = numberOfViews;
}

- (IBAction)changePage:(UIPageControl *)pageControl {

    [self scrollToViewAtIndex:pageControl.currentPage animated:YES];
}


#pragma mark - Gesture Recognizer Actions

// invoked when delete button is pressed
- (void)deleteTabContentView:(MOTabContentView *)tabContentView {

    [self deleteCurrentView];
}

// user tap on one of the three content views
- (void)selectTabContentView:(MOTabContentView *)tabContentView {

    if (tabContentView == _leftTabContentView) {
        [self scrollToViewAtIndex:_currentIndex-1 animated:YES];

    } else if (tabContentView == _centerTabContentView) {
        [self selectCurrentView];

    } else if (tabContentView == _rightTabContentView) {
        [self scrollToViewAtIndex:_currentIndex+1 animated:YES];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {

    // adjust page control
    CGFloat pageWidth = _scrollView.frame.size.width;

    float fractionalIndex = _scrollView.contentOffset.x / pageWidth / kWidthFactor;
    int newIndex = round(fractionalIndex);
    float distance = fabs(round(fractionalIndex) - fractionalIndex);

    //
    int numberOfViews = [_dataSource numberOfViewsInTabView:self];

    if (newIndex >= 0 && newIndex < numberOfViews) {

        if (newIndex != _currentIndex) {

            if (newIndex > _currentIndex) {

                // scroll one view to the right
                [_leftTabContentView removeFromSuperview];

                _leftTabContentView = _centerTabContentView;

                if (newIndex < numberOfViews && !_rightTabContentView) {

                    // add additional view to the right
                    UIView *contentView = [_dataSource tabView:self
                                                  viewForIndex:newIndex];
                    CGRect nextFrame = _centerTabContentView.frame;
                    nextFrame.origin.x += kWidthFactor * self.bounds.size.width;
                    _rightTabContentView = [[MOTabContentView alloc] initWithFrame:nextFrame];
                    _rightTabContentView.deletable = YES;
                    _rightTabContentView.delegate = self;
                    [_rightTabContentView addContentView:contentView];
                    [_rightTabContentView deselectAnimated:NO];
                    _hideFinalTabContentView = YES;
                    _rightTabContentView.alpha = 0;

                    [_scrollView addSubview:_rightTabContentView];
                }
                _centerTabContentView = _rightTabContentView;

                if (newIndex+1 < numberOfViews) {
                    // add additional view to the right
                    UIView *contentView = [_dataSource tabView:self
                                                  viewForIndex:newIndex+1];
                    CGRect nextFrame = _centerTabContentView.frame;
                    nextFrame.origin.x += kWidthFactor * self.bounds.size.width;
                    _rightTabContentView = [[MOTabContentView alloc] initWithFrame:nextFrame];
                    _rightTabContentView.deletable = YES;
                    _rightTabContentView.delegate = self;
                    [_rightTabContentView addContentView:contentView];
                    [_rightTabContentView deselectAnimated:NO];

                    if (_hideFinalTabContentView && newIndex+1 == numberOfViews-1) {
                        _rightTabContentView.alpha = 0;
                    }

                    [_scrollView addSubview:_rightTabContentView];
                } else {
                    _rightTabContentView = nil;
                }

            } else {

                // scroll one view to the left
                [_rightTabContentView removeFromSuperview];

                _rightTabContentView = _centerTabContentView;
                _centerTabContentView = _leftTabContentView;

                //
                if (newIndex-1 >= 0) {
                    // add additional view to the right
                    UIView *contentView = [_dataSource tabView:self
                                                  viewForIndex:newIndex-1];
                    CGRect previousFrame = _centerTabContentView.frame;
                    previousFrame.origin.x -= kWidthFactor * self.bounds.size.width;
                    _leftTabContentView = [[MOTabContentView alloc] initWithFrame:previousFrame];
                    _leftTabContentView.deletable = YES;
                    _leftTabContentView.delegate = self;

                    [_leftTabContentView addContentView:contentView];
                    [_leftTabContentView deselectAnimated:NO];
                    [_scrollView addSubview:_leftTabContentView];
                } else {
                    _leftTabContentView = nil;
                }
            }
            
            _currentIndex = newIndex;
        } else {
            [self updatePageControl];
        }
    }

    _leftTabContentView.visibility = distance;
    _centerTabContentView.visibility = 1-distance;
    _rightTabContentView.visibility = distance;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {

    // user stoped draging and the view does not decelerate
    // case that view decelerates is handled in scrollViewWillBeginDecelerating
    if (!decelerate) {

        CGFloat pageWidth = _scrollView.frame.size.width;
        float ratio = _scrollView.contentOffset.x / pageWidth / kWidthFactor;
        float page = round(ratio);

        [self scrollToViewAtIndex:page animated:YES];
        CGPoint contentOffset = CGPointMake(page * kWidthFactor * self.bounds.size.width, 0);
        [_scrollView setContentOffset:contentOffset
                   withTimingFunction:_timingFunction];
//                             duration:0.5];
//        [_scrollView setContentOffset:contentOffset animated:YES];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

    // adjust page control
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalIndex = scrollView.contentOffset.x / pageWidth / kWidthFactor;
    int index = round(fractionalIndex);

    int nextIndex;
    if (fractionalIndex - _currentIndex > 0) {
        nextIndex = index + 1;
    } else {
        nextIndex = index - 1;
    }

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    if (nextIndex >= 0 && nextIndex < numberOfViews) {
        // stop deceleration
        [scrollView setContentOffset:scrollView.contentOffset animated:YES];

        [self scrollToViewAtIndex:nextIndex animated:YES];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {

    if (_editingStyle == MOTabViewEditingStyleInsert) {
        _editingStyle = MOTabViewEditingStyleNone;
    }

    self.userInteractionEnabled = YES;
    [self updatePageControl];

    if (_hideFinalTabContentView) {
        [UIView animateWithDuration:0.5
                         animations:^{
                             _centerTabContentView.alpha = 1;
                         }
                         completion:^(BOOL finished){
//                             NSLog(@"%d", finished);
                             _hideFinalTabContentView = NO;
                             [self selectCurrentView];
                         }];
    }
}


#pragma mark - 

- (void)scrollToViewAtIndex:(int)newIndex
                   animated:(BOOL)animated {

    self.userInteractionEnabled = NO;

    CGPoint contentOffset = CGPointMake(newIndex * kWidthFactor * self.bounds.size.width, 0);

    float duration;
    if (abs(_currentIndex - newIndex) > 3) {
        duration = 1;
    } else {
        duration = 0.3;
    }
    [_scrollView setContentOffset:contentOffset
               withTimingFunction:_timingFunction
                         duration:duration];
//    [_scrollView setContentOffset:contentOffset animated:YES];
}

- (void)insertNewView {

    _editingStyle = MOTabViewEditingStyleInsert;
    
    int numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    [self.delegate tabView:self
        commitEditingStyle:MOTabViewEditingStyleInsert
            forViewAtIndex:numberOfViews];

    _hideFinalTabContentView = YES;

    [self updatePageControl];

    [self scrollToViewAtIndex:numberOfViews animated:YES];
}

- (void)addNewLeftView {

    if (_currentIndex-1 > 0) {
        // left view
        UIView *contentView = [_dataSource tabView:self
                                      viewForIndex:_currentIndex-1];
        CGRect leftFrame = _centerTabContentView.frame;
        leftFrame.origin.x -= kWidthFactor * self.bounds.size.width;
        _leftTabContentView = [[MOTabContentView alloc] initWithFrame:leftFrame];
        _leftTabContentView.deletable = YES;
        [_leftTabContentView addContentView:contentView];
        _leftTabContentView.delegate = self;
        _leftTabContentView.visibility = 0;
        [_leftTabContentView deselectAnimated:NO];
        [_scrollView addSubview:_leftTabContentView];

    } else {
        _leftTabContentView = nil;
    }
}


- (void)addNewRightView {

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    if (_currentIndex+1 < numberOfViews) {
        // right view
        UIView *contentView = [_dataSource tabView:self
                                      viewForIndex:_currentIndex+1];
        CGRect rightFrame = _centerTabContentView.frame;
        rightFrame.origin.x += kWidthFactor * self.bounds.size.width;
        _rightTabContentView = [[MOTabContentView alloc] initWithFrame:rightFrame];
        _rightTabContentView.deletable = YES;
        [_rightTabContentView addContentView:contentView];
        _rightTabContentView.delegate = self;
        [_rightTabContentView deselectAnimated:NO];
        _rightTabContentView.visibility = 0;
        [_scrollView insertSubview:_rightTabContentView belowSubview:_centerTabContentView];

    } else {
        _rightTabContentView = nil;
    }
}


- (void)addNewCenterViewAnimated:(BOOL)animated {

    UIView *contentView = [_dataSource tabView:self
                                viewForIndex:_currentIndex];
    CGRect centerFrame = _leftTabContentView.frame;
    centerFrame.origin.x += kWidthFactor * self.bounds.size.width;
    _centerTabContentView = [[MOTabContentView alloc] initWithFrame:centerFrame];
    _centerTabContentView.deletable = YES;
    [_centerTabContentView addContentView:contentView];
    _centerTabContentView.alpha = 0;
    _centerTabContentView.delegate = self;
    _centerTabContentView.visibility = 1;
    [_centerTabContentView deselectAnimated:NO];
    [_scrollView addSubview:_centerTabContentView];

    [UIView animateWithDuration:2
                     animations:^{
                         _centerTabContentView.alpha = 1;
                     }];
}


- (void)deleteCurrentView {

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    [UIView animateWithDuration:0.5
                     animations:^{
                         _centerTabContentView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [_centerTabContentView removeFromSuperview];
                         
                         // the previous right view will be the new center view
                         // if we delete the rightmost view _rightTabContentView is nil
                         _centerTabContentView = _rightTabContentView;
                         
                         // inform delegate that view has been deleted
                         [self.delegate tabView:self
                             commitEditingStyle:MOTabViewEditingStyleDelete
                                 forViewAtIndex:_currentIndex];

                         if (_currentIndex == numberOfViews-1) {
                             [self scrollToViewAtIndex:_currentIndex-1 animated:YES];
                         } else {

                             // add new right view
                             [self addNewRightView];

                             [UIView animateWithDuration:0.5
                                              animations:^{
                                                  CGRect newCenterFrame = _centerTabContentView.frame;
                                                  newCenterFrame.origin.x -= kWidthFactor * self.bounds.size.width;
                                                  _centerTabContentView.frame = newCenterFrame;
                                                  _centerTabContentView.visibility = 1;
                                                  CGRect newRightFrame = _rightTabContentView.frame;
                                                  newRightFrame.origin.x -= kWidthFactor * self.bounds.size.width;
                                                  _rightTabContentView.frame = newRightFrame;
                                              }
                                              completion:^(BOOL finished){
                                                  [self updatePageControl];
                                              }];
                         }
                     }];

    // check whether we have deleted the last remaining view
    //    NSInteger numberOfViews = [_dataSource numberOfViewsInSelectionView:self];
    //    if (numberOfViews == 0) {
    //
    //    }
}

- (void)selectCurrentView {

    [_scrollView bringSubviewToFront:_centerTabContentView];
    [_centerTabContentView selectAnimated:YES];
    _scrollView.scrollEnabled = NO;

    if (_delegateRespondsToDidSelect) {
        [_delegate tabView:self didSelectViewAtIndex:_currentIndex];
    }
}

- (void)deselectCurrentView {

    [_centerTabContentView deselectAnimated:YES];
    [self bringSubviewToFront:_pageControl];
    _scrollView.scrollEnabled = YES;

    if (_delegateRespondsToDidDeselect) {
        [_delegate tabViewDidDeselectView:self];
    }
}

@end
