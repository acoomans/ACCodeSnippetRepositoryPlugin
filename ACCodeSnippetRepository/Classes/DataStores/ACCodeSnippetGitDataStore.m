//
//  ACCodeSnippetGitDataStore.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 12/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACCodeSnippetGitDataStore.h"
#import "ACCodeSnippetSerialization.h"
#import "NSString+Path.h"
#import "IDECodeSnippetRepositorySwizzler.h"


@implementation ACCodeSnippetGitDataStore

- (id)initWithGitRepository:(ACGitRepository*)gitRepository {
    self = [super init];
    if (self) {
        self.mainQueue = [[NSOperationQueue alloc] init];
        self.gitRepository = gitRepository;
    }
    return self;
}


#pragma mark - Properties

- (void)setGitRepository:(ACGitRepository *)gitRepository {
    _gitRepository = gitRepository;
    gitRepository.localRepositoryPath = self.localRepositoryPath;
}


#pragma mark - ACCodeSnippetDataStoreProtocol

- (void)addCodeSnippet:(IDECodeSnippet*)snippet {
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore addCodeSnippet: %@", snippet);
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        if (![blockSnippet.title isEqualToString:@"My Code Snippet"]) {
            [weakSelf removeAllFilesForSnippet:blockSnippet];
            [weakSelf addFileForSnippet:blockSnippet];
            [weakSelf.gitRepository commit];
            [weakSelf.gitRepository push];
        }
    }];
    [self.mainQueue addOperation:blockOperation];
    
}

- (void)removeCodeSnippet:(IDECodeSnippet*)snippet {
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore removeCodeSnippet: %@", snippet);
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf removeAllFilesForSnippet:blockSnippet];
        [weakSelf.gitRepository commit];
        [weakSelf.gitRepository push];
    }];
    [self.mainQueue addOperation:blockOperation];
}

- (void)updateCodeSnippets {
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore updateCodeSnippets");
    
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf.gitRepository fetch];
        
        NSMutableDictionary *changes = [[weakSelf.gitRepository changedFilesWithOrigin] mutableCopy];
        
        [weakSelf updateDeletedFiles:changes[ACGitRepositoryFileChangeDeletedKey]];
        [weakSelf updateDeletedFiles:changes[ACGitRepositoryFileChangeModifiedKey]];
        
        [weakSelf.gitRepository pull];
        
        [weakSelf updateAddedFiles:changes[ACGitRepositoryFileChangeAddedKey]];
        [weakSelf updateAddedFiles:changes[ACGitRepositoryFileChangeModifiedKey]];
        
        [weakSelf.gitRepository commit];
        [weakSelf.gitRepository push];
    }];
    [self.mainQueue addOperation:blockOperation];
}


#pragma mark - file operations

- (void)addFileForSnippet:(IDECodeSnippet*)snippet {
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:[snippet dictionaryRepresentation]
                                                           format:0
                                                          options:0
                                                            error:nil];
    
    NSString *textFilename =  [[[[snippet.title lowercaseString] stringByAppendingString:@".m"] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringBySanitizingFilename];
    NSString *textPath = [NSString pathWithComponents:@[self.localRepositoryPath, textFilename]];
    
    [data writeToFile:textPath atomically:YES];
}

- (void)removeAllFilesForSnippet:(IDECodeSnippet*)snippet {
    
    NSError *error = nil;
    for (NSString *textFilename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                                       error:&error]) {
        
        NSString *textPath = [self.localRepositoryPath stringByAppendingPathComponent:textFilename];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:textPath isDirectory:&isDirectory];
        
        if (!isDirectory && ![textFilename hasPrefix:@"."]) {
            
            NSString *s = [NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:&error];
            if ([s rangeOfString:snippet.identifier].location != NSNotFound) {
                [[NSFileManager defaultManager] removeItemAtPath:textPath error:&error];
            }
        }
    }
}

#pragma mark -

- (NSString*)snippetDirectoryPath {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *snippetDirectoryPath = [NSString pathWithComponents:@[libraryPath, @"Developer", @"Xcode", @"UserData", @"CodeSnippets"]];
    return snippetDirectoryPath;
}

- (NSString*)localRepositoryPath {
    return [NSString pathWithComponents:@[self.snippetDirectoryPath, @"git"]];
}


#pragma mark -

- (void)updateDeletedFiles:(NSArray*)array {
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
        IDECodeSnippet *s = [[NSClassFromString(@"IDECodeSnippet") alloc] initWithDictionaryRepresentation:dict];
        
        IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] codeSnippetForIdentifier:s.identifier];
        
        if (snippet) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeCodeSnippet:snippet];
            });
        }
    }
}

- (void)updateAddedFiles:(NSArray*)array {
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
        
        IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippet") alloc] initWithDictionaryRepresentation:dict];

        [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addCodeSnippet:snippet];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] override_saveUserCodeSnippetToDisk:snippet];
        });
    }
}

@end
