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
static const CGFloat kLightGrayRed = 0.57f;
static const CGFloat kLightGrayGreen = 0.63f;
static const CGFloat kLightGrayBlue = 0.68f;

static const CGFloat kDarkGrayRed = 0.31f;
static const CGFloat kDarkGrayGreen = 0.41f;
static const CGFloat kDarkGrayBlue = 0.48f;

static const CGFloat kWidthFactor = 0.73f;


@implementation MOTabView {

    id _delegate;

    // cache whehter delegate responds to methods
    BOOL _delegateRespondsToWillSelect;
    BOOL _delegateRespondsToWillDeselect;
    BOOL _delegateRespondsToDidSelect;
    BOOL _delegateRespondsToDidDeselect;
    BOOL _delegateRespondsToWillEdit;
    BOOL _delegateRespondsToDidEdit;

    id<MOTabViewDataSource> _dataSource;

    // index of the current center view
    NSUInteger _currentIndex;

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

    BOOL _navigationBarHidden;

    // y component of contentOffset, saved if content views are table views
    NSMutableArray *_offsets;
}


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

    gradientLayer.colors = @[(id) lightGray.CGColor, (id) darkGray.CGColor];
    [_backgroundView.layer addSublayer:gradientLayer];
    [self addSubview:_backgroundView];

    // title label
    CGRect titleFrame = CGRectMake(10, 19, self.bounds.size.width-20, 40);
    _titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.backgroundColor = [UIColor clearColor];
    UIColor *shadowColor = [UIColor colorWithRed:0.4f
                                           green:0.47f
                                            blue:0.51f
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
    UIColor *subtitleColor = [UIColor colorWithRed:0.76f
                                             green:0.8f
                                              blue:0.83f
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

    _navigationBarHidden = YES;

    _offsets = @[].mutableCopy;
}

- (MOTabContentView *)tabContentView {

    CGRect contentViewFrame = self.frame;
    if (!_navigationBarHidden) {
        // if the navigation bar is shown the content is offset
        contentViewFrame.origin.y += _navigationBar.bounds.size.height;
    }
    return [[MOTabContentView alloc] initWithFrame:contentViewFrame];
}


#pragma mark - Getting and Setting Properties

- (BOOL)navigationBarHidden {

    return _navigationBarHidden;
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden {

    _navigationBarHidden = navigationBarHidden;

    if (!_navigationBarHidden) {
        CGRect navigationBarFrame = CGRectMake(0, 0, self.bounds.size.width, 44);
        _navigationBar = [[UINavigationBar alloc] initWithFrame:navigationBarFrame];
        UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:@""];
        [_navigationBar pushNavigationItem:item animated:NO];
        [self addSubview:_navigationBar];

//        probably necessary if dataSource is not already set
//        
//        CGRect newLeftFrame = _leftTabContentView.frame;
//        newLeftFrame.origin.y = newLeftFrame.origin.y + 44;
//        _leftTabContentView.frame = newLeftFrame;
//
//        CGRect newCenterFrame = _centerTabContentView.frame;
//        newCenterFrame.origin.y = newCenterFrame.origin.y + 44;
//        _centerTabContentView.frame = newCenterFrame;
//
//        CGRect newRightFrame = _rightTabContentView.frame;
//        newRightFrame.origin.y = newRightFrame.origin.y + 44;
//        _rightTabContentView.frame = newRightFrame;
    }
}

- (id<MOTabViewDataSource>)dataSource {

    return _dataSource;
}

- (void)setDataSource:(id<MOTabViewDataSource>)dataSource {

    // when the data source is set, views are initialized
    _dataSource = dataSource;

    [self updatePageControl];

    _currentIndex = 0;

    if (!_navigationBarHidden) {
        _navigationBar.topItem.title = [self.dataSource titleForIndex:_currentIndex];
    }

    NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    for (int i = 0; i < (NSInteger)numberOfViews; i++) {
        [_offsets addObject:[NSNumber numberWithFloat:0]];
    }

    _scrollView.contentSize = CGSizeMake((1 + kWidthFactor * (numberOfViews-1)) * self.bounds.size.width,
                                         self.bounds.size.height);

    // initialize center view
    if (numberOfViews > 0) {
        UIView *contentView = [_dataSource tabView:self viewForIndex:0];
        _centerTabContentView = [self tabContentView];
        _centerTabContentView.delegate = self;
        _centerTabContentView.contentView = contentView;
        [_scrollView addSubview:_centerTabContentView];
        [self selectCurrentViewAnimated:NO];
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
    _delegateRespondsToWillDeselect = [_delegate respondsToSelector:@selector(tabView:willDeselectViewAtIndex:)];
    _delegateRespondsToDidSelect = [_delegate respondsToSelector:@selector(tabView:didSelectViewAtIndex:)];
    _delegateRespondsToDidDeselect = [_delegate respondsToSelector:@selector(tabView:didDeselectViewAtIndex:)];
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

//    // if content view is a table view, the navigation bar becomes table header
//    if ([_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {
//        UITableView *tableView = (UITableView *)_centerTabContentView.contentView;
//        tableView.contentOffset = CGPointMake(0, -_navigationBar.frame.origin.y + tableView.contentOffset.y);
//        [_navigationBar removeFromSuperview];
//        CGRect newFrame = _centerTabContentView.frame;
//        newFrame.origin.y -= _navigationBar.frame.origin.y + _navigationBar.bounds.size.height;
//        _centerTabContentView.frame = newFrame;
//        tableView.tableHeaderView = _navigationBar;
//    }

    if (!_navigationBarHidden && [_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)_centerTabContentView.contentView;

        CGRect navigationBarFrame = _navigationBar.frame;
        navigationBarFrame.origin.y = 0;
        _navigationBar.frame = navigationBarFrame;

        CGRect centerFrame = _centerTabContentView.frame;
        centerFrame.origin.y = 0;
        _centerTabContentView.frame = centerFrame;

        [_navigationBar removeFromSuperview];
        tableView.tableHeaderView = _navigationBar;

        NSNumber *offsetNumber = [_offsets objectAtIndex:_currentIndex];
        float offset = offsetNumber.floatValue;
        tableView.contentOffset = CGPointMake(0, offset);
    }

    if (_delegateRespondsToDidSelect) {
        [_delegate tabView:self didSelectViewAtIndex:_currentIndex];
    }

    // selecting the view may be the last step in inserting a new tab
    if (_editingStyle == MOTabViewEditingStyleInsert) {
        [self tabViewDidEditView];
    }
}

- (void)tabViewWillDeselectView {

    if (_delegateRespondsToWillDeselect) {
        [_delegate tabView:self willDeselectViewAtIndex:_currentIndex];
    }
}

- (void)tabViewDidDeselectView {

    [self bringSubviewToFront:_pageControl];
    
    if (_delegateRespondsToDidDeselect) {
        [_delegate tabView:self didDeselectViewAtIndex:_currentIndex];
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

    NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
    _pageControl.numberOfPages = numberOfViews;
    _pageControl.currentPage = _currentIndex;
}

- (IBAction)changePage:(UIPageControl *)pageControl {

    [self scrollToViewAtIndex:(NSUInteger) pageControl.currentPage
           withTimingFunction:_easeInEaseOutTimingFunction
                     duration:0.5];
}


#pragma mark - TabContentViewDelegate Methods

// invoked when delete button is pressed
- (void)tabContentViewDidTapDelete:(MOTabContentView *)__unused tabContentView {

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
        [self selectCurrentViewAnimated:YES];
    } else if (tabContentView == _rightTabContentView) {
        [self scrollToViewAtIndex:_currentIndex+1
               withTimingFunction:_easeInEaseOutTimingFunction
                         duration:0.5];
    }
}

//- (void)tabContentViewDidSelect:(MOTabContentView *)__unused tabContentView {
//
////    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [self tabViewDidSelectView];
//
//    // selecting the view may be the last step in inserting a new tab
//    if (_editingStyle == MOTabViewEditingStyleInsert) {
//        [self tabViewDidEditView];
//    }
//}

//- (void)tabContentViewDidDeselect:(MOTabContentView *)__unused tabContentView {
//
////    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [self bringSubviewToFront:_pageControl];
//
//    [self tabViewDidDeselectView];
//}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat fractionalIndex = scrollView.contentOffset.x / pageWidth / kWidthFactor;
    NSInteger potentialIndex = (NSInteger) roundf(fractionalIndex);

    //
    NSUInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];

    if (potentialIndex >= 0 && potentialIndex < (NSInteger) numberOfViews) {

        NSUInteger newIndex = (NSUInteger) potentialIndex;
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

    CGFloat distance = fabsf(roundf(fractionalIndex) - fractionalIndex);
    _leftTabContentView.visibility = distance;
    _centerTabContentView.visibility = 1-distance;
    _rightTabContentView.visibility = distance;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {

    // user stoped draging and the view does not decelerate
    // case that view decelerates is handled in scrollViewWillBeginDecelerating
    if (!decelerate) {

        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat ratio = scrollView.contentOffset.x / pageWidth / kWidthFactor;
        NSUInteger newIndex = (NSUInteger) roundf(ratio);

        [self scrollToViewAtIndex:newIndex
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
    NSInteger index = (NSInteger) roundf(fractionalIndex);

    NSInteger potentialIndex;
    if (fractionalIndex - _currentIndex > 0) {
        potentialIndex = index + 1;
    } else {
        potentialIndex = index - 1;
    }

    NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    if (potentialIndex >= 0 && potentialIndex < (NSInteger) numberOfViews) {
        NSUInteger nextIndex = (NSUInteger) potentialIndex;
        // stop deceleration
        [scrollView setContentOffset:scrollView.contentOffset animated:YES];

        // scroll view to next index
        [self scrollToViewAtIndex:nextIndex
               withTimingFunction:_easeOutTimingFunction
                         duration:0.2];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)__unused scrollView {

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
                         completion:^(BOOL __unused finished){
                             [self selectCurrentViewAnimated:YES];
                         }];
    }

    if (_editingStyle == MOTabViewEditingStyleInsert) {
        _editingStyle = MOTabViewEditingStyleNone;
    }

    if (_editingStyle == MOTabViewEditingStyleDelete) {
        [self tabViewDidEditView];
        _editingStyle = MOTabViewEditingStyleNone;
    }
}


#pragma mark - 

- (void)scrollToViewAtIndex:(NSUInteger)newIndex
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
    NSUInteger newIndex = 0;
    if (_addingStyle == MOTabViewAddingAtLastIndex) {
        NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
        newIndex = numberOfViews;
    } else if (_addingStyle == MOTabViewAddingAtNextIndex) {
        newIndex = _currentIndex + 1;
    }

    [_offsets insertObject:[NSNumber numberWithFloat:0] atIndex:newIndex];

    // inform delegate to update model
    [_delegate tabView:self
          willEditView:_editingStyle
               atIndex:newIndex];

    if (_addingStyle == MOTabViewAddingAtLastIndex) {

        if (_currentIndex + 1 == newIndex) {
            _rightTabContentView = [self tabContentViewAtIndex:newIndex];
            _rightTabContentView.hidden = YES;
        } else {
            _hideLastTabContentView = YES;
        }

        CFTimeInterval duration;
        if (abs((NSInteger) (newIndex - _currentIndex)) > 3) {
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
                         completion:^(BOOL __unused finished){

                             // after changing frames the center view becomes
                             // the left view
                             [_leftTabContentView removeFromSuperview];
                             _leftTabContentView = _centerTabContentView;
                             _centerTabContentView = nil;

// TODO: revise this code
                             MOTabView *temp = self;
                             [self addNewCenterViewAnimated:YES
                                                 completion:^(BOOL __unused finished) {
                                                     [temp selectCurrentViewAnimated:YES];
                                                 }];
                         }];

    }
}

- (CGRect)newFrame:(CGRect)frame forIndex:(NSUInteger)index {

    NSInteger factor = (NSInteger) index - (NSInteger) _currentIndex;
    CGRect newFrame = frame;
    newFrame.origin.x = newFrame.origin.x + factor * kWidthFactor * self.bounds.size.width;
    return newFrame;
}

- (MOTabContentView *)tabContentViewAtIndex:(NSUInteger)index {

    NSUInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];
    MOTabContentView *tabContentView = nil;

    if (index < numberOfViews) {
        UIView *contentView = [_dataSource tabView:self viewForIndex:index];
        CGRect newFrame = [self newFrame:_centerTabContentView.frame forIndex:index];

        if (!_navigationBarHidden && [contentView.class isSubclassOfClass:[UITableView class]]) {

            UITableView *tableView = (UITableView *) contentView;

            NSNumber *offsetNumber = [_offsets objectAtIndex:index];
            float offset = offsetNumber.floatValue;

            CGRect navigationFrame = _navigationBar.frame;
            navigationFrame.origin.y -= offset;
            _navigationBar.frame = navigationFrame;

            if (offset > _navigationBar.bounds.size.height) {
                newFrame.origin.y = 0;
                tableView.contentOffset = CGPointMake(0, offset - _navigationBar.bounds.size.height);
            } else {
                newFrame.origin.y = _navigationBar.bounds.size.height - offset;
                tableView.contentOffset = CGPointMake(0, 0);
            }
        }

        tabContentView = [[MOTabContentView alloc] initWithFrame:newFrame];
        tabContentView.contentView = contentView;
        tabContentView.delegate = self;
        tabContentView.visibility = 0;
        [_scrollView insertSubview:tabContentView belowSubview:_centerTabContentView];
    }

    return tabContentView;
}

// TODO: actually use this method
- (void)addNewCenterViewAnimated:(BOOL)__unused animated
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

    [_offsets removeObjectAtIndex:_currentIndex];

    NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];

    // inform delegate that view will be deleted
    [self tabViewWillEditView];

    [UIView animateWithDuration:0.5
                     animations:^{
                         _centerTabContentView.alpha = 0;
                     }
                     completion:^(BOOL __unused finished) {
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
                                              completion:^(BOOL __unused finished){
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

    [self selectCurrentViewAnimated:YES];
}

- (void)selectCurrentViewAnimated:(BOOL)animated {

    if (!_navigationBarHidden) {
        // set the navigation bar to the correct position
        CGRect newNavigationFrame = _navigationBar.frame;
        // because the view is transformed, we can simply check the frame to
        // determine where the origin will be when the view is expanded
        newNavigationFrame.origin.y = _centerTabContentView.frame.origin.y - _navigationBar.bounds.size.height;
        _navigationBar.frame = newNavigationFrame;
    }

    [self tabViewWillSelectView];

    [_scrollView bringSubviewToFront:_centerTabContentView];
    [self bringSubviewToFront:_scrollView];
    [_centerTabContentView selectAnimated:animated];
    _scrollView.scrollEnabled = NO;

    NSString *title = [self.dataSource titleForIndex:_currentIndex];
    _navigationBar.topItem.title = title;

    if (!_navigationBarHidden) {
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 _navigationBar.alpha = 1;
                             }
                             completion:^(BOOL __unused finished) {
#warning this might not be the end of the animation because of deselectAnimated
                                 [self tabViewDidSelectView];
                             }];
        } else {
            [self tabViewDidSelectView];
        }
    }
}

