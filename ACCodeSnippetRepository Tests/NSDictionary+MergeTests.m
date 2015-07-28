//
//  NSDictionary+MergeTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 17/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+Merge.h"

@interface NSDictionary_MergeTests : XCTestCase
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
    
    XCTAssertTrue([r[@"a"] isEqualToString:@"a"]);
    XCTAssertTrue([r[@"b"] isEqualToString:@"b"]);
    XCTAssertTrue([r[@"c"] isEqualToString:@"c"]);
}

@end
