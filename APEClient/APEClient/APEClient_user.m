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
@synthesize properties;

- (id)init
{
    return [self initWithPubid:@""];
}

- (id)initWithPubid:(NSString *)this_pubid {
    if ( self = [super init] ) {
        
        //TODO: Test if pubid exist and is valid
        
        //Set data
        pubid = this_pubid;
        
        //Init other objets
        properties = [[NSMutableDictionary alloc] init];
        
        return self;
        
    } else {
        //Todo: Return exception
        return nil;
    }
}

-(void)setProperty:(NSString *)PropertyName :(id)PropertyValue
{
    [properties setObject:PropertyValue forKey:PropertyName];
}

-(id)getProperty:(NSString *)PropertyName
{
    return [properties objectForKey:PropertyName];
}

-(void)delProperty:(NSString *)PropertyName
{
    [properties removeObjectForKey:PropertyName];
}

@end
