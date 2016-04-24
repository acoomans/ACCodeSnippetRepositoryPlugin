//
//  NSDictionary+Merge.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 17/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "NSDictionary+Merge.h"

@implementation NSDictionary (Merge)

- (NSDictionary*)dictionaryByMergingDictionary:(NSDictionary*)dictionary {
    NSMutableDictionary *result = [self mutableCopy];
    for (id key in [dictionary allKeys]) {
        if (!result[key]) {
            result[key] = dictionary[key];
        }
    }
    return [result copy];
}

@end
