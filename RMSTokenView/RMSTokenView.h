//
//  RMSTokenView.h
//  RMSTokenView
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RMSTokenDelegate;


@interface RMSTokenView : UIScrollView<UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSString *text;

@property (nonatomic) BOOL searching;

@property (nonatomic, strong, readonly) NSString *summary;
@property (nonatomic, strong, readonly) NSArray *tokens; /* List of NSStrings */

@property (nonatomic, strong) id<RMSTokenDelegate> tokenDelegate;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;

- (void)addTokenWithText:(NSString *)tokenText;
- (void)removeTokenWithText:(NSString *)tokenText;
- (void)selectTokenWithText:(NSString *)tokenText;

- (void)setSearching:(BOOL)searching animated:(BOOL)animated;

@end


@protocol RMSTokenDelegate <UITextFieldDelegate>

@optional

- (void)tokenView:(RMSTokenView *)tokenView didSelectTokenWithText:(NSString *)text;
- (void)tokenView:(RMSTokenView *)tokenView didAddTokenWithText:(NSString *)text;
- (void)tokenView:(RMSTokenView *)tokenView didRemoveTokenWithText:(NSString *)text;

- (BOOL)tokenView:(RMSTokenView *)tokenView shouldAddTokenWithText:(NSString *)text;

- (void)tokenView:(RMSTokenView *)tokenView didChangeText:(NSString *)text;
- (void)tokenView:(RMSTokenView *)tokenView didUpdateSummary:(NSString *)summary;

@end