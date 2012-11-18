//
//  MOTitleTextField.m
//  MOTabView
//
//  Created by Jan Christiansen on 9/22/12.
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

#import "MOTitleTextField.h"


@implementation MOTitleTextField {

    NSString *_placeholder;

    BOOL _showsPlaceholder;

    UIColor *_textColor;
    UIColor *_placeholderColor;
}


#pragma mark - Initializing

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        _textColor = [UIColor whiteColor];
        _placeholderColor = [UIColor colorWithWhite:0.8f alpha:1];
        _showsPlaceholder = NO;

        self.enabled = YES;
        self.font = [UIFont boldSystemFontOfSize:20];
        self.textColor = _textColor;
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = UITextAlignmentCenter;
        [self addTarget:self
                 action:@selector(textFieldDidBeginEditing:)
       forControlEvents:UIControlEventEditingDidBegin];

        UIColor *shadowColor = [UIColor colorWithRed:0.4f
                                               green:0.47f
                                                blue:0.51f
                                               alpha:1];
        self.layer.shadowColor = shadowColor.CGColor;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 0.0;
        self.layer.shadowOffset = CGSizeMake(0, -1);
    }
    return self;
}


#pragma mark - Getting and Setting Properties

- (NSString *)placeholder {

    return _placeholder;
}

- (void)setPlaceholder:(NSString *)placeholder {

    _placeholder = placeholder;

    [self setText:super.text];
}

- (NSString *)text {

    return _showsPlaceholder ? @"" : super.text;
}

- (void)setText:(NSString *)text {

    if ([text isEqualToString:@""]) {
        if (_placeholder) {
            if (!_showsPlaceholder) {
                super.textColor = _placeholderColor;
                super.clearsOnBeginEditing = YES;
            }
            super.text = _placeholder;
            _showsPlaceholder = YES;
        } else {
            super.text = @"";
            _showsPlaceholder = NO;
        }
    } else {
        if (_showsPlaceholder) {
            super.textColor = _textColor;
            super.clearsOnBeginEditing = NO;
            _showsPlaceholder = NO;
        }
        super.text = text;
    }
}


#pragma mark - Actions

- (void)textFieldDidBeginEditing:(UITextField *)__unused textField {

    if (_showsPlaceholder) {
        super.textColor = _textColor;
        super.clearsOnBeginEditing = NO;
        _showsPlaceholder = NO;
    }
}


@end
