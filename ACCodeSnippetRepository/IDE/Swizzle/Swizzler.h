//
//  Swizzler.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define swelf (IDECodeSnippetRepository*)self // swizzled self

@interface Swizzler : NSObject

+ (void)swizzleWithClass:(Class)cls;
+ (void)swizzleMethodsWithPrefix:(NSString*)prefix class:(Class)cls;

@end
