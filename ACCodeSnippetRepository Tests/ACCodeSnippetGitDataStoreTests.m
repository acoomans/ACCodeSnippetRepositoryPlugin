//
//  ACCodeSnippetGitDataStoreTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 13/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ACCodeSnippetGitDataStore.h"


@interface ACCodeSnippetGitDataStoreTests : XCTestCase
@end

@implementation ACCodeSnippetGitDataStoreTests


- (void)testExample {
    
    ACGitRepository *gitRepository = [[ACGitRepository alloc] init];
    ACCodeSnippetGitDataStore *gitDataStore = [[ACCodeSnippetGitDataStore alloc] initWithGitRepository:gitRepository];
    
    [gitDataStore syncCodeSnippets];
    
}

@end
