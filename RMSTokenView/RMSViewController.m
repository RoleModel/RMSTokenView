//
//  RMSViewController.m
//  RMSTokenView
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

#import "RMSViewController.h"

@interface RMSViewController ()

@end

@implementation RMSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
