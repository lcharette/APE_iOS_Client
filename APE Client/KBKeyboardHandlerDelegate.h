//
//  KBKeyboardHandlerDelegate.h
//  Source: http://stackoverflow.com/a/12402817/445757
//

#import <Foundation/Foundation.h>

@protocol KBKeyboardHandlerDelegate

- (void)keyboardSizeChanged:(CGSize)delta;

@end