//
//  Swizzler.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "Swizzler.h"


static NSString * const kSwizzlerOverridePrefix = @"override_";

@implementation Swizzler

+ (void)swizzleWithClass:(Class)original_cls {
    [self swizzleMethodsWithPrefix:kSwizzlerOverridePrefix class:original_cls];
}

+ (void)swizzleMethodsWithPrefix:(NSString*)prefix class:(Class)original_cls {
    
    int unsigned numMethods;
    Method *methods = class_copyMethodList(self.class, &numMethods);
    for (int i = 0; i < numMethods; i++) {
        
        NSString *overrideMethodName = NSStringFromSelector(method_getName(methods[i]));
        if ([overrideMethodName hasPrefix:prefix]) {

            NSString *originalMethodName = [overrideMethodName substringFromIndex:[prefix length]];
            
            Method original_method = class_getInstanceMethod(original_cls, NSSelectorFromString(originalMethodName));
            Method override_method = class_getInstanceMethod(self.class, NSSelectorFromString(overrideMethodName));
            
            if (!original_method || class_addMethod(original_cls, NSSelectorFromString(overrideMethodName), method_getImplementation(original_method), method_getTypeEncoding(original_method))) {
                class_replaceMethod(original_cls, NSSelectorFromString(originalMethodName), method_getImplementation(override_method), method_getTypeEncoding(override_method));
            }
        }
        
    }
}

@end
