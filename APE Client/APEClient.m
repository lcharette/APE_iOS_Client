//
//  APE_Client.m
//  APE Client
//
//  Created by Louis Charette on 2013-10-17.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import "APEClient.h"
#include <stdlib.h>


/*
 TODO:
 - Get user method (get only one user; By pubid/name)
 - Handle sessions
 - Non-blocking stuff...
*/

@implementation APEClient {
    BOOL APE_socket_input_open;
    BOOL APE_socket_output_open;
    BOOL APE_socket_output_ready;
    BOOL APE_init_connection;
    NSTimer *APE_Check;
    NSTimer *APE_connection_timeout;
    NSString *APE_sessid;
    NSInteger APE_chl;
}
@synthesize inputStream, outputStream, APE_host, APE_port, APE_name, APE_debug, APE_channelList, APE_connected;

+ (id)APEClient_init {
    static APEClient *init = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        init = [[self alloc] init];
    });
    return init;
}

- (id)init {
    if (self = [super init]) {
        
        NSLog(@"APEClient_init");
        
        //Default variables here
        APE_debug = FALSE;
        APE_sessid = @"";
        APE_name = @"";
        APE_socket_input_open = APE_socket_output_open = APE_socket_output_ready = FALSE;
        APE_connected = FALSE;
        APE_init_connection = FALSE;
        
        //Init the channelList dictionnary
        APE_channelList = [[NSMutableDictionary alloc] init];
        
        //We register the default event here
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_LOGIN:) name:@"APE_LOGIN" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_ERR:) name:@"APE_ERR" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_CONNECT:) name:@"APE_CONNECT" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_CHANNEL:) name:@"APE_CHANNEL" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_JOIN:) name:@"APE_JOIN" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(raw_LEFT:) name:@"APE_LEFT" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnect) name:@"APE_DISCONNECT" object:nil];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    NSLog(@"dealloc");
}

# pragma mark - Public commands

-(void)sendCmd:(NSString *)command
{
    [self sendCmd:command :nil];
}
-(void)sendCmd:(NSString *)command :(NSDictionary *)data
{
    //First step, create the main Dictionnary
    NSMutableDictionary *cmd = [[NSMutableDictionary alloc] init];
    [cmd setObject:command forKey:@"cmd"];
    [cmd setObject:[NSNumber numberWithInteger:APE_chl] forKey:@"chl"];
    
    if ([data count] > 0) {
        [cmd setObject:data forKey:@"params"];
    }
    
    //Do we have a sessid?
    if (![APE_sessid isEqual: @""]) {
        [cmd setObject:APE_sessid forKey:@"sessid"];
    }
    
    //We translate the dictionnary to a JSON data
    NSString *jsonString;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:&error];
    
    //Check the data did work
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        
        //Translate the data to a string
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //Debug
        if (APE_debug) {
            NSLog(@"\n------ SENDING ------\n%@\n---------------------", jsonString);
        }
        
        //Create the HTML query
        NSString *query;
        if (APE_connected) {
            query = [[NSString alloc] initWithFormat:@"GET /1/?[%@]\n\n", jsonString];
        } else {
            query = [[NSString alloc] initWithFormat:@"GET /1/?[%@] HTTP/1.1\nHost: 0\n\n", jsonString];
        }
        
        //Output to server
        const uint8_t *rawString=(const uint8_t *)[query cStringUsingEncoding:NSUTF8StringEncoding];
        [outputStream write:rawString maxLength:[query length]];
        
        //Increment the challenge number
        APE_chl++;
    }
}


-(void)sendCmdToChannel:(NSString *)command :(NSString *)channelName
{
    [self sendCmdToChannel:command :channelName :nil];
}
-(void)sendCmdToChannel:(NSString *)command :(NSString *)channelName :(NSMutableDictionary *) data
{
    [data setObject:[self getChannelPubidFromName:channelName] forKey:@"pipe"];
    [self sendCmd:command :data];
}

