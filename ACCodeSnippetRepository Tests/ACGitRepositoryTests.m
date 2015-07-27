//
//  ACGitRepositoryTests.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ACGitRepository.h"

@interface ACGitRepositoryTests : XCTestCase
@end

@implementation ACGitRepositoryTests

- (void)testExample {
    
    NSURL *gitURL = [NSURL URLWithString:@"git@github.com:acoomans/test.git"];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *gitPath = [NSString pathWithComponents:@[libraryPath, @"Developer", @"Xcode", @"UserData", @"CodeSnippets", @"git"]];
    
    ACGitRepository *git = [[ACGitRepository alloc] initWithLocalRepositoryDirectory:gitPath];
    
    //[git cloneRemoteRepositoryWithURL:gitURL inDirectory:gitPath];
    //[git removeLocalRepository];
    //NSLog(@"%@", [git identifierForCurrentCommit]);
    //NSLog(@"%@", [git changedFilesSinceCommitWithIdentifier:@"HEAD~6"]);
    
    git.remoteRepositoryURL = gitURL;
    NSLog(@"%@", [git remoteRepositoryURL]);
    
}

@end
