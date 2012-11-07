//
//  ExampleViewController.m
//  ExampleApplication
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

#import "ExampleViewController.h"
#import "ExampleContentView.h"


@implementation ExampleViewController {

    // array of strings that are presented in the views of the tab view
    NSMutableArray *_model;

    // array of titles that are presented on top of the views
    NSMutableArray *_titles;
}


#pragma mark - Initializing

- (id)init {

    self = [super init];
    if (self) {
//        self.tabView.addingStyle = MOTabViewAddingAtNextIndex;
        self.tabView.addingStyle = MOTabViewAddingAtLastIndex;

        self.tabView.editableTitles = YES;

//        self.tabView.navigationBarHidden = NO;
    }
    return self;
}


#pragma mark - UIViewController Methods

- (NSMutableArray *)model {

    if (!_model) {
        _model = @[@"1", @"2", @"3", @"4"].mutableCopy;
    }
    return _model;
}

- (NSMutableArray *)titles {

    if (!_titles) {
        _titles = @[@"", @"", @"", @""].mutableCopy;
    }
    return _titles;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - TabViewDataSource

- (UIView *)tabView:(MOTabView *)tabView viewForIndex:(NSUInteger)index {

    // ask the tab view for a reusalbe view
    ExampleContentView *contentView = (ExampleContentView *)[self.tabView reusableView];
    if (!contentView) {
        // if we did not get a view, we have to build a new one
        contentView = [[ExampleContentView alloc] initWithFrame:tabView.bounds];
    }

    contentView.text = _model[index];

    return contentView;
}

- (NSUInteger)numberOfViewsInTabView:(MOTabView *)tabView {

    return self.model.count;
}

- (NSString *)titleForIndex:(NSUInteger)index {

    NSString *title = [self.titles objectAtIndex:index];
    if ([title isEqualToString:@""]) {
        return [NSString stringWithFormat:@"This is the title for tab %d", index+1];
    } else {
        return title;
    }
}

- (NSString *)subtitleForIndex:(NSUInteger)index {
    
    return [NSString stringWithFormat:@"This is the subtitle for tab %d", index+1];
}


#pragma mark - TabViewDelegate

- (void)tabView:(MOTabView *)tabView
   didEditTitle:(NSString *)title
        atIndex:(NSUInteger)index {

    [self.titles replaceObjectAtIndex:index withObject:title];
}

- (void)tabView:(MOTabView *)tabView
   willEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(NSUInteger)index {

    [super tabView:tabView willEditView:editingStyle atIndex:index];

    if (editingStyle == MOTabViewEditingStyleDelete) {

        [self.model removeObjectAtIndex:index];
        [self.titles removeObjectAtIndex:index];
    }

    if (editingStyle == MOTabViewEditingStyleUserInsert) {

//        NSLog(@"%s insert %d", __PRETTY_FUNCTION__, index);

        [self.model insertObject:[NSString stringWithFormat:@"%d", index+1]
                    atIndex:index];
        [self.titles insertObject:@"" atIndex:index];
    }
}


@end
