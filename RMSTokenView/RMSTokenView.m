//
//  RMSTokenView.m
//  RMSTokenView
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

#import "RMSTokenView.h"
#import "RMSTokenConstraintManager.h"

void *RMSTokenSelectionContext = &RMSTokenSelectionContext;
NSString *RMSBackspaceUnicodeString = @"\u200B";

@interface RMSTokenView()
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) UILabel *summaryLabel;

@property (nonatomic, strong) NSArray *contentConstraints;

@property (nonatomic, strong) NSMutableArray *tokenViews;
@property (nonatomic, strong) NSMutableArray *tokenLines;
@property (nonatomic, strong) UIButton *selectedToken;

@property (nonatomic) CGSize lastKnownSize;

@property (nonatomic, strong) RMSTokenConstraintManager *constraintManager;

@end

@implementation RMSTokenView

#pragma mark - Setup

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
    if (CGRectIsEmpty(self.frame)) {
        self.frame = CGRectMake(0, 0, 320, 44);
    }
    self.contentSize = self.bounds.size;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
    
    _tokenViews = [NSMutableArray array];
    _tokenLines = [NSMutableArray arrayWithObject:[NSMutableArray array]];
    
    _constraintManager = [RMSTokenConstraintManager manager];
    _constraintManager.tokenView = self;
    
    [self setupViews];
}

- (void)setupViews {
    if (!self.heightConstraint) {
        for (NSLayoutConstraint *constraint in self.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                self.heightConstraint = constraint;
                break;
            }
        }
    }
    [self.constraintManager setupheightConstraintFromOutlet:self.heightConstraint];

    self.content = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.content];
    [self.constraintManager setupContentViewConstraints:self.content];

    self.lineView = [[UIView alloc] init];
    self.lineView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.content addSubview:self.lineView];
    [self.constraintManager setupLineViewConstraints:self.lineView];

    self.textField = [[UITextField alloc] init];
    self.textField.text = RMSBackspaceUnicodeString;
    self.textField.delegate = self;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textField addObserver:self forKeyPath:@"selectedTextRange" options:0 context:RMSTokenSelectionContext];
    [self.content addSubview:self.textField];
    [self.constraintManager setupConstraintsOnTextField:self.textField];
    [[self.tokenLines lastObject] addObject:self.textField];

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.backgroundColor = [UIColor clearColor];
    self.summaryLabel.font = [UIFont systemFontOfSize:15];
    [self.content addSubview:self.summaryLabel];
    [self.constraintManager setupConstraintsOnSummaryLabel:self.summaryLabel];

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewSelected:)]];
}

#pragma mark - Actions

- (void)addTokenWithText:(NSString *)tokenText {
    if ([self.tokens containsObject:tokenText]) {
        [self selectTokenWithText:tokenText];
        self.text = nil;
        return;
    }
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:shouldAddTokenWithText:)]) {
        if (![self.tokenDelegate tokenView:self shouldAddTokenWithText:tokenText]) {
            return;
        }
    }

    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:willPresentTokenWithText:)]) {
        NSString *transformedText = [self.tokenDelegate tokenView:self willPresentTokenWithText:tokenText];
        if (transformedText) {
            tokenText = transformedText;
        }
    }

    UIButton *tokenView = [UIButton buttonWithType:UIButtonTypeCustom];
    tokenView.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
    tokenView.adjustsImageWhenHighlighted = NO;

    UIControlState controlStates[3] = {UIControlStateNormal, UIControlStateHighlighted, UIControlStateSelected};

    for (int idx = 0; idx < 3; idx++) {
        UIControlState controlState = controlStates[idx];
        [tokenView setBackgroundImage:[self tokenBackgroundImageForState:controlState withTokenText:tokenText]
                             forState:controlState];
        [tokenView setAttributedTitle:[[NSAttributedString alloc] initWithString:tokenText attributes:[self titleTextAttributesForState:controlState]]
                             forState:controlState];
    }
    [tokenView setTitle:tokenText forState:UIControlStateNormal];

    [tokenView addTarget:self action:@selector(selectedToken:) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:tokenView];
    [self.constraintManager setupConstraintsOnToken:tokenView];

    [self.tokenViews addObject:tokenView];

    if (!self.textField.editing) {
        tokenView.alpha = 0.0;
    }
    
    self.text = nil;
    
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didAddTokenWithText:)]) {
        [self.tokenDelegate tokenView:self didAddTokenWithText:tokenText];
    }

    [self updateSummary];
    [self resetLines];
}

