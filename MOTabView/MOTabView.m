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
    BOOL _delegateRespondsToWillSelect;
    BOOL _delegateRespondsToWillDeselect;
    BOOL _delegateRespondsToDidSelect;
    BOOL _delegateRespondsToDidDeselect;
    BOOL _delegateRespondsToWillEdit;
    BOOL _delegateRespondsToDidEdit;

    id<MOTabViewDataSource> _dataSource;

    // index of the current center view
    int _currentIndex;

    UIView *_backgroundView;
    MOScrollView *_scrollView;
    UIPageControl *_pageControl;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;

    MOTabContentView *_leftTabContentView;
    MOTabContentView *_centerTabContentView;
    MOTabContentView *_rightTabContentView;

    MOTabViewEditingStyle _editingStyle;

    // timing functions used for scrolling
    CAMediaTimingFunction *_easeInEaseOutTimingFunction;
    CAMediaTimingFunction *_easeOutTimingFunction;
    CAMediaTimingFunction *_easeInTimingFunction;

    // if true the last view is hidden when scrolling
    BOOL _hideLastTabContentView;
}


@synthesize delegate = _delegate;
@synthesize addingStyle = _addingStyle;


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
    _easeInEaseOutTimingFunction = [CAMediaTimingFunction
                                    functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    _easeOutTimingFunction = [CAMediaTimingFunction
                              functionWithName:kCAMediaTimingFunctionEaseOut];
    _easeInTimingFunction = [CAMediaTimingFunction
                             functionWithName:kCAMediaTimingFunctionEaseIn];

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

    // title label
    CGRect titleFrame = CGRectMake(10, 19, self.bounds.size.width-20, 40);
    _titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.backgroundColor = [UIColor clearColor];
    UIColor *shadowColor = [UIColor colorWithRed:0.4
                                           green:0.47
                                            blue:0.51
                                           alpha:1];
    _titleLabel.shadowColor = [UIColor darkGrayColor];
    _titleLabel.shadowOffset = CGSizeMake(0, -1);
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    [self insertSubview:_titleLabel aboveSubview:_backgroundView];

    // subtitle label
    CGRect subtitleFrame = CGRectMake(10, 46, self.bounds.size.width-20, 40);
    _subtitleLabel = [[UILabel alloc] initWithFrame:subtitleFrame];
    UIColor *subtitleColor = [UIColor colorWithRed:0.76
                                             green:0.8
                                              blue:0.83
                                             alpha:1];
    _subtitleLabel.textColor = subtitleColor;
    _subtitleLabel.backgroundColor = [UIColor clearColor];
    _subtitleLabel.shadowColor = shadowColor;
    _subtitleLabel.shadowOffset = CGSizeMake(0, -1);
    _subtitleLabel.textAlignment = UITextAlignmentCenter;
    _subtitleLabel.font = [UIFont systemFontOfSize:14];
    _subtitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    [self insertSubview:_subtitleLabel aboveSubview:_backgroundView];

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
    _scrollView.scrollEnabled = NO;

// TODO: Remove this hack
    _scrollView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.01];
    // paging of the scrollview is implemented by using the delegate methods
    [self insertSubview:_scrollView aboveSubview:_titleLabel];

    // standard adding style is the one used by safari prior to iOS6
    _addingStyle = MOTabViewAddingAtLastIndex;
}


#pragma Getting and Setting Properties

- (id<MOTabViewDataSource>)dataSource {

    return _dataSource;
}

- (void)setDataSource:(id<MOTabViewDataSource>)dataSource {

    // when the data source is set, views are initialized
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
        _centerTabContentView.delegate = self;
        _centerTabContentView.contentView = contentView;
        [_centerTabContentView selectAnimated:NO];
        [_scrollView addSubview:_centerTabContentView];
        [self updateTitles];

        // initialize right view
        _rightTabContentView = [self tabContentViewAtIndex:_currentIndex+1];
    }
}

- (id<MOTabViewDelegate>)delegate {

    return _delegate;
}

- (void)setDelegate:(id<MOTabViewDelegate>)delegate {

    _delegate = delegate;

    // save whether the delegate responds to the delegate methods
    _delegateRespondsToWillSelect = [_delegate respondsToSelector:@selector(tabView:willSelectViewAtIndex:)];
    _delegateRespondsToWillDeselect = [_delegate respondsToSelector:@selector(tabViewWillDeselectView:)];
    _delegateRespondsToDidSelect = [_delegate respondsToSelector:@selector(tabView:didSelectViewAtIndex:)];
    _delegateRespondsToDidDeselect = [_delegate respondsToSelector:@selector(tabViewDidDeselectView:)];
    _delegateRespondsToWillEdit = [_delegate respondsToSelector:@selector(tabView:willEditView:atIndex:)];
    _delegateRespondsToDidEdit = [_delegate respondsToSelector:@selector(tabView:didEditView:atIndex:)];

    [self tabViewWillSelectView];
    [self tabViewDidDeselectView];
}


