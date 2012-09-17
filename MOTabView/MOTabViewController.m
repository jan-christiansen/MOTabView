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


@implementation MOTabViewController {

    UIToolbar *_toolbar;
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

    CGRect tabViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-44);
    _tabView = [[MOTabView alloc] initWithFrame:tabViewFrame];
    [self.view addSubview:_tabView];
    _toolbar = [[UIToolbar alloc]
                initWithFrame:CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44)];
    [self.view addSubview:_toolbar];
}


#pragma mark - UIViewController Methods

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    _tabView.delegate = self;
    _tabView.dataSource = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    NSUInteger numberOfViews = [self numberOfViewsInTabView:tabView];
    NSString *buttonTitle = [NSString stringWithFormat:@"%d", numberOfViews];
    UIBarButtonItem *button = [[UIBarButtonItem alloc]
                               initWithTitle:buttonTitle
                               style:UIBarButtonItemStylePlain
                               target:tabView
                               action:@selector(deselectCurrentView)];

    _toolbar.userInteractionEnabled = NO;
    [_toolbar setItems:@[space, button] animated:YES];
}

- (void)tabView:(MOTabView *)__unused tabView
didSelectViewAtIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    _toolbar.userInteractionEnabled = YES;
}

- (void)tabView:(MOTabView *)tabView
willDeselectViewAtIndex:(NSUInteger)__unused index {

    // update toolbar when a page view is deselected
    UIBarButtonItem *addViewButton = [[UIBarButtonItem alloc]
                                      initWithTitle:@"New Page"
                                      style:UIBarButtonItemStyleBordered
                                      target:tabView
                                      action:@selector(insertNewView)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    UIBarButtonItem *button = [[UIBarButtonItem alloc]
                               initWithTitle:@"Done"
                               style:UIBarButtonItemStyleDone
                               target:tabView
                               action:@selector(selectCurrentView)];
    NSArray *items = @[addViewButton, space, button];

    _toolbar.userInteractionEnabled = NO;
    [_toolbar setItems:items animated:YES];
}

- (void)tabView:(MOTabView *)__unused tabView
didDeselectViewAtIndex:(NSUInteger)__unused index {

    _toolbar.userInteractionEnabled = YES;
}

// dummy method, overwritten by subclass
- (void)tabView:(MOTabView *)__unused tabView
   willEditView:(MOTabViewEditingStyle)__unused editingStyle
        atIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    _toolbar.userInteractionEnabled = NO;
}

// dummy method, overwritten by subclass
- (void)tabView:(MOTabView *)__unused tabView
    didEditView:(MOTabViewEditingStyle)__unused editingStyle
        atIndex:(NSUInteger)__unused index {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    _toolbar.userInteractionEnabled = YES;
}


@end
