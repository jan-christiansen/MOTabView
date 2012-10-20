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
#import "MOGradientView.h"
#import "MOTitleTextField.h"


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
    BOOL _delegateRespondsToDidEditTitle;
    BOOL _delegateRespondsToDidChange;
    BOOL _delegateRespondsToTitleForIndex;

    id<MOTabViewDataSource> _dataSource;

    // index of the current center view
    NSUInteger _currentIndex;

    UIView *_backgroundView;
    MOScrollView *_scrollView;
    UIPageControl *_pageControl;
    MOTitleTextField *_titleField;
    MOTitleTextField *_navigationBarField;
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

    NSMutableArray *_reusableContentViews;
}


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        [self initializeMOTabView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeMOTabView];
    }
    return self;
}

- (void)initializeMOTabView {

    // timing function used to scroll the MOScrollView
    _easeInEaseOutTimingFunction = [CAMediaTimingFunction
                                    functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    _easeOutTimingFunction = [CAMediaTimingFunction
                              functionWithName:kCAMediaTimingFunctionEaseOut];
    _easeInTimingFunction = [CAMediaTimingFunction
                             functionWithName:kCAMediaTimingFunctionEaseIn];

    // background view
    UIColor *lightGray = [UIColor colorWithRed:kLightGrayRed
                                         green:kLightGrayGreen
                                          blue:kLightGrayBlue
                                         alpha:1.0];
    UIColor *darkGray = [UIColor colorWithRed:kDarkGrayRed
                                        green:kDarkGrayGreen
                                         blue:kDarkGrayBlue
                                        alpha:1.0];
    _backgroundView = [[MOGradientView alloc] initWithFrame:self.bounds
                                                   topColor:lightGray
                                                bottomColor:darkGray];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self addSubview:_backgroundView];

    // title label
    CGRect titleFrame = CGRectMake(10, 19, self.bounds.size.width-20, 40);
    _titleField = [[MOTitleTextField alloc] initWithFrame:titleFrame];
    _titleField.delegate = self;
    _titleField.enabled = NO;
    _titleField.returnKeyType = UIReturnKeyDone;
//    _titleField.lineBreakMode = UILineBreakModeMiddleTruncation;v
    [self insertSubview:_titleField aboveSubview:_backgroundView];

    // subtitle label
    CGRect subtitleFrame = CGRectMake(10, 46, self.bounds.size.width-20, 40);
    _subtitleLabel = [[UILabel alloc] initWithFrame:subtitleFrame];
    UIColor *subtitleColor = [UIColor colorWithRed:0.76f
                                             green:0.8f
                                              blue:0.83f
                                             alpha:1];
    _subtitleLabel.textColor = subtitleColor;
    _subtitleLabel.backgroundColor = [UIColor clearColor];
//    _subtitleLabel.shadowColor = shadowColor;
    _subtitleLabel.shadowOffset = CGSizeMake(0, -1);
    _subtitleLabel.textAlignment = UITextAlignmentCenter;
    _subtitleLabel.font = [UIFont systemFontOfSize:14];
    _subtitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    [self insertSubview:_subtitleLabel aboveSubview:_backgroundView];

    // page control
    CGRect pageControlFrame = CGRectMake(0, 0, 320, 36);
    pageControlFrame.origin.y = 0.85f * super.frame.size.height;
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
    [self addSubview:_scrollView];

    // standard adding style is the one used by safari prior to iOS6
    _addingStyle = MOTabViewAddingAtLastIndex;

    _navigationBarHidden = YES;

    _offsets = @[].mutableCopy;
    
    _reusableContentViews = @[].mutableCopy;
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

- (void)setFrame:(CGRect)frame {

    super.frame = frame;

    // reposition page control
    CGRect newPageControlFrame = _pageControl.frame;
    newPageControlFrame.origin.y = 0.85f * frame.size.height;
    _pageControl.frame = newPageControlFrame;

    // resize content views
    _leftTabContentView.frame = CGRectMake(_leftTabContentView.frame.origin.x,
                                           _leftTabContentView.frame.origin.y,
                                           frame.size.width,
                                           frame.size.height);
    _centerTabContentView.frame = CGRectMake(_centerTabContentView.frame.origin.x,
                                             _centerTabContentView.frame.origin.y,
                                             frame.size.width,
                                             frame.size.height);
    _rightTabContentView.frame = CGRectMake(_rightTabContentView.frame.origin.x,
                                            _rightTabContentView.frame.origin.y,
                                            frame.size.width,
                                            frame.size.height);
}

- (BOOL)navigationBarHidden {

    return _navigationBarHidden;
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden {

    _navigationBarHidden = navigationBarHidden;

    if (!_navigationBarHidden) {

        CGRect navigationBarFrame = CGRectMake(0, 0, self.bounds.size.width, 44);
        _navigationBar = [[UINavigationBar alloc] initWithFrame:navigationBarFrame];
        UINavigationItem* item = [[UINavigationItem alloc] init];
        CGRect titleFrame = CGRectMake(0, 0, 200, 25);
        _navigationBarField = [[MOTitleTextField alloc] initWithFrame:titleFrame];
        _navigationBarField.enabled = NO;
        _navigationBarField.delegate = self;
        _navigationBarField.returnKeyType = UIReturnKeyDone;

        if (_delegateRespondsToTitleForIndex) {
            _navigationBarField.text = [self.dataSource titleForIndex:_currentIndex];
        }
        item.titleView = _navigationBarField;
        [_navigationBar pushNavigationItem:item animated:NO];
        [self addSubview:_navigationBar];

        // necessary if dataSource is not already set
        CGRect newLeftFrame = _leftTabContentView.frame;
        newLeftFrame.origin.y = newLeftFrame.origin.y + _navigationBar.bounds.size.height;
        _leftTabContentView.frame = newLeftFrame;

        CGRect newCenterFrame = _centerTabContentView.frame;
        newCenterFrame.origin.y = newCenterFrame.origin.y + _navigationBar.bounds.size.height;
        _centerTabContentView.frame = newCenterFrame;

        CGRect newRightFrame = _rightTabContentView.frame;
        newRightFrame.origin.y = newRightFrame.origin.y + _navigationBar.bounds.size.height;
        _rightTabContentView.frame = newRightFrame;

        if (_centerTabContentView.isSelected) {
            [self selectCurrentViewAnimated:NO];
        }
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

    NSUInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];

    for (int i = 0; i < (NSInteger)numberOfViews; i++) {
        [_offsets addObject:[NSNumber numberWithFloat:0]];
    }

    _scrollView.contentSize = CGSizeMake((1 + kWidthFactor * (numberOfViews-1)) * self.bounds.size.width,
                                         self.bounds.size.height);

    // initialize the three views
    _centerTabContentView = [self tabContentView];
    _centerTabContentView.delegate = self;
    [_scrollView addSubview:_centerTabContentView];

    // initialize left view
    _leftTabContentView = [self tabContentViewAtIndex:_currentIndex-1
                                        withReuseView:nil];

    // initialize right view
    _rightTabContentView = [self tabContentViewAtIndex:_currentIndex+1
                                         withReuseView:nil];

    if (numberOfViews > 0) {
        UIView *contentView = [_dataSource tabView:self viewForIndex:0];
        _centerTabContentView.contentView = contentView;
        [self selectCurrentViewAnimated:NO];
        [self updateTitles];
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
    _delegateRespondsToDidEditTitle = [_delegate respondsToSelector:@selector(tabView:didEditTitle:atIndex:)];
    _delegateRespondsToDidChange = [_delegate respondsToSelector:@selector(tabView:didChangeIndex:)];
    _delegateRespondsToTitleForIndex = [_delegate respondsToSelector:@selector(titleForIndex:)];

    [self tabViewWillSelectView];
    [self tabViewDidDeselectView];
}

- (BOOL)editableTitles {

    return _titleField.enabled;
}

- (void)setEditableTitles:(BOOL)editableTitles {

    _titleField.enabled = editableTitles;
    _navigationBarField.enabled = editableTitles;
}

- (NSString *)titlePlaceholder {

    return _titleField.placeholder;
}

- (void)setTitlePlaceholder:(NSString *)titlePlaceholder {

    _titleField.placeholder = titlePlaceholder;
    _navigationBarField.placeholder = titlePlaceholder;
}


#pragma mark - Wrapping _offsets Array

- (float)offsetForIndex:(NSUInteger)index {

    NSNumber *offsetNumber = [_offsets objectAtIndex:index];
    return offsetNumber.floatValue;
}

- (void)initOffsetForIndex:(NSUInteger)index {

    [_offsets insertObject:[NSNumber numberWithFloat:0] atIndex:index];
}

- (void)replaceOffsetAtIndex:(NSUInteger)index withOffset:(float)offset {

    [_offsets replaceObjectAtIndex:index
                        withObject:[NSNumber numberWithFloat:offset]];
}


#pragma mark - Informing the Delegate

- (void)tabViewWillSelectView {

    [self bringSubviewToFront:_navigationBar];

    if (_delegateRespondsToWillSelect) {
        [_delegate tabView:self willSelectViewAtIndex:_currentIndex];
    }
}

- (void)tabViewDidSelectView {

    if (!_navigationBarHidden
        && [_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)_centerTabContentView.contentView;

        // navigation bar becomes tableHeaderView of the table view
        CGRect navigationBarFrame = _navigationBar.frame;
        navigationBarFrame.origin.y = 0;
        _navigationBar.frame = navigationBarFrame;

        CGRect centerFrame = _centerTabContentView.frame;
        centerFrame.origin.y = 0;
        _centerTabContentView.frame = centerFrame;

        [_navigationBar removeFromSuperview];
        tableView.tableHeaderView = _navigationBar;

        float offset = [self offsetForIndex:_currentIndex];
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

    [self bringSubviewToFront:_titleField];
    [self bringSubviewToFront:_pageControl];

    if (_delegateRespondsToDidDeselect) {
        [_delegate tabView:self didDeselectViewAtIndex:_currentIndex];
    }
}

- (void)tabViewDidChange {

    if (_delegateRespondsToDidChange) {
        [_delegate tabView:self didChangeIndex:_currentIndex];
    }
}

- (void)tabViewWillEditView {

    NSUInteger numberOfViewsBeforeEdit = [_delegate numberOfViewsInTabView:self];

    if (_delegateRespondsToWillEdit) {
        [_delegate tabView:self willEditView:_editingStyle atIndex:_currentIndex];
    }

    NSUInteger numberOfViewsAfterEdit = [_delegate numberOfViewsInTabView:self];

    if (_editingStyle == MOTabViewEditingStyleInsert) {
        NSString *desc = [NSString stringWithFormat:@"Number of views before insertion %d, after insertion %d, should be %d",
                          numberOfViewsBeforeEdit,
                          numberOfViewsAfterEdit,
                          numberOfViewsBeforeEdit+1];
        NSAssert(numberOfViewsBeforeEdit + 1 == numberOfViewsAfterEdit, desc);
    } else if (_editingStyle == MOTabViewEditingStyleDelete) {
        NSString *desc = [NSString stringWithFormat:@"Number of views before deletion %d, after deletion %d, should be %d",
                          numberOfViewsBeforeEdit,
                          numberOfViewsAfterEdit,
                          numberOfViewsBeforeEdit-1];
        NSAssert(numberOfViewsBeforeEdit - 1 == numberOfViewsAfterEdit, desc);
    }
}

- (void)tabViewDidEditView {

    [self updateTitles];

    // if we have deleted a tab we have to adjust the content size
    if (_editingStyle == MOTabViewEditingStyleDelete) {
        CGSize newContentSize;
        newContentSize.width = _scrollView.contentSize.width - kWidthFactor * _scrollView.bounds.size.width;
        newContentSize.height = _scrollView.contentSize.height;
        _scrollView.contentSize = newContentSize;
    }

    if (_delegateRespondsToDidEdit) {
        [_delegate tabView:self didEditView:_editingStyle atIndex:_currentIndex];
    }
    _editingStyle = MOTabViewEditingStyleNone;
}

- (void)tabViewDidEditTitle:(NSString *)title {

    if (_delegateRespondsToDidEditTitle) {
        [_delegate tabView:self didEditTitle:title atIndex:_currentIndex];
    }
}


#pragma mark - Titles

- (void)updateTitles {

    if (_delegateRespondsToTitleForIndex) {
        NSString *title = [self.dataSource titleForIndex:_currentIndex];
        _titleField.text = title;
        _subtitleLabel.text = [_dataSource subtitleForIndex:_currentIndex];
        if (!_navigationBarHidden) {
            _navigationBarField.text = title;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)__unused textField {

    [self tabViewDidEditTitle:textField.text];

    [self updateTitles];
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

- (void)tabContentViewDidSelect:(MOTabContentView *)__unused tabContentView {

    [self tabViewDidSelectView];
}

- (void)tabContentViewDidDeselect:(MOTabContentView *)__unused tabContentView {

    [self tabViewDidDeselectView];
}


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
        if (newIndex > _currentIndex || newIndex < _currentIndex) {

            if (newIndex > _currentIndex) {

                // save left view for reuse
                MOTabContentView *reuseTabContentView = _leftTabContentView;
                if (reuseTabContentView.contentView) {
                    [_reusableContentViews addObject:reuseTabContentView.contentView];
                    reuseTabContentView.contentView = nil;
                }

                _leftTabContentView = _centerTabContentView;
                _centerTabContentView = _rightTabContentView;

                // add additional view to the right
                _rightTabContentView = [self tabContentViewAtIndex:(NSInteger)newIndex+1
                                                     withReuseView:reuseTabContentView];

                // if right view was just added by insert, hide it
                if (_hideLastTabContentView && newIndex+1 == numberOfViews-1) {
                    _rightTabContentView.hidden = YES;
                    _hideLastTabContentView = NO;
                }

            } else if (newIndex < _currentIndex) {

                // save right view for reuse
                MOTabContentView *reuseTabContentView = _rightTabContentView;
                if (reuseTabContentView.contentView) {
                    [_reusableContentViews addObject:reuseTabContentView.contentView];
                    reuseTabContentView.contentView = nil;
                }

                _rightTabContentView = _centerTabContentView;
                _centerTabContentView = _leftTabContentView;

                //
                _leftTabContentView = [self tabContentViewAtIndex:(NSInteger)newIndex-1
                                                    withReuseView:reuseTabContentView];
            }

            _currentIndex = newIndex;
            [self tabViewDidChange];

            [self updateTitles];

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
                         duration:0.3];
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

    // after the deletion animation finished we inform the delegate
    if (_editingStyle == MOTabViewEditingStyleDelete) {
        [self updatePageControl];
        [self tabViewDidEditView];
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
}

- (void)insertNewView {

    _editingStyle = MOTabViewEditingStyleInsert;

    CGSize newContentSize;
    newContentSize.width = _scrollView.contentSize.width + kWidthFactor * _scrollView.bounds.size.width;
    newContentSize.height = _scrollView.contentSize.height;
    _scrollView.contentSize = newContentSize;

    // index where new tab is added
    NSUInteger newIndex = 0;
    NSUInteger numberOfViews = [self.dataSource numberOfViewsInTabView:self];
    if (_addingStyle == MOTabViewAddingAtLastIndex) {
        newIndex = numberOfViews;
    } else if (_addingStyle == MOTabViewAddingAtNextIndex) {
        newIndex = _currentIndex + 1;
    }

    // add the offset for the new view to the array of offsets
    [self initOffsetForIndex:newIndex];

    // inform delegate to update model
    [_delegate tabView:self
          willEditView:_editingStyle
               atIndex:newIndex];

    if (_addingStyle == MOTabViewAddingAtNextIndex) {

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

        if (numberOfViews == 0) {
            _currentIndex = 0;
        } else {
            _currentIndex = _currentIndex + 1;
        }
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
                         completion:^(BOOL __unused finished) {

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

    } else if (_addingStyle == MOTabViewAddingAtLastIndex) {

        if (_currentIndex + 1 == newIndex) {
            _rightTabContentView = [self tabContentViewAtIndex:newIndex
                                                 withReuseView:nil];
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
    }
}

- (void)insertViewAtIndex:(NSUInteger)newIndex {
    
    _editingStyle = MOTabViewEditingStyleInsert;
    
    CGSize newContentSize;
    newContentSize.width = _scrollView.contentSize.width + kWidthFactor * _scrollView.bounds.size.width;
    newContentSize.height = _scrollView.contentSize.height;
    _scrollView.contentSize = newContentSize;
    
    // add the offset for the new view to the array of offsets
    [self initOffsetForIndex:newIndex];

    if (_currentIndex + 1 == newIndex) {
        _rightTabContentView = [self tabContentViewAtIndex:newIndex
                                             withReuseView:nil];

    }

    // in case the scrollView is visible during a dropbox synchronization
    [self updatePageControl];

}

- (CGRect)newFrame:(CGRect)frame forIndex:(NSUInteger)index {

    CGRect newFrame = frame;
    newFrame.origin.x = newFrame.origin.x + index * kWidthFactor * self.bounds.size.width;
    return newFrame;
}

- (MOTabContentView *)tabContentViewAtIndex:(NSInteger)index
                              withReuseView:(MOTabContentView *)reuseView {

    // if the index is out of bounds, the view is hidden
    NSUInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];
    MOTabContentView *tabContentView = nil;

    if (reuseView) {
        tabContentView = reuseView;
    } else {
        tabContentView = [[MOTabContentView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        tabContentView.delegate = self;
        tabContentView.visibility = 0;
        [_scrollView insertSubview:tabContentView belowSubview:_centerTabContentView];
    }

    if (0 <= index && index < (NSInteger)numberOfViews) {
        // the index is within the bounds
        UIView *contentView = [_dataSource tabView:self viewForIndex:(NSUInteger)index];
        CGRect newFrame = [self newFrame:self.bounds forIndex:(NSUInteger)index];
        tabContentView.frame = newFrame;
        tabContentView.contentView = contentView;
        tabContentView.hidden = NO;

        if (!_navigationBarHidden && [contentView.class isSubclassOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)contentView;
            
            float offset = [self offsetForIndex:(NSUInteger)index];

            CGRect navigationFrame = _navigationBar.frame;
            navigationFrame.origin.y -= offset;
            _navigationBar.frame = navigationFrame;
            
            newFrame.origin.y = MAX(_navigationBar.bounds.size.height - offset, 0);
            tableView.contentOffset = CGPointMake(0, MAX(offset - _navigationBar.bounds.size.height,0));
        }
    } else {
        // the view is out of bounds and, therefore, not dislayed
        tabContentView.hidden = YES;
    }

    return tabContentView;
}

// TODO: actually use this method
- (void)addNewCenterViewAnimated:(BOOL)__unused animated
                      completion:(void (^)(BOOL finished))completion {

    UIView *contentView = [_dataSource tabView:self
                                  viewForIndex:_currentIndex];
    if (_leftTabContentView) {
        CGRect centerFrame = _leftTabContentView.frame;
        centerFrame.origin.x += kWidthFactor * self.bounds.size.width;
        _centerTabContentView = [[MOTabContentView alloc] initWithFrame:centerFrame];
        _centerTabContentView.delegate = self;
        _centerTabContentView.contentView = contentView;
        _centerTabContentView.visibility = 1;
        _centerTabContentView.alpha = 0;
    } else {
        _centerTabContentView = [self tabContentView];
        _centerTabContentView.delegate = self;
        _centerTabContentView.contentView = contentView;
//        [self selectCurrentViewAnimated:NO];
//        [self updateTitles];
    }
    [_scrollView addSubview:_centerTabContentView];

//    [UIView animateWithDuration:0.5
//                     animations:^{
//                         _centerTabContentView.alpha = 1;
//                     }
//                     completion:completion];
}


- (void)deleteCurrentView {

    // if we are about to delete the last remaining tab, we first add a new one
    NSUInteger numberOfViews = [_delegate numberOfViewsInTabView:self];
    if (numberOfViews == 1) {
        [_offsets addObject:[NSNumber numberWithFloat:0]];
        _editingStyle = MOTabViewEditingStyleInsert;
        [self tabViewWillEditView];
        _rightTabContentView = [self tabContentViewAtIndex:1 withReuseView:nil];
        [_scrollView addSubview:_rightTabContentView];
        [self tabViewDidEditView];

        numberOfViews = [_delegate numberOfViewsInTabView:self];;
    }

    _editingStyle = MOTabViewEditingStyleDelete;

    [_offsets removeObjectAtIndex:_currentIndex];

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
                             _rightTabContentView = [self tabContentViewAtIndex:_currentIndex+1
                                                                  withReuseView:nil];

                             [UIView animateWithDuration:0.5
                                              animations:^{
                                                  CGPoint newCenterCenter = _centerTabContentView.center;
                                                  newCenterCenter.x -= kWidthFactor * self.bounds.size.width;
                                                  _centerTabContentView.center = newCenterCenter;
                                                  _centerTabContentView.visibility = 1;
                                                  CGPoint newRightCenter = _rightTabContentView.center;
                                                  newRightCenter.x -= kWidthFactor * self.bounds.size.width;
                                                  _rightTabContentView.center = newRightCenter;
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

    if (!_navigationBarHidden
        && [_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {
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
    _scrollView.scrollEnabled = NO;

    [self updateTitles];

    if (animated && !_navigationBarHidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             _navigationBar.alpha = 1;
                         }];
    }

#warning informs the delegate at the end of the animation, not guarenteed that navigationbar animation is finised
    [_centerTabContentView selectAnimated:animated];
}

- (void)deselectCurrentView {

    [self deselectCurrentViewAnimated:YES];
}

- (void)deselectCurrentViewAnimated:(BOOL)animated {

    if (!_navigationBarHidden
        && [_centerTabContentView.contentView.class isSubclassOfClass:[UITableView class]]) {

        UITableView *tableView = (UITableView *)_centerTabContentView.contentView;

        [self replaceOffsetAtIndex:_currentIndex
                        withOffset:tableView.contentOffset.y];

        // careful, removing tableHeaderView changes contentOffset
        // therefore, we save it into a variable
        float contentOffsetY = tableView.contentOffset.y;
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

    [self updateTitles];
    _scrollView.scrollEnabled = YES;

    if (animated && !_navigationBarHidden) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             _navigationBar.alpha = 0;
                         }];
    }

#warning informs the delegate at the end of the animation, not guarenteed that navigationbar animation is finised
    [_centerTabContentView deselectAnimated:animated];
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

- (NSUInteger)indexOfContentView:(UIView *)view {

    if (view == _leftTabContentView.contentView) {
        return _currentIndex-1;
    } else if (view == _centerTabContentView.contentView) {
        return _currentIndex;
    } else if (view == _rightTabContentView.contentView) {
        return _currentIndex+1;
    } else {
        return 0;
    }
}

- (UIView *)selectedView {
    
    if (_centerTabContentView.isSelected) {
        return _centerTabContentView.contentView;
    } else {
        return nil;
    }
}

- (void)selectViewAtIndex:(NSUInteger)index {

    [_leftTabContentView removeFromSuperview];
    _leftTabContentView = nil;
    [_centerTabContentView removeFromSuperview];
    _centerTabContentView = nil;
    [_rightTabContentView removeFromSuperview];
    _rightTabContentView = nil;

    NSUInteger numberOfViews = [_dataSource numberOfViewsInTabView:self];

    NSString *desc = [NSString stringWithFormat:@"Index %d is not a valid index", index];
    NSAssert(index < numberOfViews, desc);

    _currentIndex = index;
    [self updatePageControl];

    // initialize center view
    UIView *contentView = [_dataSource tabView:self viewForIndex:index];
    CGRect contentViewFrame = self.frame;
// TODO: refactor this code
    CGRect temp = CGRectMake(contentViewFrame.origin.x + index * kWidthFactor * self.bounds.size.width, contentViewFrame.origin.y, contentViewFrame.size.width, contentViewFrame.size.height);
    _centerTabContentView = [[MOTabContentView alloc] initWithFrame:temp];

    _centerTabContentView.delegate = self;
    _centerTabContentView.contentView = contentView;
    [_scrollView addSubview:_centerTabContentView];
    [self selectCurrentViewAnimated:NO];
    [self updateTitles];

    // initialize left view
    _leftTabContentView = [self tabContentViewAtIndex:index-1 withReuseView:nil];

    // initialize right view
    _rightTabContentView = [self tabContentViewAtIndex:index+1 withReuseView:nil];

    CGPoint contentOffset = CGPointMake(index * kWidthFactor * self.bounds.size.width, 0);
    _scrollView.contentOffset = contentOffset;
}

- (UIView *)reusableView {

    UIView *reusableView = nil;
    if (_reusableContentViews.count > 0) {
        reusableView = [_reusableContentViews objectAtIndex:0];
        [_reusableContentViews removeObjectAtIndex:0];
    }
    return reusableView;
}


@end