- (void)connect:(NSString*)host :(long)port {
    
    self.APE_port = port;
    self.APE_host = CFBridgingRetain(host);
    
    NSLog(@"APE CLient: Connecting to %@:%ld", APE_host, APE_port);
    
    //Just in case, we reset the vars
    [self disconnect];
    
    //Create the socket
    CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, APE_host, APE_port, &readStream, &writeStream);
	
    //Setup the input stream for reading data from APE
	self.inputStream = (__bridge_transfer NSInputStream *)readStream;
	[self.inputStream setDelegate:self];
	[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.inputStream open];
	
    //Setup output stream to write to APE
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    //Start a timer for connection timeout
    [APE_connection_timeout invalidate];
    APE_connection_timeout = [NSTimer scheduledTimerWithTimeInterval: 15.0
                                                 target: self
                                               selector: @selector(connect_err)
                                               userInfo: nil
                                                repeats: YES];
}

//This one is only good if port & host is already defined
-(void)connect
{
    if (self.APE_port == 0 || self.APE_host == nil) {
        NSLog(@"APE HOST OR PORT NOT DEFINED");
    } else {
        [self connect:CFBridgingRelease(APE_host) :APE_port];
    }
}

-(void)quit
{
    [self sendCmd:@"QUIT"];
    [self disconnect];
}

- (NSString *) getChannelPubidFromName:(NSString *)channelName
{
    NSString *channelPubid = @"";
    
    //Loop each channel
    for (NSString* pubid in APE_channelList) {
        
        //Is the name the one we want?
        if ([[[APE_channelList objectForKey:pubid] objectForKey:@"name"] isEqual:channelName]) {
            channelPubid = pubid;
        }
    }
    
    return channelPubid;
}

- (NSDictionary *) getChannelUsersFromName:(NSString *)channelName
{
    return [self getChannelUsersfromPubid:[self getChannelPubidFromName:channelName]];
}

- (NSDictionary *) getChannelUsersfromPubid:(NSString *)channelPubid
{
    return [[APE_channelList objectForKey:channelPubid] objectForKey:@"users"];
}

-(void) joinChannel:(NSString *)channelName
{
    NSMutableDictionary *dataToSend = [[NSMutableDictionary alloc] init];
    [dataToSend setObject:channelName forKey:@"channels"];
    [self sendCmd:@"JOIN" :dataToSend];
}

-(void) leftChannel:(NSString *)channelName
{
    NSMutableDictionary *dataToSend = [[NSMutableDictionary alloc] init];
    [dataToSend setObject:channelName forKey:@"channel"];
    [self sendCmd:@"LEFT" :dataToSend];
}

# pragma mark - Request parser

