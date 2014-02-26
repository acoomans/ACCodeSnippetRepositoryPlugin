//
//  ACCodeSnippetSerialization.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACCodeSnippetSerialization.h"

NSString * const ACCodeSnippetIdentifierKey = @"IDECodeSnippetIdentifier";
NSString * const ACCodeSnippetTitleKey = @"IDECodeSnippetTitle";
NSString * const ACCodeSnippetSummaryKey = @"IDECodeSnippetSummary";
NSString * const ACCodeSnippetContentsKey = @"IDECodeSnippetContents";
NSString * const ACCodeSnippetUserSnippetKey = @"IDECodeSnippetUserSnippet";
NSString * const ACCodeSnippetLanguageKey = @"IDECodeSnippetLanguage";

NSString * const ACCodeSnippetLanguageObjectiveC = @"Xcode.SourceCodeLanguage.Objective-C";


@implementation ACCodeSnippetSerialization


+ (NSData *)dataWithDictionary:(NSDictionary*)dict
                        format:(ACCodeSnippetSerializationFormat)format
                       options:(ACCodeSnippetSerializationWriteOptions)opt
                         error:(NSError**)error {
    
    NSString *title = dict[ACCodeSnippetTitleKey];
    NSString *summary = dict[ACCodeSnippetSummaryKey];
    NSString *contents = dict[ACCodeSnippetContentsKey];
    
    NSMutableDictionary *mutableDictionary = [dict mutableCopy];
    [mutableDictionary removeObjectsForKeys:@[ACCodeSnippetTitleKey, ACCodeSnippetSummaryKey, ACCodeSnippetContentsKey]];
    dict = mutableDictionary;
    
    NSMutableString *string = [@"" mutableCopy];
    
    [string appendFormat:@"// %@\n", (title?:@"")];
    [string appendFormat:@"// %@\n", (summary?:@"")];
    [string appendString:@"//\n"];
    
    for (NSString *key in [[dict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        
        id value = dict[key];
        
        if ([value isKindOfClass:NSArray.class]) {
            value = [NSString stringWithFormat:@"[%@]", [value componentsJoinedByString:@","]];
        }
        [string appendFormat:@"// %@: %@\n", key, value];
    }
    
    [string appendString:(contents?:@"")];
    
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}


+ (id)dictionaryWithData:(NSData*)data
                 options:(ACCodeSnippetSerializationReadOptions)opt
                  format:(ACCodeSnippetSerializationFormat)format
                   error:(NSError**)error {
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *dict = [@{} mutableCopy];

    __block BOOL isParsingHeader = YES;
    __block NSString *contents = @"";
    
    NSString *pattern = @"//\\s*(\\w*)\\s*:\\s*(.*)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:error];
    __block int i = 0;
    [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        if (![line hasPrefix:@"//"]) {
            isParsingHeader = NO;
        }
        
        if (isParsingHeader) {
            __block NSString *key = nil;
            __block id value = nil;
            [regex enumerateMatchesInString:line
                                    options:0
                                      range:NSMakeRange(0, line.length)
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                     
                                     key = [line substringWithRange:[result rangeAtIndex:1]];
                                     value = [[line substringWithRange:[result rangeAtIndex:2]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                     
                                     if ([value hasPrefix:@"["] && [value hasSuffix:@"]"]) {
                                         value = [[value substringWithRange:NSMakeRange(1, [value length]-2)] componentsSeparatedByString:@","];
                                     }
                                     
                                     if ([@"title|name" rangeOfString:[key lowercaseString]].location != NSNotFound) {
                                         key = ACCodeSnippetTitleKey;
                                     }
                                     
                                     if ([@"description|summary" rangeOfString:[key lowercaseString]].location != NSNotFound) {
                                         key = ACCodeSnippetSummaryKey;
                                     }
                                     
                                     dict[key] = value;
                                 }];
            
            if (!key && !value) {
                if (i < 2) {
                    value = [[line substringWithRange:NSMakeRange(2, line.length-2)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (i == 0) {
                        dict[ACCodeSnippetTitleKey] = value;
                    }
                    if (i == 1) {
                        dict[ACCodeSnippetSummaryKey] = value;
                    }
                }
            }
            
        } else {
            contents = [contents stringByAppendingFormat:@"%@\n", line]; //stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        i++;
    }];
    
    dict[ACCodeSnippetContentsKey] = contents;
    
    return [dict copy];
}

#pragma mark - 

+ (NSString*)identifier {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    NSString *uuidString = [NSString stringWithString:(__bridge NSString*)strRef];
    CFRelease(strRef);
    CFRelease(uuidRef);
    return uuidString;
}

@end
