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
       viewForIndex:(NSUInteger)index;

- (NSUInteger)numberOfViewsInTabView:(MOTabView *)tabView;

@optional
- (NSString *)titleForIndex:(NSUInteger)index;

- (NSString *)subtitleForIndex:(NSUInteger)index;


@end


@protocol MOTabViewDelegate<NSObject>


typedef NS_ENUM(NSUInteger, MOTabViewEditingStyle) {
    MOTabViewEditingStyleNone,
    MOTabViewEditingStyleDelete,
    MOTabViewEditingStyleInsert
};


@optional

- (void)tabView:(MOTabView *)tabView
willSelectViewAtIndex:(NSUInteger)index;

- (void)tabView:(MOTabView *)tabView willDeselectViewAtIndex:(NSUInteger)index;

- (void)tabView:(MOTabView *)tabView didSelectViewAtIndex:(NSUInteger)index;

- (void)tabView:(MOTabView *)tabView didDeselectViewAtIndex:(NSUInteger)index;

- (void)tabView:(MOTabView* )tabView
   willEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(NSUInteger)index;

- (void)tabView:(MOTabView *)tabView
    didEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(NSUInteger)index;

- (void)tabView:(MOTabView *)tabView
   didEditTitle:(NSString *)title
        atIndex:(NSUInteger)index;


@end


@interface MOTabView : UIView<UIScrollViewDelegate,MOTabContentViewDelegate,UITextFieldDelegate>

/**
 * While `MOTabViewAddNewTabAtLastIndex` corresponds to the behaviour  of the
 * tab view in safari prior to iOS6, `MOTabViewAddNewTabAtNextIndex`
 * resembles iOS6.
 */
typedef NS_ENUM(NSUInteger, MOTabViewAddinngStyle) {
    MOTabViewAddingAtLastIndex,
    MOTabViewAddingAtNextIndex
};


@property(assign, nonatomic) IBOutlet id<MOTabViewDataSource> dataSource;
@property(assign, nonatomic) IBOutlet id<MOTabViewDelegate> delegate;

@property(assign, nonatomic) BOOL navigationBarHidden;
@property(strong, nonatomic) UINavigationBar *navigationBar;

@property(assign, nonatomic) BOOL editableTitles;

@property(strong, nonatomic) NSString *titlePlaceholder;


/// @name Configuring a TabView

/// Style used when a new tab is added to the view.
@property(assign, nonatomic) MOTabViewAddinngStyle addingStyle;


- (void)scrollToViewAtIndex:(NSUInteger)newIndex
         withTimingFunction:(CAMediaTimingFunction *)timingFunction
                   duration:(CFTimeInterval)duration;

- (void)selectCurrentView;

- (void)deselectCurrentView;

- (void)insertNewView;

- (void)insertViewAtIndex:(NSUInteger)newIndex;

- (void)deleteCurrentView;

/**
 * Yields the view for a specific index if the view is currently visible. If it
 * is not visible, the result is `nil`.
 */
- (UIView *)viewForIndex:(NSUInteger)index;

/**
 * Yields the currently selected view if one is selected and `nil` otherwise.
 */
- (UIView *)selectedView;


@end