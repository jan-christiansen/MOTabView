//
//  MOTabViewController.m
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
#import "MOTabViewController.h"
#import "MOTabView.h"


@interface MOTabViewController ()


@end


@implementation MOTabViewController {

    UIBarButtonItem *_addViewButton;
    UIBarButtonItem *_numberOfViewsButton;
}


#pragma mark - Initializing

- (id)init {

    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeMOTabViewController];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initializeMOTabViewController];
    }
    return self;
}

- (void)initializeMOTabViewController {

    // default titles for buttons on toolbar
    _doneButtonTitle = @"Done";
    _addPageButtonTitle = @"New Page";

    [self.view addSubview:self.selectedToolbar];
    [self.view addSubview:self.deselectedToolbar];

    CGRect tabViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-44);
    _tabView = [[MOTabView alloc] initWithFrame:tabViewFrame];
    _tabView.delegate = self;
    _tabView.dataSource = self;
    [self.view addSubview:_tabView];

    self.maxNumberOfViews = 8;
}


#pragma mark - UIViewController Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Getting and Setting Properties

- (void)setMaxNumberOfViews:(NSUInteger)maxNumberOfViews {

    _maxNumberOfViews = maxNumberOfViews;

    NSUInteger numberOfViews = [self numberOfViewsInTabView:self.tabView];
    _addViewButton.enabled = maxNumberOfViews > numberOfViews;
}

- (void)tabViewDeselectCurrentView {

    [self.tabView deselectCurrentView];
}

- (void)tabViewSelectCurrentView {

    [self.tabView selectCurrentView];
}

- (UIToolbar *)selectedToolbar {

    if (!_selectedToolbar) {
        _selectedToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44)];

        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                          target:nil
                                          action:nil];
        _numberOfViewsButton = [[UIBarButtonItem alloc]
                                initWithTitle:@""
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:@selector(tabViewDeselectCurrentView)];
        UIBarButtonItem *smallSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                    target:nil
                                                                                    action:nil];
        smallSpace.width = 10;

        _selectedToolbar.items = @[flexibleSpace, _numberOfViewsButton, smallSpace];
    }
    return _selectedToolbar;
}

- (UIToolbar *)deselectedToolbar {
    
    if (!_deselectedToolbar) {
        _deselectedToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44)];
        _addViewButton = [[UIBarButtonItem alloc]
                          initWithTitle:self.addPageButtonTitle
                          style:UIBarButtonItemStyleBordered
                          target:_tabView
                          action:@selector(insertNewView)];
        UIBarButtonItem *space = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil
                                  action:nil];
        UIBarButtonItem *button = [[UIBarButtonItem alloc]
                                   initWithTitle:self.doneButtonTitle
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:@selector(tabViewSelectCurrentView)];
        _deselectedToolbar.items = @[_addViewButton, space, button];
    }
    return _deselectedToolbar;
}


#pragma mark - MOTabDataSource

// dummy implementations that are overwritten when subclassing
- (UIView *)tabView:(MOTabView *)__unused tabView
       viewForIndex:(NSUInteger)__unused index {

    return nil;
}

- (NSUInteger)numberOfViewsInTabView:(MOTabView *)__unused tabView {

    return 0;
}

- (NSString *)titleForIndex:(NSUInteger)__unused index {

    return @"";
}

- (NSString *)subtitleForIndex:(NSUInteger)__unused index {

    return @"";
}


#pragma mark - MOTabViewDelegate

- (void)tabView:(MOTabView *)tabView
willSelectViewAtIndex:(NSUInteger)__unused index {

    NSUInteger numberOfViews = [self numberOfViewsInTabView:tabView];
    NSString *buttonTitle = [NSString stringWithFormat:@"%d", numberOfViews];
    _numberOfViewsButton.title = buttonTitle;

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.deselectedToolbar.alpha = 0;
                     }
                     completion:^(BOOL __unused finished) {
                         [self.view sendSubviewToBack:self.deselectedToolbar];
                         self.deselectedToolbar.alpha = 1;
                     }];
}

- (void)tabView:(MOTabView *)__unused tabView
didSelectViewAtIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    // update toolbar when a page view is deselected
    _addViewButton.title = self.addPageButtonTitle;

    self.selectedToolbar.userInteractionEnabled = YES;
    
}

- (void)tabView:(MOTabView *)__unused tabView
willDeselectViewAtIndex:(NSUInteger)__unused index {

    self.selectedToolbar.userInteractionEnabled = NO;
    self.deselectedToolbar.userInteractionEnabled = NO;

    // update toolbar when a page view is deselected
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.selectedToolbar.alpha = 0;
                     }
                     completion:^(BOOL __unused finished) {
                         [self.view sendSubviewToBack:self.selectedToolbar];
                         self.selectedToolbar.alpha = 1;
                     }];
}

- (void)tabView:(MOTabView *)__unused tabView
didDeselectViewAtIndex:(NSUInteger)__unused index {

    self.selectedToolbar.userInteractionEnabled = YES;
    self.deselectedToolbar.userInteractionEnabled = YES;
}

// dummy method, overwritten by subclass
- (void)tabView:(MOTabView *)__unused tabView
   willEditView:(MOTabViewEditingStyle)__unused editingStyle
        atIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.selectedToolbar.userInteractionEnabled = NO;
    self.deselectedToolbar.userInteractionEnabled = NO;
}

// dummy method, overwritten by subclass
- (void)tabView:(MOTabView *)__unused tabView
    didEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSUInteger numberOfViews = [self numberOfViewsInTabView:self.tabView];
    _addViewButton.enabled = self.maxNumberOfViews > numberOfViews;

    if (editingStyle == MOTabViewEditingStyleInsert) {
        NSString *buttonTitle = [NSString stringWithFormat:@"%d!", numberOfViews];
        _numberOfViewsButton.title = buttonTitle;
    }

    self.selectedToolbar.userInteractionEnabled = YES;
    self.deselectedToolbar.userInteractionEnabled = YES;
}

// dummy method, overwritten by subclass
- (void)tabView:(MOTabView *)__unused tabView
 didChangeIndex:(NSUInteger)__unused index {

    return;
}


@end
