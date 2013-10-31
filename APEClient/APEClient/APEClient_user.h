//
//  APEClient_user.h
//  APE Client
//
//  Created by Louis Charette on 2013-10-26.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APEClient_user : NSObject

@property (nonatomic, readonly) NSString *pubid;
@property (nonatomic, readonly) NSMutableDictionary *properties;

- (id) initWithPubid:(NSString *)this_pubid;
- (void) setProperty:(NSString *)PropertyName :(id)PropertyValue;
- (id) getProperty:(NSString *)PropertyName;
- (void) delProperty:(NSString *)PropertyName;

@end
