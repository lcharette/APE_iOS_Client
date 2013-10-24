//
//  APE_Client.h
//  APE Client
//
//  Created by Louis Charette on 2013-10-17.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APEClient : NSObject <NSStreamDelegate>

@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic) CFStringRef APE_host;
@property (nonatomic) long APE_port;
@property (nonatomic) NSString *APE_name;
@property (nonatomic) BOOL APE_debug;
@property (nonatomic) NSMutableDictionary *APE_channelList;
@property (nonatomic) BOOL APE_connected;

+ (id)APEClient_init;

-(void)sendCmd:(NSString *)command :(NSDictionary *)data;
-(void)sendCmd:(NSString *)command;
-(void)sendCmdToChannel:(NSString *)command :(NSString *)channelName;
-(void)sendCmdToChannel:(NSString *)command :(NSString *)channelName :(NSMutableDictionary *) data;
-(void)connect:(NSString*)host :(long)port;
-(void)connect;
-(void) quit;
-(NSString *)getChannelPubidFromName:(NSString *)channelName;
-(void) joinChannel:(NSString *)channelName;
-(void) leftChannel:(NSString *)channelName;
-(NSString*) encodeToPercentEscapeString:(NSString *)string;
- (NSDictionary *) getChannelUsersFromName:(NSString *)channelName;
- (NSDictionary *) getChannelUsersfromPubid:(NSString *)channelPubid;
@end
