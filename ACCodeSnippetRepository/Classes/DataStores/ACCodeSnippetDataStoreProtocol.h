//
//  ACCodeSnippetDataStoreProtocol.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 12/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDE.h"

@protocol ACCodeSnippetDataStoreProtocol <NSObject>

- (void)addCodeSnippet:(IDECodeSnippet*)snippet;
- (void)removeCodeSnippet:(IDECodeSnippet*)snippet;
- (void)updateCodeSnippets;

@end
