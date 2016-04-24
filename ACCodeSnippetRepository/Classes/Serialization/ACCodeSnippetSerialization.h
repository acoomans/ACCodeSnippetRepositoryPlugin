//
//  ACCodeSnippetSerialization.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ACCodeSnippetIdentifierKey;
extern NSString * const ACCodeSnippetTitleKey;
extern NSString * const ACCodeSnippetSummaryKey;
extern NSString * const ACCodeSnippetContentsKey;
extern NSString * const ACCodeSnippetUserSnippetKey;
extern NSString * const ACCodeSnippetLanguageKey;

extern NSString * const ACCodeSnippetLanguageObjectiveC;


typedef NS_ENUM(NSUInteger, ACCodeSnippetSerializationFormat) {
    ACCodeSnippetSerializationFormatC
};

typedef NSUInteger ACCodeSnippetSerializationWriteOptions;
typedef NSUInteger ACCodeSnippetSerializationReadOptions;


@interface ACCodeSnippetSerialization : NSObject

+ (NSData *)dataWithDictionary:(NSDictionary*)dict
                        format:(ACCodeSnippetSerializationFormat)format
                       options:(ACCodeSnippetSerializationWriteOptions)opt
                         error:(NSError**)error;

+ (id)dictionaryWithData:(NSData*)data
                 options:(ACCodeSnippetSerializationReadOptions)opt
                  format:(ACCodeSnippetSerializationFormat)format
                   error:(NSError**)error;

+ (NSString*)identifier;

@end
