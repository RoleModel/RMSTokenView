//
//  RMSTokenViewTests.m
//  RMSTokenViewTests
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

#import "RMSTokenViewTests.h"
#import "RMSTokenView.h"

@implementation RMSTokenViewTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAddingAndRemovingTokens {
    RMSTokenView *tokenView = (id)[tester waitForTappableViewWithAccessibilityLabel:@"tokenView"];
    [tokenView becomeFirstResponder];
    [tester waitForTimeInterval:1];
    [tester enterTextIntoCurrentFirstResponder:@"Test\n"];
    XCTAssert([tokenView.tokens count] == 1, @"a token should have been added");
    [tester tapViewWithAccessibilityLabel:@"Test"];
    [tester enterTextIntoCurrentFirstResponder:@"\b"];
    XCTAssert([tokenView.tokens count] == 0, @"the token should have been removed");
    [tester waitForTimeInterval:1];
}

@end