- (void)removeTokenWithText:(NSString *)tokenText {
    UIButton *buttonToRemove = nil;
    for (UIButton *tokenButton in self.tokenViews) {
        if ([[tokenButton titleForState:UIControlStateNormal] isEqualToString:tokenText]) {
            buttonToRemove = tokenButton;
        }
    }

    if (!!buttonToRemove) {
        [buttonToRemove removeFromSuperview];
        [self.tokenViews removeObject:buttonToRemove];

        if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didRemoveTokenWithText:)]) {
            [self.tokenDelegate tokenView:self didRemoveTokenWithText:tokenText];
        }

        [self updateSummary];
        [self resetLines];
    }
}


- (void)viewSelected:(UITapGestureRecognizer *)tapGesture {
    [self becomeFirstResponder];
    [self selectTokenWithText:nil];
}

- (void)selectedToken:(UIButton *)tokenButton {
    [self selectTokenWithText:[tokenButton titleForState:UIControlStateNormal]];
}

- (void)selectTokenWithText:(NSString *)tokenText {
    if (![[self.selectedToken titleForState:UIControlStateNormal] isEqualToString:tokenText]) {

        self.selectedToken = nil;
        for (UIButton *tokenButton in self.tokenViews) {
            if ([[tokenButton titleForState:UIControlStateNormal] isEqualToString:tokenText]) {
                self.selectedToken = tokenButton;
                break;
            }
        }

        [self updateTextField];
        if (self.selectedToken) {
            [self.textField becomeFirstResponder];
        }
    }

    for (UIButton *tokenView in self.tokenViews) {
        BOOL selected = (tokenView == self.selectedToken);
        if (tokenView.selected != selected) {
            tokenView.selected = selected;
        }
    }

    if (tokenText && [self.tokenDelegate respondsToSelector:@selector(tokenView:didSelectTokenWithText:)]) {
        [self.tokenDelegate tokenView:self didSelectTokenWithText:tokenText];
    }
}

- (void)updateTextField {
    self.textField.hidden = (self.selectedToken || ![self.textField isFirstResponder]);
}

- (void)selectLastToken {
    [self selectTokenWithText:[[self.tokenViews lastObject] titleForState:UIControlStateNormal]];
}

#pragma mark - Searching

- (void)setSearching:(BOOL)searching {
    if (_searching != searching) {
        _searching = searching;

        [self updateConstraints];
        [self.superview layoutIfNeeded];

        [self scrollToBottom];

        if (_searching) {
            self.scrollEnabled = NO;
            self.lineView.hidden = NO;
            self.lineView.backgroundColor = [UIColor colorWithWhite:0.557 alpha:1.000];
        } else {
            self.lineView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.000];
        }
    }
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [self setSearching:searching];
        } completion:nil];
    } else {
        [self setSearching:searching];
    }
}

#pragma mark - Summary

- (NSString *)summary {
    return self.summaryLabel.text;
}

- (void)updateSummary {
    if ([self.tokenViews count] > 0) {
        NSMutableString *summary = [[NSMutableString alloc] init];

        for (UIButton *tokenView in self.tokenViews) {
            [summary appendString:[tokenView titleForState:UIControlStateNormal]];
            if (tokenView != [self.tokenViews lastObject]) {
                [summary appendString:@", "];
            }
        }

        self.summaryLabel.text = summary;
        self.summaryLabel.textColor = [UIColor darkTextColor];
    } else {
        self.summaryLabel.text = @"";
        self.summaryLabel.textColor = [UIColor lightGrayColor];
    }
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didUpdateSummary:)]) {
        [self.tokenDelegate tokenView:self didUpdateSummary:self.summary];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.content layoutSubviews];

    NSMutableArray *lastLine = [self.tokenLines lastObject];
    [[lastLine copy] enumerateObjectsUsingBlock:^(UIView *tokenView, NSUInteger index, BOOL *stop) {
        if (index != 0) {
            if (tokenView.intrinsicContentSize.width > tokenView.bounds.size.width || (tokenView == self.textField && tokenView.bounds.size.width < 100)) {
                [self.tokenLines addObject:[[lastLine subarrayWithRange:NSMakeRange(index, [lastLine count] - index)] mutableCopy]];
                [lastLine removeObjectsInArray:[self.tokenLines lastObject]];

                [self updateConstraints];
                [self layoutSubviews];

                *stop = YES;
            }
        }
    }];


    /* Content is overflowing horizontally */
    if (self.frame.size.width != self.contentSize.width) {
        self.contentSize = CGSizeMake(self.frame.size.width, self.contentSize.height);
        [self resetLines];
        [self updateConstraints];
        [self layoutSubviews];
        return;
    }

    [self showScrollBarsIfNecessary];
}

