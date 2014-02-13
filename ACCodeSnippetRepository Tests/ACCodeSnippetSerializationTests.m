//
//  ACCodeSnippetSerializationTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "ACCodeSnippetSerialization.h"

@interface ACCodeSnippetSerializationTests : SenTestCase
@end

@implementation ACCodeSnippetSerializationTests

- (void)testSerialize {
    
    NSDictionary *dict = @{
                           ACCodeSnippetTitleKey: @"title",
                           ACCodeSnippetSummaryKey: @"summary",
                           ACCodeSnippetContentsKey: @"content",
                           @"WhateverKey": @"WhateverValue",
                           };
    
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:dict
                                                           format:ACCodeSnippetSerializationFormatC
                                                          options:0
                                                            error:nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"\n%@", string);
    
    STAssertTrue([string rangeOfString:@"title"].location != NSNotFound, nil);
    STAssertTrue([string rangeOfString:@"summary"].location != NSNotFound, nil);
    STAssertTrue([string rangeOfString:@"content"].location != NSNotFound, nil);
    STAssertTrue([string rangeOfString:@"WhateverKey"].location != NSNotFound, nil);
    STAssertTrue([string rangeOfString:@"WhateverValue"].location != NSNotFound, nil);
}


- (void)testDeserialize {
    NSString *string = @"// title\n// summary\n//\n// WhateverKey: WhateverValue\ncontents\n";
    
    NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                 format:ACCodeSnippetSerializationFormatC
                                                                  error:nil];
    NSLog(@"\n%@", dict);
    
    STAssertTrue([dict[ACCodeSnippetTitleKey] isEqualToString:@"title"], nil);
    STAssertTrue([dict[ACCodeSnippetSummaryKey] isEqualToString:@"summary"], nil);
    STAssertTrue([dict[ACCodeSnippetContentsKey] isEqualToString:@"contents"], nil);
    STAssertTrue([dict[@"WhateverKey"] isEqualToString:@"WhateverValue"], nil);
}

- (void)testSerializeDeserialize {

    NSDictionary *dict1 = @{
                           ACCodeSnippetTitleKey: @"title",
                           ACCodeSnippetSummaryKey: @"summary",
                           ACCodeSnippetContentsKey: @"content",
                           @"WhateverKey": @"WhateverValue",
                           };
    
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:dict1
                                                           format:ACCodeSnippetSerializationFormatC
                                                          options:0
                                                            error:nil];
    
    NSDictionary *dict2 = [ACCodeSnippetSerialization dictionaryWithData:data
                                                                options:0
                                                                 format:ACCodeSnippetSerializationFormatC
                                                                  error:nil];
    STAssertTrue([dict1 isEqualToDictionary:dict2], nil);
    
}



@end
