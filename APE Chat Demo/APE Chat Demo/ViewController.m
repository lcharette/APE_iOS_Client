//
//  ViewController.m
//  APE Client
//
//  Created by Louis Charette on 2013-10-17.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import "ViewController.h"
#import "APEClient/APEClient.h"
#import "APEClient/APEClient_user.h"
#import "KBKeyboardHandler.h"

@interface ViewController ()

@end

@implementation ViewController {
    APEClient *client;
    KBKeyboardHandler *keyboard;
    NSMutableArray *msgArray;
    NSArray *userArray;
}
@synthesize msgInput;
@synthesize userTableView;
@synthesize msgTableView;

#pragma mark - Viewcontroler methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Add delegate to capture the enterkey on the inputField
    msgInput.delegate = self;
    
    //Init Arrays
    msgArray = [[NSMutableArray alloc] init];
    userArray = [[NSArray alloc] init];
    
    //Get the APE Client instance
    client = [APEClient APEClient_init];
    
    //Debug
    //client.APE_debug = TRUE;
    
    //Set random name.
    //TODO: This is not persistent when the client reconnect since the name would then be marked as used by APE
    NSString *username = [[NSString alloc] initWithFormat:@"iOS%u", (arc4random()%1000)];
    [client setUserProperty:@"name" :username];
    
    //Connect to APE
    [client connect:@"ape.local":6969];
    
    //Listen for events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_LOGIN:) name:@"APE_LOGIN" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_DATA:) name:@"APE_DATA" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserList:) name:@"APE_JOIN" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserList:) name:@"APE_LEFT" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserList:) name:@"APE_CHANNEL" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_CHANNEL:) name:@"APE_CHANNEL" object:nil]; //The same event can have multiple listener...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_CONNECT) name:@"APE_CONNECT" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_DISCONNECT) name:@"APE_DISCONNECT" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(APE_CONNECT_ERR) name:@"APE_CONNECT_ERR" object:nil];
    
    //Adding keyboard handler to resize the view when the keybaord appear
    keyboard = [[KBKeyboardHandler alloc] init];
    keyboard.delegate = self;
    
    //We fix bouncing when not needed (ugly)
    userTableView.alwaysBounceVertical = NO;
    msgTableView.alwaysBounceVertical = NO;
    
    //Add delegate
    msgTableView.delegate = self;
    userTableView.delegate = self;
    
    //Littlehack to remove line separator for empty lines
    //Source: http://stackoverflow.com/a/3204316/445757
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [userTableView setTableFooterView:v];
    [msgTableView setTableFooterView:v];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RAW events

-(void) updateUserList:(NSNotification *)notification
{
    userArray = [client getChannelUsersFromName:@"test"];
    [userTableView reloadData];
}

-(void) raw_LOGIN:(NSNotification *)notification
{
    [client joinChannel:@"test"];
}

