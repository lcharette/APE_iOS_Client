//
//  APEClient_user.m
//  APE Client
//
//  Created by Louis Charette on 2013-10-26.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import "APEClient_user.h"

@implementation APEClient_user
@synthesize pubid;

- (id)init
{
    return [self initWithPubid:@""];
}

- (id)initWithPubid:(NSString *)this_pubid {
    if ( self = [super init] ) {
        
        //TODO: Test if pubid exist and is valid
        
        pubid = this_pubid;
        return self;
        
    } else {
        //Todo: Return exception
        return nil;
    }
}
@end
