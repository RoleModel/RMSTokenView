//
//  RMSTokenViewTests.m
//  RMSTokenViewTests
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

// NOTE: These tests must be run on an iOS 7 or later, but the RMSTokenView itself will run on iOS 6.

#import "RMSTokenViewTests.h"
#import "RMSTokenView.h"

@implementation RMSTokenViewTests

- (void)setUp {
    [super setUp];
    self.tokenView = (id)[tester waitForTappableViewWithAccessibilityLabel:@"tokenView"];
    [self.tokenView becomeFirstResponder];
}

- (void)tearDown {
    [super tearDown];
    self.tokenView.placeholder = @"";
    for (NSString *token in self.tokenView.tokens) {
        [self.tokenView removeTokenWithText:token];
    }
    [self.tokenView resignFirstResponder];
}

- (void)testAddingAndRemovingTokens {
    [tester enterTextIntoCurrentFirstResponder:@"Test\n"];
    XCTAssert([self.tokenView.tokens isEqual:@[@"Test"]], @"a token should have been added");
    [tester tapViewWithAccessibilityLabel:@"Test"];
    [tester enterTextIntoCurrentFirstResponder:@"\b"];
    XCTAssert([self.tokenView.tokens count] == 0, @"the token should have been removed");
}

- (void)testAddingManyTokens {
    [tester enterTextIntoCurrentFirstResponder:@"Test\nBilly\nBob"];
    XCTAssert([self.tokenView.tokens count] == 3, @"multiple tokens should have been added");
    [tester enterTextIntoCurrentFirstResponder:@"\b\b\b\b\b\b\b\b\b\b"];
    XCTAssert([self.tokenView.tokens count] == 0, @"all tokens should have been cleared");
}

- (void)testFixingTextForNewToken {
    [tester enterTextIntoCurrentFirstResponder:@"Test\n"];
    XCTAssert([self.tokenView.tokens count] == 1, @"a token should have been added");
    [tester enterTextIntoCurrentFirstResponder:@"Oops\b\b\b\bReal text\n"];
    XCTAssert([self.tokenView.tokens count] == 2, @"another edited token should have been added");
}

- (void)testAddingAPlaceholder {
    self.tokenView.placeholder = @"This is a placeholder";
    [self.tokenView resignFirstResponder];
    [tester tapViewWithAccessibilityLabel:self.tokenView.placeholder];
}

@end
