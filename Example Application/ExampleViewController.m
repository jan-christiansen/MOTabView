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


@implementation ExampleViewController {

    // array of strings that are presented in multiple views of the page scroll
    // view
    NSMutableArray *_model;
}


#pragma mark - Initializing

- (id)init {

    self = [super init];
    if (self) {
        _model = [NSMutableArray arrayWithObjects:@"1", @"2", @"3", @"4", nil];
        
        self.tabView.addingStyle = MOTabViewAddingAtNextIndex;
    }
    return self;
}


#pragma mark - UIViewController Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - TabViewDataSource

- (UIView *)tabView:(MOTabView *)tabView viewForIndex:(NSInteger)index {

    UIView *contentView = [[UIView alloc] initWithFrame:tabView.bounds];
    contentView.backgroundColor = [UIColor whiteColor];
    CGRect labelFrame = CGRectMake(0.5*tabView.bounds.size.width-50,
                                   0.5*tabView.bounds.size.height-50,
                                   100,
                                   100);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.backgroundColor = [UIColor clearColor];
    label.text = [_model objectAtIndex:index];
    label.font = [UIFont systemFontOfSize:50];
    label.textAlignment = UITextAlignmentCenter;
    [contentView addSubview:label];
    return contentView;
}

- (NSInteger)numberOfViewsInTabView:(MOTabView *)tabView {

    return _model.count;
}


#pragma mark - TabViewDelegate

- (void)tabView:(MOTabView *)tabView
   willEditView:(MOTabViewEditingStyle)editingStyle
        atIndex:(int)index {

    [super tabView:tabView willEditView:editingStyle atIndex:index];

    if (editingStyle == MOTabViewEditingStyleDelete) {

        [_model removeObjectAtIndex:index];
    }

    if (editingStyle == MOTabViewEditingStyleInsert) {
        
//        NSLog(@"%s insert %d", __PRETTY_FUNCTION__, index);

        [_model insertObject:[NSString stringWithFormat:@"%d", index+1]
                    atIndex:index];
    }
}


@end