-(void) raw_DATA:(NSNotification *)notification
{
    //Get the notification
    NSDictionary *data = [notification.userInfo objectForKey:@"data"];
    
    //Get the data from the notification
    NSString *from = [[[data objectForKey:@"from"] objectForKey:@"properties"] objectForKey:@"name"];
    NSString *msg  = [data objectForKey:@"msg"];
    
    //Decode the message
    msg = [msg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //Append the message
    [self appendMsg:msg:from];
}

-(void) raw_CHANNEL:(NSNotification *)notification
{
    //We are connected to the channel. The text input is enabled.
    self.msgInput.text = @"";
    self.msgInput.enabled = TRUE;
}

-(void) raw_CONNECT
{
    self.msgInput.text = @"Connecting to 'test' channel";
}

-(void) raw_DISCONNECT
{
    self.msgInput.text = @"Connexion to the server lost";
    self.msgInput.enabled = FALSE;
}

-(void) APE_CONNECT_ERR
{
    //Show an alert
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"APE Error"
                                                        message:@"Can't connect to APE Server !"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

-(void) appendMsg:(NSString *)msg :(NSString *)from
{
    //Create a dictionnary for the msg
    NSMutableDictionary *tempMsgData = [[NSMutableDictionary alloc] init];
    [tempMsgData setObject:from forKey:@"name"];
    [tempMsgData setObject:msg forKey:@"msg"];
    
    //Add the messages to the list
    [msgArray addObject:tempMsgData];
    
    //Update the table
    [msgTableView reloadData];
    
    //Scroll to the bottom
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: [msgArray count]-1 inSection: 0];
    [msgTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: YES];
}

#pragma mark - Tableviews

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == userTableView) {
        return @"User list";
    } else if (tableView == msgTableView) {
        return @"";
    } else {
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == userTableView) {
       return [userArray count];
    } else if (tableView == msgTableView) {
       return [msgArray count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableViewVar cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableViewVar == userTableView) {
                
        //Get the user object
        APEClient_user *userdata = [userArray objectAtIndex:indexPath.row];
        
        //Get the cell
        static NSString *simpleTableIdentifier = @"userTableCell";
        UITableViewCell *cell = [tableViewVar dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        //Change the cell label
        cell.textLabel.text = [userdata getProperty:@"name"];
        
        //Return the cell
        return cell;
    
    } else if (tableViewVar == msgTableView) {
        
        //Get the entry
        NSDictionary *msgData = [msgArray objectAtIndex:indexPath.row];
        
        //Get the cell
        static NSString *simpleTableIdentifier = @"msgTableCell";
        UITableViewCell *cell = [tableViewVar dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        //Change the cell labels
        cell.textLabel.text = [msgData objectForKey:@"name"];
        cell.detailTextLabel.text = [msgData objectForKey:@"msg"];
        
        //Return the cell
        return cell;
    
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableViewVar heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //We tweek the cellheight for msg that could be longer
    if (tableViewVar == msgTableView) {
        
        //Get the entry
        NSDictionary *msgData = [msgArray objectAtIndex:indexPath.row];
        
        // This gets the size of the rectangle needed to draw a multi-line string
        // 63 is padding & 91 is the username label width.
        CGSize theSize = [[msgData objectForKey:@"msg"] sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(tableViewVar.frame.size.width - 63 - 91, 9999.0f) lineBreakMode:NSLineBreakByWordWrapping];
        
        // 18 is the size of the font used in the text label
        // This will give us the number of lines in the multi-line string
        int numberOfTextRows = round(theSize.height / 18);
        
        //We won't touch 1 line.
        if (numberOfTextRows < 2) {
            return 44;
        } else {
            //Return the calculated height. 16 is for extra padding.
            return theSize.height + 16;
        }
        
    } else {
        return 44;
    }
}

#pragma mark - Interface actions

- (IBAction)msgSendBtn:(id)sender {
    
    //Get the string
    NSString *msg = [msgInput text];
    
    //Test if the message is not blank and if APE is connected
    if (![msg  isEqual: @""] && client.APE_connected) {
        
        //Append the message
        [self appendMsg:msg:[client.APE_user getProperty:@"name"]];
        
        //Encode before sending
        msg = [client encodeToPercentEscapeString:msg];
        
        //Send to channel
        NSMutableDictionary *dataToSend = [[NSMutableDictionary alloc] init];
        [dataToSend setObject:msg forKey:@"msg"];
        [client sendCmdToChannel:@"SEND" :@"test" :dataToSend];
        
        //Clear the text input
        msgInput.text = @"";
    } else if (!client.APE_connected) {
        [client connect];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //Send the message when the enter key is pressedt
    if (textField == msgInput) {
        [self msgSendBtn:self];
    }
    return YES;
}

- (void)keyboardSizeChanged:(CGSize)delta
{
    CGRect frame = self.view.frame;
    frame.size.height -= delta.height;
    self.view.frame = frame;
}

@end