#pragma mark - Informing the Delegate

- (void)tabViewWillSelectView {

    if (_delegateRespondsToWillSelect) {
        [_delegate tabView:self willSelectViewAtIndex:_currentIndex];
    }
}

- (void)tabViewDidSelectView {

    if (_delegateRespondsToDidSelect) {
        [_delegate tabView:self didSelectViewAtIndex:_currentIndex];
    }
}

- (void)tabViewWillDeselectView {

    if (_delegateRespondsToWillDeselect) {
        [_delegate tabViewWillDeselectView:self];
    }
}

- (void)tabViewDidDeselectView {

    if (_delegateRespondsToDidSelect) {
        [_delegate tabViewDidDeselectView:self];
    }
}

- (void)tabViewWillEditView {

    if (_delegateRespondsToWillEdit) {
        [_delegate tabView:self willEditView:_editingStyle atIndex:_currentIndex];
    }
}

- (void)tabViewDidEditView {

    if (_delegateRespondsToDidEdit) {
        [_delegate tabView:self didEditView:_editingStyle atIndex:_currentIndex];
    }
}


#pragma mark - Updating Titles

- (void)updateTitles {

    _titleLabel.text = [_dataSource titleForIndex:_currentIndex];
    _subtitleLabel.text = [_dataSource subtitleForIndex:_currentIndex];
}


#pragma mark - UIPageControl Methods

- (void)updatePageControl {

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
    _pageControl.numberOfPages = numberOfViews;
    _pageControl.currentPage = _currentIndex;
}

- (IBAction)changePage:(UIPageControl *)pageControl {

    [self scrollToViewAtIndex:pageControl.currentPage
           withTimingFunction:_easeInEaseOutTimingFunction
                     duration:0.5];
}


#pragma mark - TabContentViewDelegate Methods

// invoked when delete button is pressed
- (void)tabContentViewDidTapDelete:(MOTabContentView *)tabContentView {

    [self deleteCurrentView];
}

// user tap on one of the three content views
- (void)tabContentViewDidTapView:(MOTabContentView *)tabContentView {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (tabContentView == _leftTabContentView) {
        [self scrollToViewAtIndex:_currentIndex-1
               withTimingFunction:_easeInEaseOutTimingFunction
                         duration:0.5];
    } else if (tabContentView == _centerTabContentView) {
        [self selectCurrentView];
    } else if (tabContentView == _rightTabContentView) {
        [self scrollToViewAtIndex:_currentIndex+1
               withTimingFunction:_easeInEaseOutTimingFunction
                         duration:0.5];
    }
}

- (void)tabContentViewDidSelect:(MOTabContentView *)tabContentView {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self tabViewDidSelectView];

    // selecting the view may be the last step in inserting a new tab
    if (_editingStyle == MOTabViewEditingStyleInsert) {
        [self tabViewDidEditView];
    }
}

- (void)tabContentViewDidDeselect:(MOTabContentView *)tabContentView {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self tabViewDidDeselectView];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    CGFloat pageWidth = _scrollView.frame.size.width;
    float fractionalIndex = _scrollView.contentOffset.x / pageWidth / kWidthFactor;
    int newIndex = round(fractionalIndex);

    //
    int numberOfViews = [_dataSource numberOfViewsInTabView:self];

    if (newIndex >= 0 && newIndex < numberOfViews) {

        if (newIndex > _currentIndex) {

            _currentIndex = newIndex;

            [self updateTitles];

            // scroll one view to the right
            [_leftTabContentView removeFromSuperview];

            _leftTabContentView = _centerTabContentView;
            _centerTabContentView = _rightTabContentView;

            // add additional view to the right
            _rightTabContentView = [self tabContentViewAtIndex:newIndex+1];

            // if right view was just added by insert, hide it
            if (_hideLastTabContentView && newIndex+1 == numberOfViews-1) {
                _rightTabContentView.hidden = YES;
                _hideLastTabContentView = NO;
            }

        } else if (newIndex < _currentIndex) {

            _currentIndex = newIndex;

            [self updateTitles];

            // scroll one view to the left
            [_rightTabContentView removeFromSuperview];

            _rightTabContentView = _centerTabContentView;
            _centerTabContentView = _leftTabContentView;

            //
            _leftTabContentView = [self tabContentViewAtIndex:newIndex-1];
        } else {
            [self updatePageControl];
        }
    }

    float distance = fabs(round(fractionalIndex) - fractionalIndex);
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
        int page = round(ratio);

        [self scrollToViewAtIndex:page
               withTimingFunction:_easeOutTimingFunction
                         duration:0.3];
