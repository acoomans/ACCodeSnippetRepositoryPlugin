//
//  ACCodeSnippetSerializationTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ACCodeSnippetSerialization.h"

@interface ACCodeSnippetSerializationTests : XCTestCase
@end

@implementation ACCodeSnippetSerializationTests

- (void)testSerialize {
    
    NSDictionary *dict = @{
                           ACCodeSnippetTitleKey: @"title",
                           ACCodeSnippetSummaryKey: @"summary",
                           ACCodeSnippetContentsKey: @"line1\nline2\nline3",
                           @"WhateverKey": @"WhateverValue",
                           @"Array": @[@"one", @"two"],
                           };
    
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:dict
                                                           format:ACCodeSnippetSerializationFormatC
                                                          options:0
                                                            error:nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"\n%@", string);
    
    XCTAssertTrue([string rangeOfString:@"title"].location != NSNotFound);
    XCTAssertTrue([string rangeOfString:@"summary"].location != NSNotFound);
    XCTAssertTrue([string rangeOfString:@"line1\nline2\nline3"].location != NSNotFound);
    XCTAssertTrue([string rangeOfString:@"WhateverKey"].location != NSNotFound);
    XCTAssertTrue([string rangeOfString:@"WhateverValue"].location != NSNotFound);
    
    XCTAssertTrue([string rangeOfString:@"one"].location != NSNotFound);
    XCTAssertTrue([string rangeOfString:@"two"].location != NSNotFound);
}

- (void)testDeserialize {
    NSString *string = @"// title\n// summary\n//\n// WhateverKey: WhateverValue\n// Array: [one,two]\nline1\nline2\nline3\n";
    
    NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                 format:ACCodeSnippetSerializationFormatC
                                                                  error:nil];
    NSLog(@"\n%@", dict);
    
    XCTAssertTrue([dict[ACCodeSnippetTitleKey] isEqualToString:@"title"]);
    XCTAssertTrue([dict[ACCodeSnippetSummaryKey] isEqualToString:@"summary"]);
    XCTAssertTrue([dict[ACCodeSnippetContentsKey] isEqualToString:@"line1\nline2\nline3\n"]);
    XCTAssertTrue([dict[@"WhateverKey"] isEqualToString:@"WhateverValue"]);
    
    NSArray *a = @[@"one", @"two"];
    XCTAssertTrue([dict[@"Array"] isEqualToArray:a]);
}

- (void)testDeserialize2 {
    NSString *string = @"// Title: title\n// Summary: summary\n//\n// WhateverKey: WhateverValue\n// Array: [one,two]\nline1\nline2\nline3\n";
    
    NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                 format:ACCodeSnippetSerializationFormatC
                                                                  error:nil];
    NSLog(@"\n%@", dict);
    
    XCTAssertTrue([dict[ACCodeSnippetTitleKey] isEqualToString:@"title"]);
    XCTAssertTrue([dict[ACCodeSnippetSummaryKey] isEqualToString:@"summary"]);
    XCTAssertTrue([dict[ACCodeSnippetContentsKey] isEqualToString:@"line1\nline2\nline3\n"]);
    XCTAssertTrue([dict[@"WhateverKey"] isEqualToString:@"WhateverValue"]);
    
    NSArray *a = @[@"one", @"two"];
    XCTAssertTrue([dict[@"Array"] isEqualToArray:a]);
}

- (void)testSerializeDeserialize {

    NSDictionary *dict1 = @{
                           ACCodeSnippetTitleKey: @"title",
                           ACCodeSnippetSummaryKey: @"summary",
                           ACCodeSnippetContentsKey: @"line1\nline2\nline3\n",
                           @"WhateverKey": @"WhateverValue",
                           @"Array": @[@"one", @"two"],
                           };
    
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:dict1
                                                           format:ACCodeSnippetSerializationFormatC
                                                          options:0
                                                            error:nil];
    
    NSDictionary *dict2 = [ACCodeSnippetSerialization dictionaryWithData:data
                                                                options:0
                                                                 format:ACCodeSnippetSerializationFormatC
                                                                  error:nil];
    XCTAssertTrue([dict1 isEqualToDictionary:dict2]);
    
}



@end
