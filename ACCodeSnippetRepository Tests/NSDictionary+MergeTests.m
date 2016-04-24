//
//  NSDictionary+MergeTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 17/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSDictionary+Merge.h"

@interface NSDictionary_MergeTests : SenTestCase
@end

@implementation NSDictionary_MergeTests

- (void)testExample {
    NSDictionary *d = @{
                        @"a": @"a",
                        @"b": @"b",
                        };
    
    NSDictionary *r = [d dictionaryByMergingDictionary:@{
                                                         @"b": @"B",
                                                         @"c": @"c"
                                                         }];
    
    STAssertTrue([r[@"a"] isEqualToString:@"a"], nil);
    STAssertTrue([r[@"b"] isEqualToString:@"b"], nil);
    STAssertTrue([r[@"c"] isEqualToString:@"c"], nil);
}

@end