- (void)updateConstraints {
    [super updateConstraints];

    [self.constraintManager updateConstraintsForTokenLines:self.tokenLines
                                               andLineView:self.lineView
                                        withTextFieldFocus:[self.textField isFirstResponder]
                                               isSearching:self.searching];

    if (self.searching) {
        [self scrollToBottom];
    }
}

- (void)scrollToBottom {
    self.contentOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
}

- (void)resetLines {
    self.tokenLines = [NSMutableArray arrayWithObject:[self.tokenViews mutableCopy]];
    [[self.tokenLines lastObject] addObject:self.textField];
    [self updateConstraints];
    [self layoutSubviews];
}

- (void)showScrollBarsIfNecessary {
    if (self.textField.isFirstResponder && self.contentSize.height > self.frame.size.height && !self.searching) {
        self.scrollEnabled = YES;
        self.lineView.hidden = YES;
    } else {
        self.scrollEnabled = NO;
        self.lineView.hidden = NO;
    }
}

#pragma mark - Frame Changes

- (void)frameChanged {
    if ([self.tokenLines[0] count] > 0 && self.bounds.size.width != self.lastKnownSize.width) {
        [self resetLines];
    }

    [self showScrollBarsIfNecessary];

    if (self.selectedToken == nil && (self.bounds.size.width != self.lastKnownSize.width || self.bounds.size.height != self.lastKnownSize.height)) {
        [self scrollToBottom];
    }
    self.lastKnownSize = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self frameChanged];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self frameChanged];
}

#pragma mark - First Responder

- (BOOL)canBecomeFirstResponder {
    return [self.textField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([[textField.text substringWithRange:range] isEqual:RMSBackspaceUnicodeString]) {
        /* Select last token */
        if (self.selectedToken) {
            [self removeTokenWithText:[self.selectedToken titleForState:UIControlStateNormal]];
            [self selectTokenWithText:nil];
        } else if ([self.text length] == 0) {
            [self selectLastToken];
        }
        return NO;
    } else if (self.selectedToken) {
        /* Replace selected token */
        [self removeTokenWithText:[self.selectedToken titleForState:UIControlStateNormal]];
        [self selectTokenWithText:nil];
    }

    /* Adjust cursor position */
    if (range.location < 1) {
        range.location++;

        if (range.length > 0) {
            range.length--;
        }
    }

    [self manuallyChangeTextField:textField inRange:range replacementString:string];
    [self setSearching:([self.text length] > 0) animated:YES];


    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didChangeText:)]) {
        [self.tokenDelegate tokenView:self didChangeText:self.text];
    }
    
    return NO;
}

