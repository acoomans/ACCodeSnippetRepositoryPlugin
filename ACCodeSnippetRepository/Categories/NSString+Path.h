//
//  NSString+Path.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 07/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Path)

- (NSString *)stringBySanitizingFilename;

@end