- (void)deselectCurrentView {

    if (!_navigationBarHidden && [_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {

        UITableView *tableView = (UITableView *) _centerTabContentView.contentView;
        
        [_offsets replaceObjectAtIndex:_currentIndex
                            withObject:[NSNumber numberWithFloat:tableView.contentOffset.y]];
    
        float contentOffsetY = tableView.contentOffset.y;

        // careful, removing tableHeaderView changes contentOffset
        tableView.tableHeaderView = nil;

        CGRect navigationFrame = _navigationBar.frame;
        navigationFrame.origin.y = -contentOffsetY;
        _navigationBar.frame = navigationFrame;
        [self addSubview:_navigationBar];

        CGRect contentFrame = _centerTabContentView.frame;
        contentFrame.origin.y = MAX(_navigationBar.bounds.size.height - contentOffsetY, 0);
        _centerTabContentView.frame = contentFrame;

        tableView.contentOffset = CGPointMake(0, MAX(contentOffsetY - _navigationBar.bounds.size.height, 0));
    }

    [self tabViewWillDeselectView];

    [_centerTabContentView deselectAnimated:YES];
    _scrollView.scrollEnabled = YES;

    if (!_navigationBarHidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             _navigationBar.alpha = 0;
#warning this might not be the end of the animation because of deselectAnimated
                             [self tabViewDidDeselectView];
                         }];
    }
}

- (UIView *)viewForIndex:(NSUInteger)index {

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
