//
//  ViewController.h
//  APE Client
//
//  Created by Louis Charette on 2013-10-17.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBKeyboardHandlerDelegate.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, KBKeyboardHandlerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *msgInput;
@property (weak, nonatomic) IBOutlet UITableView *msgTableView;
@property (weak, nonatomic) IBOutlet UITableView *userTableView;

@end
