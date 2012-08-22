//
//  MOTabView.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MOTabContentView.h"


@class MOTabView;


@protocol MOTabViewDataSource<NSObject>


- (UIView *)tabView:(MOTabView *)tabView
       viewForIndex:(NSInteger)index;

- (NSInteger)numberOfViewsInTabView:(MOTabView *)tabView;

@optional
- (NSString *)titleForIndex:(NSInteger)index;

- (NSString *)subtitleForIndex:(NSInteger)index;


@end


@protocol MOTabViewDelegate<NSObject>


typedef enum {
    MOTabViewEditingStyleNone,
    MOTabViewEditingStyleDelete,
    MOTabViewEditingStyleInsert
} MOTabViewEditingStyle;


@optional

- (void)tabView:(MOTabView *)tabView
willSelectViewAtIndex:(NSInteger)index;

- (void)tabViewWillDeselectView:(MOTabView *)tabView;

- (void)tabView:(MOTabView *)tabView
didSelectViewAtIndex:(NSInteger)index;

- (void)tabViewDidDeselectView:(MOTabView *)tabView;

- (void)tabView:(MOTabView* )tabView
   willEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(int)index;

- (void)tabView:(MOTabView *)tabView
    didEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(int)index;


@end


@interface MOTabView : UIView<UIScrollViewDelegate,MOTabContentViewDelegate>

/**
 * While `MOTabViewAddNewTabAtLastIndex` corresponds to the behaviour  of the
 * tab view in safari prior to iOS6, `MOTabViewAddNewTabAtNextIndex`
 * resembles iOS6.
 */
typedef enum {
    MOTabViewAddingAtLastIndex,
    MOTabViewAddingAtNextIndex
} MOTabViewAddinngStyle;


@property(assign, nonatomic) IBOutlet id<MOTabViewDataSource> dataSource;
@property(assign, nonatomic) IBOutlet id<MOTabViewDelegate> delegate;


/// @name Configuring a TabView

/// Style used when a new tab is added to the view.
@property(assign, nonatomic) MOTabViewAddinngStyle addingStyle;


- (void)scrollToViewAtIndex:(int)newIndex
         withTimingFunction:(CAMediaTimingFunction *)timingFunction
                   duration:(CFTimeInterval)duration;

- (void)selectCurrentView;

- (void)deselectCurrentView;

- (void)insertNewView;

- (void)deleteCurrentView;


/**
 * Yields the view for a specific index if the view is currently visible. If it
 * is not visible, the result is `nil`.
 */
- (UIView *)viewForIndex:(NSInteger)index;

/**
 * Yields the currently selected view if one is selected and `nil` otherwise.
 */
- (UIView *)selectedView;


@end