-(void) parseRequest:(NSString *)requestData
{
    //Trim the data once to get rid of extra empty lines
    requestData = [requestData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //Divide the data by lines
    NSArray* dataLines = [requestData componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    //Loop for each lines returnes
    for (NSString *dataLine in dataLines) {
        
        //Trim the data again to get rid of spaces
        NSString *dataLineString = [dataLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //We test if the line is not empty and correspond to a JSON string
        if (![dataLineString  isEqual: @""] && [[dataLineString substringToIndex:1]  isEqual: @"["]) {
            
            //Debug
            if (APE_debug) {
                NSLog(@"\n------ RECEIVED ------\n%@\n---------------------", dataLineString);
            }
            
            //Parse to JSON. The string need to first be translated into an NSData before beeing converted to a Dictionnary
            NSError *error1;
            NSDictionary * dataLineDictionary = [NSJSONSerialization JSONObjectWithData:[dataLineString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error1];
            
            //TODO: Catch error
            
            //Again, we split around the dictionnary since APE can put multiple RAW in the same request.
            for (NSDictionary* RawData in dataLineDictionary) {
                [self parseRAW:RawData];
            }
        }
    }
}

-(void) parseRAW:(NSDictionary *)rawData
{
    //We call the "event" using notificationCenter. If the event doesn't exist, it's just ignored.
    NSString *notificationName = [[NSString alloc] initWithFormat:@"APE_%@", [rawData objectForKey:@"raw"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:[rawData objectForKey:@"data"]];
}

# pragma mark - RAW Events

-(void) raw_CONNECT:(NSNotification *)notification
{
    [APE_connection_timeout invalidate];
    
    //Prepare the dictionary wiuth the data to send
    NSMutableDictionary *dataToSend = [[NSMutableDictionary alloc] init];
    
    //If we don't have a nickname, we create one
    if ([APE_name  isEqual: @""]) {
        APE_name = [[NSString alloc] initWithFormat:@"iOS%u", (arc4random()%1000)];
    }

    //Add to the request
    [dataToSend setObject:APE_name forKey:@"name"];
    
    //Send to the client
    [self sendCmd:@"CONNECT" :dataToSend];
}

-(void) raw_LOGIN:(NSNotification *)notification
{
    //Get the sessid from the raw
    NSDictionary *data = notification.userInfo;
    APE_sessid = [data objectForKey:@"sessid"];
    
    //We are connected now.
    APE_connected = TRUE;
    
    //Log...
    NSLog(@"APE SESSID --> %@", APE_sessid);
    
    //Init the "CHECK" command interval
    APE_Check = [NSTimer scheduledTimerWithTimeInterval: 20.0
                                                 target: self
                                               selector: @selector(check)
                                               userInfo: nil
                                                repeats: YES];
    
}

-(void) raw_CHANNEL:(NSNotification *)notification
{
    //Get the data
    NSDictionary *data = notification.userInfo;
    NSMutableDictionary *channelData = [[NSMutableDictionary alloc] init];
    
    //Is the channel already in the dictionnary?
    
    //Get the channel pubid
    NSDictionary *pipe = [data objectForKey:@"pipe"];
    NSString *pubid = [pipe objectForKey:@"pubid"];
    
    //Get the channel name
    NSString *name = [[pipe objectForKey:@"properties"] objectForKey:@"name"];
    [channelData setObject:name forKey:@"name"];
    
    //Get the channel users
    NSDictionary *users = [data objectForKey:@"users"];
    NSMutableDictionary *channelUsers = [[NSMutableDictionary alloc] init];
    
    //Loop each users in the dictionnary
    for(NSDictionary *user in users) {
        [channelUsers setObject:[user objectForKey:@"properties"] forKey:[user objectForKey:@"pubid"]];
    }
    
    //Add the user thing to the dictionnary
    [channelData setObject:channelUsers forKey:@"users"];
    
    //Add to the dictionnary
    [APE_channelList setObject:channelData forKey:pubid];
}

-(void) raw_LEFT:(NSNotification *)notification
{
    //Get the data
    NSDictionary *data = notification.userInfo;
    NSDictionary *user = [data objectForKey:@"user"];
    NSString *channelPubid = [[data objectForKey:@"pipe"] objectForKey:@"pubid"];
    
    //Get the pipeobj from the master channel list
    NSMutableDictionary *pipeobj = [APE_channelList objectForKey:channelPubid];
    
    //Remove the user from the pipeobj
    [[pipeobj objectForKey:@"users"] removeObjectForKey:[user objectForKey:@"pubid"]];
    
    //Change dans le dictionnaire principal
    [APE_channelList setObject:pipeobj forKey:channelPubid];
}

-(void) raw_JOIN:(NSNotification *)notification
{
    //Get the data
    NSDictionary *data = notification.userInfo;
    NSDictionary *user = [data objectForKey:@"user"];
    NSString *channelPubid = [[data objectForKey:@"pipe"] objectForKey:@"pubid"];
    
    //Get the pipeobj from the master channel list
    NSMutableDictionary *pipeobj = [APE_channelList objectForKey:channelPubid];
    
    //Add the user from the pipeobj
    [[pipeobj objectForKey:@"users"] setObject:[user objectForKey:@"properties"] forKey:[user objectForKey:@"pubid"]];
    
    //Change dans le dictionnaire principal
    [APE_channelList setObject:pipeobj forKey:channelPubid];
}

-(void) raw_ERR:(NSNotification *)notification
{
    NSDictionary *data = notification.userInfo;
    NSString *errormsg = [[NSString alloc] initWithFormat:@"Error %@: %@", [data objectForKey:@"code"], [data objectForKey:@"value"]];
    
    //Show an alert
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"APE Error"
                                                        message:errormsg
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - Misc Command

-(void)check
{
    [self sendCmd:@"CHECK"];
}

# pragma mark - Socket Handle

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
        
	switch (streamEvent) {
			
		case NSStreamEventOpenCompleted:
			
            if (theStream == inputStream) {
                
                APE_socket_input_open = TRUE;
                
            } else if (theStream == outputStream) {
                
                APE_socket_output_open = TRUE;
                
            } else {
                NSLog(@"Unknown stream opened");
            }
            
            //Send the CONNECT command if everything is ready
            if (APE_socket_input_open && APE_socket_output_open && APE_socket_output_ready && !APE_init_connection) {
                APE_init_connection = TRUE;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_CONNECT" object:self userInfo:nil];
			}
            
            break;
		case NSStreamEventHasBytesAvailable:
            
			if (theStream == inputStream) {
                
				uint8_t buffer[1024];
				NSInteger len;
				while ([inputStream hasBytesAvailable]) {
					len = [inputStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
						if (nil != output) {
                            [self parseRequest:output];
						}
					}
				}
            }
            
            break;
			
		case NSStreamEventErrorOccurred:
			
			NSLog(@"Can not connect to the host!");
            //TODO: Event..
            [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_CONNECT_ERR" object:self userInfo:nil];
			
            break;
            
        case NSStreamEventHasSpaceAvailable:
            
            if (theStream == outputStream) {
                
                APE_socket_output_ready = TRUE;
                
                //Send the CONNECT command if everything is ready
                if (APE_socket_input_open && APE_socket_output_open && APE_socket_output_ready && !APE_init_connection) {
                    APE_init_connection = TRUE;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_CONNECT" object:self userInfo:nil];
                }
                
			}
            
            break;
            
		case NSStreamEventEndEncountered:
            
            if (theStream == inputStream) {
                NSLog(@"Stream input closed");
                //We can't received anything anymore
                APE_socket_input_open = FALSE;
                
                //Stop the check timeout
                [APE_Check invalidate];
                
                //Push an event. This event will take care of closing the sockets
                [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_DISCONNECT" object:self userInfo:nil];
                
            } else if (theStream == outputStream) {
                 NSLog(@"Stream output closed");
                //We can't send anything anymore.
                APE_socket_output_open = APE_socket_output_ready = FALSE;
                
                //Push an event. This event will take care of closing the sockets
                [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_DISCONNECT" object:self userInfo:nil];
                
            } else {
                
                NSLog(@"Stream unknown closed");
                
                [theStream close];
                [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                theStream = nil;
            }
            
            break;
            
        default:
            break;
	}
}

-(void) disconnect
{
    //Close both streams
    //First the output
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.outputStream = nil;
    
    //Then the input one
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    
    //Clear some variables and objects
    APE_name = @"";
    APE_socket_input_open = APE_socket_output_open = APE_socket_output_ready = FALSE;
    APE_connected = FALSE;
    APE_init_connection = FALSE;
    APE_channelList = [[NSMutableDictionary alloc] init];
}

-(void) connect_err
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"APE_CONNECT_ERR" object:self userInfo:nil];
    [self disconnect];
}

#pragma mark - String Encoding

// Encode a string to embed in the HTML request.
// The string is double encoded, otherwhise the "%" cracter (from the first encoding)
// isn't encoded and thus create a BAD_JSON from the APE Server
// Ref.: http://cybersam.com/ios-dev/proper-url-percent-encoding-in-ios
-(NSString*) encodeToPercentEscapeString:(NSString *)string
{
    NSString *temp = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                               (CFStringRef) string,
                                                                               NULL,
                                                                               (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                               kCFStringEncodingUTF8));
    
    return [temp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
@end