- (void)manuallyChangeTextField:(UITextField *)textField inRange:(NSRange)range replacementString:(NSString *)string {
    // Set the cursor to be the original offset distance from the last token
    NSInteger offset = [textField offsetFromPosition:textField.selectedTextRange.end toPosition:textField.endOfDocument];

    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];

    UITextPosition *newEnd = [textField positionFromPosition:textField.endOfDocument inDirection:UITextLayoutDirectionLeft offset:offset];
    textField.selectedTextRange = [textField textRangeFromPosition:newEnd toPosition:newEnd];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self addTokenWithText:self.text];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        for (UIView *tokenView in self.tokenViews) {
            tokenView.alpha = 1.0;
        }
        self.textField.alpha = 1.0;
        self.summaryLabel.alpha = 0.0;

        [self setNeedsUpdateConstraints];
        [self.superview layoutIfNeeded];

        [self scrollToBottom];
    } completion:nil];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            self.scrollEnabled = NO;
            self.lineView.hidden = NO;

            for (UIView *tokenView in self.tokenViews) {
                tokenView.alpha = 0.0;
            }
            self.textField.alpha = 0.0;
            self.summaryLabel.alpha = 1.0;

            [self setNeedsUpdateConstraints];
            [self.superview layoutIfNeeded];

            self.contentOffset = CGPointMake(0.0, 0.0);
        } completion:nil];
    });
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedTextRange"] && object == self.textField) {
        // We use a backspace character at the start of the field that we don't want the user to select or move the insertion point in front of
        NSInteger offset = [self.textField offsetFromPosition:self.textField.beginningOfDocument toPosition:self.textField.selectedTextRange.start];

        if (offset < 1) {
            UITextPosition *newStart = [self.textField positionFromPosition:self.textField.beginningOfDocument offset:1];
            self.textField.selectedTextRange = [self.textField textRangeFromPosition:newStart toPosition:self.textField.selectedTextRange.end];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Token Buttons

- (UIImage *)tokenBackgroundImageForState:(UIControlState)state withTokenText:(NSString *)tokenText {
    UIColor *topColor; UIColor *bottomColor; UIColor *strokeColor;

    if (state == UIControlStateNormal) {
        topColor = [UIColor colorWithRed:0.87f green:0.91f blue:0.96f alpha:1.0f];
        bottomColor = [UIColor colorWithRed:0.75f green:0.82f blue:0.92f alpha:1.0f];
        strokeColor = [UIColor colorWithRed:0.64f green:0.73f blue:0.88f alpha:1.00f];
    } else if (state == UIControlStateHighlighted || state == UIControlStateSelected) {
        topColor = [UIColor colorWithRed:0.3f green:0.56f blue:0.98f alpha:1.0f];
        bottomColor = [UIColor colorWithRed:0.21f green:0.37f blue:1.0f alpha:1.0f];
        strokeColor = [UIColor colorWithRed:0.27f green:0.42f blue:0.84f alpha:1.00f];
    }
    return [self buttonImageWithTopColor:topColor bottomColor:bottomColor withStrokeColor:strokeColor];
}

- (NSDictionary *)titleTextAttributesForState:(UIControlState)state {

    if (state == UIControlStateNormal) {
        return @{
                NSFontAttributeName: [UIFont systemFontOfSize:15.0],
                NSForegroundColorAttributeName: [UIColor blackColor],
        };
    } else if (state == UIControlStateHighlighted) {
        return @{
                NSFontAttributeName: [UIFont systemFontOfSize:15.0],
                NSForegroundColorAttributeName: [UIColor whiteColor],
        };
    } else if (state == UIControlStateSelected) {
        return @{
                NSFontAttributeName: [UIFont systemFontOfSize:15.0],
                NSForegroundColorAttributeName: [UIColor whiteColor],
        };
    }

    return nil;
}

- (UIImage *)buttonImageWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor withStrokeColor:(UIColor *)strokeColor {
    CGRect rect = CGRectMake(0, 0, 29, 25);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    /* Draw Fill Gradient */
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:12].CGPath);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    NSArray *colors = @[(__bridge id)topColor.CGColor, (__bridge id)bottomColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    
    CGPoint startPoint = CGPointMake(rect.size.width / 2.0, 0);
    CGPoint endPoint = CGPointMake(rect.size.width / 2.0, rect.size.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    /* Draw Stroke */
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.2, 0.2) cornerRadius:12].CGPath);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetLineWidth(context, 0.5);
    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
}

#pragma mark - Accessors

- (void)setText:(NSString *)text
{
    if (text != nil) {
        [self.textField setText:[RMSBackspaceUnicodeString stringByAppendingString:text]];
    } else {
        [self.textField setText:RMSBackspaceUnicodeString];
    }
    [self setSearching:!!text];

    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didChangeText:)]) {
        [self.tokenDelegate tokenView:self didChangeText:self.text];
    }
}

- (NSString *)text {
    return [[self.textField text] stringByReplacingOccurrencesOfString:RMSBackspaceUnicodeString withString:@""];
}

- (NSArray *)tokens {
    NSMutableArray *tokens = [NSMutableArray array];
    [self.tokenViews enumerateObjectsUsingBlock:^(UIButton *tokenView, NSUInteger idx, BOOL *stop) {
        [tokens addObject:[tokenView titleForState:UIControlStateNormal]];
    }];
    return tokens;
}

@end