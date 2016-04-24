//
//  NSDictionary+Merge.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 17/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Merge)

- (NSDictionary*)dictionaryByMergingDictionary:(NSDictionary*)dictionary;

@end
