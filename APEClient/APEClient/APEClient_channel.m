//
//  APEClient_channel.m
//  APE Client
//
//  Created by Louis Charette on 2013-10-26.
//  Copyright (c) 2013 APE-Project. All rights reserved.
//

#import "APEClient_channel.h"

@implementation APEClient_channel
@synthesize pubid;
@synthesize users;
@synthesize name;
@synthesize properties;

-(id)initWithPubid:(NSString *)this_pubid
{
    if (self = [super init]) {
       
        //Todo: test if pubid is valid
        
        //Set data
        pubid = this_pubid;
        
        //Init other objets
        users = [[NSMutableArray alloc] init];
        properties = [[NSMutableDictionary alloc] init];
        
        return self;
    
    } else {
        //Todo: Exception
        return nil;
    }
}

-(void)addUser:(APEClient_user *)user
{
    [users addObject:user];
    //[users setObject:user forKey:user.pubid];
}

-(void)removeUserWithPubid:(NSString *)userPubid
{
    for (int i = 0; i < [users count]; i++) {
        if ([[[users objectAtIndex:i] pubid] isEqualToString:userPubid]) {
            [users removeObjectAtIndex:i];
            return;
        }
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
