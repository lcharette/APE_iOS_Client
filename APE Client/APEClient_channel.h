//
//  APEClient_channel.h
//  APE Client
//
//  Created by Louis Charette on 2013-10-26.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import "APEClient_user.h"
#import <Foundation/Foundation.h>

@interface APEClient_channel : NSObject

@property (nonatomic, readonly) NSString *pubid;
@property (nonatomic, readonly) NSMutableArray *users;
@property (nonatomic, readonly) NSMutableDictionary *properties;
@property (nonatomic) NSString *name;

- (id) initWithPubid:(NSString *)pubid;
- (void) addUser:(APEClient_user *)user;
- (void) removeUserWithPubid:(NSString *)userPubid;
- (void) setProperty:(NSString *)PropertyName :(id)PropertyValue;
- (id) getProperty:(NSString *)PropertyName;
- (void) delProperty:(NSString *)PropertyName;
@end