//        CGPoint contentOffset = CGPointMake(page * kWidthFactor * self.bounds.size.width, 0);
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

        // scroll view to next index
        [self scrollToViewAtIndex:nextIndex
               withTimingFunction:_easeOutTimingFunction
                         duration:0.2];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.userInteractionEnabled = YES;
    [self updatePageControl];

    if (_centerTabContentView.hidden) {

        _centerTabContentView.alpha = 0;
        _centerTabContentView.hidden = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             _centerTabContentView.alpha = 1;
                         }
                         completion:^(BOOL finished){
                             [self selectCurrentView];
                         }];
    }

    if (_editingStyle == MOTabViewEditingStyleInsert) {
        _editingStyle = MOTabViewEditingStyleNone;
    }
}


#pragma mark - 

- (void)scrollToViewAtIndex:(int)newIndex
         withTimingFunction:(CAMediaTimingFunction *)timingFunction
                   duration:(CFTimeInterval)duration {

    self.userInteractionEnabled = NO;

    CGPoint contentOffset = CGPointMake(newIndex * kWidthFactor * self.bounds.size.width, 0);

    [_scrollView setContentOffset:contentOffset
               withTimingFunction:timingFunction
                         duration:duration];
//    [_scrollView setContentOffset:contentOffset animated:YES];
}

- (void)insertNewView {

    _editingStyle = MOTabViewEditingStyleInsert;

    CGSize newContentSize;
    newContentSize.width = _scrollView.contentSize.width + kWidthFactor * _scrollView.bounds.size.width;
    newContentSize.height = _scrollView.contentSize.height;
    _scrollView.contentSize = newContentSize;

    // index where new tab is added
    int newIndex;
    if (_addingStyle == MOTabViewAddingAtLastIndex) {
        int numberOfViews = [self.dataSource numberOfViewsInTabView:self];
        newIndex = numberOfViews;
    } else if (_addingStyle == MOTabViewAddingAtNextIndex) {
        newIndex = _currentIndex + 1;
    }

    // inform delegate to update model
    [_delegate tabView:self
          willEditView:_editingStyle
               atIndex:newIndex];

    if (_addingStyle == MOTabViewAddingAtLastIndex) {

        _hideLastTabContentView = YES;

        if (_currentIndex + 1 == newIndex) {
            _rightTabContentView = [self tabContentViewAtIndex:newIndex];
            _rightTabContentView.hidden = YES;
        }

        CFTimeInterval duration;
        if (abs(newIndex - _currentIndex) > 3) {
            duration = 1;
        } else {
            duration = 0.5;
        }

        [self scrollToViewAtIndex:newIndex
               withTimingFunction:_easeInTimingFunction
                         duration:duration];

    } else if (_addingStyle == MOTabViewAddingAtNextIndex) {

        // move all three views to the right
        CGRect newLeftFrame = _leftTabContentView.frame;
        newLeftFrame.origin.x += kWidthFactor * self.bounds.size.width;
        _leftTabContentView.frame = newLeftFrame;
        CGRect newCenterFrame = _centerTabContentView.frame;
        newCenterFrame.origin.x += kWidthFactor * self.bounds.size.width;
        _centerTabContentView.frame = newCenterFrame;
        CGRect newRightFrame = _rightTabContentView.frame;
        newRightFrame.origin.x += kWidthFactor * self.bounds.size.width;
        _rightTabContentView.frame = newRightFrame;

        // and increase the offset by the same factor
        // we set the bounds of the scrollview and not the contentOffset to
        // not inform the delegate
        CGRect newBounds = _scrollView.bounds;
        newBounds.origin.x = _scrollView.bounds.origin.x + kWidthFactor * _scrollView.bounds.size.width;
        _scrollView.bounds = newBounds;

        // this way we can later move the left and the center view to the left
        // and make room for a new tab

        _currentIndex = _currentIndex + 1;
        [self updatePageControl];

        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect newLeftFrame = _leftTabContentView.frame;
                             newLeftFrame.origin.x -= kWidthFactor * self.bounds.size.width;
                             _leftTabContentView.frame = newLeftFrame;
                             _leftTabContentView.visibility = 1;
                             CGRect newCenterFrame = _centerTabContentView.frame;
                             newCenterFrame.origin.x -= kWidthFactor * self.bounds.size.width;
                             _centerTabContentView.frame = newCenterFrame;
                             _centerTabContentView.visibility = 0;
                         }
                         completion:^(BOOL finished){

                             // after changing frames the center view becomes
                             // the left view
                             [_leftTabContentView removeFromSuperview];
                             _leftTabContentView = _centerTabContentView;
                             _centerTabContentView = nil;

// TODO: revise this code
                             MOTabView *temp = self;
                             [self addNewCenterViewAnimated:YES
                                                 completion:^(BOOL finished) {
                                                     [temp selectCurrentView];
                                                 }];
                         }];

    }
}

