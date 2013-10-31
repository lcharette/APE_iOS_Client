//
//  KBKeyboardHandler.h
//  Source: http://stackoverflow.com/a/12402817/445757
//

#import <Foundation/Foundation.h>

@protocol KBKeyboardHandlerDelegate;

@interface KBKeyboardHandler : NSObject

- (id)init;

// Put 'weak' instead of 'assign' if you use ARC
@property(nonatomic, weak) id<KBKeyboardHandlerDelegate> delegate;
@property(nonatomic) CGRect frame;

@end