- (CGRect)newFrame:(CGRect)frame forIndex:(int)index {

    int factor = index - _currentIndex;
    CGRect newFrame = frame;
    newFrame.origin.x = newFrame.origin.x + factor * kWidthFactor * self.bounds.size.width;
    return newFrame;
}

- (MOTabContentView *)tabContentViewAtIndex:(int)index {

    NSInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];
    MOTabContentView *tabContentView = nil;

    if (index >= 0 && index < numberOfViews) {
        UIView *contentView = [_dataSource tabView:self viewForIndex:index];
        CGRect newFrame = [self newFrame:_centerTabContentView.frame forIndex:index];
        tabContentView = [[MOTabContentView alloc] initWithFrame:newFrame];
        tabContentView.contentView = contentView;
        tabContentView.delegate = self;
        tabContentView.visibility = 0;
        [_scrollView insertSubview:tabContentView belowSubview:_centerTabContentView];
    }

    return tabContentView;
}

// TODO: actually use this method
- (void)addNewCenterViewAnimated:(BOOL)animated
                      completion:(void (^)(BOOL finished))completion {

    UIView *contentView = [_dataSource tabView:self
                                  viewForIndex:_currentIndex];
    CGRect centerFrame = _leftTabContentView.frame;
    centerFrame.origin.x += kWidthFactor * self.bounds.size.width;
    _centerTabContentView = [[MOTabContentView alloc] initWithFrame:centerFrame];
    _centerTabContentView.delegate = self;
    _centerTabContentView.contentView = contentView;
    _centerTabContentView.visibility = 1;
    _centerTabContentView.alpha = 0;
    [_scrollView addSubview:_centerTabContentView];

    [UIView animateWithDuration:0.5
                     animations:^{
                         _centerTabContentView.alpha = 1;
                     }
                     completion:completion];
}


- (void)deleteCurrentView {

    _editingStyle = MOTabViewEditingStyleDelete;

    NSInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    // inform delegate that view will be deleted
    [self tabViewWillEditView];

    [UIView animateWithDuration:0.5
                     animations:^{
                         _centerTabContentView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [_centerTabContentView removeFromSuperview];

                         // the previous right view will be the new center view
                         // if we delete the rightmost view _rightTabContentView is nil
                         _centerTabContentView = _rightTabContentView;

                         if (_currentIndex == numberOfViews-1) {
                             [self scrollToViewAtIndex:_currentIndex-1
                                    withTimingFunction:_easeInEaseOutTimingFunction
                                              duration:0.5];
                         } else {

                             // add new right view
                             _rightTabContentView = [self tabContentViewAtIndex:_currentIndex+1];

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
                                                  [self tabViewDidEditView];
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

    [self tabViewWillSelectView];

    [_scrollView bringSubviewToFront:_centerTabContentView];
    [_centerTabContentView selectAnimated:YES];
    _scrollView.scrollEnabled = NO;
}

- (void)deselectCurrentView {

    [self tabViewWillDeselectView];

    [_centerTabContentView deselectAnimated:YES];
    [self bringSubviewToFront:_pageControl];
    _scrollView.scrollEnabled = YES;
}

- (UIView *)viewForIndex:(NSInteger)index {

    if (index == _currentIndex) {
        return _centerTabContentView.contentView;
    } else if (index-1 == _currentIndex) {
        return _rightTabContentView.contentView;
    } else if (index+1 == _currentIndex) {
        return _leftTabContentView.contentView;
    } else {
        return nil;
    }
}

- (UIView *)selectedView {
    
    if (_centerTabContentView.isSelected) {
        return _centerTabContentView.contentView;
    } else {
        return nil;
    }
}


@end
