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

- (instancetype)init {
    return [self initWithRemoteRepositoryURL:nil];
}

- (id)initWithRemoteRepositoryURL:(NSURL*)remoteRepositoryURL {
    ACGitRepository *gitRepository = [[ACGitRepository alloc] initWithLocalRepositoryDirectory:self.localRepositoryPath];
    if (remoteRepositoryURL && !gitRepository.localRepositoryExists) {
        [gitRepository forkRemoteRepositoryWithURL:remoteRepositoryURL inDirectory:self.localRepositoryPath];
    }
    return [self initWithGitRepository:gitRepository];
}

- (id)initWithGitRepository:(ACGitRepository*)gitRepository {
    self = [super init];
    if (self) {
        self.mainQueue = [[NSOperationQueue alloc] init];
        self.gitRepository = gitRepository;
    }
    return self;
}


#pragma mark - Properties

- (void)dataStoreWillAdd {
    if (![self.gitRepository localRepositoryExists]) {
        [self.gitRepository forkRemoteRepositoryWithURL:self.remoteRepositoryURL inDirectory:self.localRepositoryPath];
    }
}

- (void)dataStoreDidAdd {
    self.mainQueue.suspended = NO;
}

- (void)dataStoreWillRemove {
    self.mainQueue.suspended = YES;
    [self.mainQueue waitUntilAllOperationsAreFinished];
}

- (void)dataStoreDidRemove {
    [self.gitRepository removeLocalRepository];
}

- (void)setGitRepository:(ACGitRepository *)gitRepository {
    _gitRepository = gitRepository;
    gitRepository.localRepositoryPath = self.localRepositoryPath;
}

- (NSURL*)remoteRepositoryURL {
    return self.gitRepository.remoteRepositoryURL;
}

- (void)setRemoteRepositoryURL:(NSURL *)remoteRepositoryURL {
    self.gitRepository.remoteRepositoryURL = remoteRepositoryURL;
}

#pragma mark - ACCodeSnippetDataStoreProtocol

- (void)addCodeSnippet:(IDECodeSnippet*)snippet {
    if (!self.gitRepository) return;
    
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore addCodeSnippet: %@", snippet);
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        if (![blockSnippet.title isEqualToString:@"My Code Snippet"]) {
            [weakSelf removeAllFilesInLocalRepositoryForSnippet:blockSnippet];
            [weakSelf addFileInLocalRepositoryForSnippet:blockSnippet];
            [weakSelf.gitRepository commit];
            [weakSelf.gitRepository push];
        }
    }];
    [self.mainQueue addOperation:blockOperation];
    
}

- (void)removeCodeSnippet:(IDECodeSnippet*)snippet {
    if (!self.gitRepository) return;
    
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore removeCodeSnippet: %@", snippet);
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf removeAllFilesInLocalRepositoryForSnippet:blockSnippet];
        [weakSelf.gitRepository commit];
        [weakSelf.gitRepository push];
    }];
    [self.mainQueue addOperation:blockOperation];
}

- (void)updateCodeSnippets {
    if (!self.gitRepository) return;
    
    NSLog(@"ACCodeSnippetRepositoryPlugin -- GitDataStore updateCodeSnippets");
    
    __weak ACCodeSnippetGitDataStore *weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf.gitRepository fetch];
        
        NSMutableDictionary *changes = [[weakSelf.gitRepository changedFilesWithOrigin] mutableCopy];
        
        [weakSelf removeSnippetsForFilesInLocalRepository:changes[ACGitRepositoryFileChangeDeletedKey]];
        [weakSelf removeSnippetsForFilesInLocalRepository:changes[ACGitRepositoryFileChangeModifiedKey]];
        
        [weakSelf.gitRepository pull];
        
        [weakSelf updateSnippetsForFilesInLocalRepository:changes[ACGitRepositoryFileChangeAddedKey]];
        [weakSelf updateSnippetsForFilesInLocalRepository:changes[ACGitRepositoryFileChangeModifiedKey]];
        
        [weakSelf.gitRepository commit];
        [weakSelf.gitRepository push];
    }];
    [self.mainQueue addOperation:blockOperation];
}

- (void)removeAllCodeSnippets {
    NSError *error = nil;
    
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                             error:&error];
    [self removeSnippetsForFilesInLocalRepository:filenames];
}

- (void)importCodeSnippets {
    NSError *error = nil;
    
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                             error:&error];
    [self updateSnippetsForFilesInLocalRepository:filenames];

}

#pragma mark - file operations

- (void)addFileInLocalRepositoryForSnippet:(IDECodeSnippet*)snippet {
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:[snippet dictionaryRepresentation]
                                                           format:0
                                                          options:0
                                                            error:nil];
    
    NSString *textFilename =  [[[[snippet.title lowercaseString] stringByAppendingString:@".m"] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringBySanitizingFilename];
    NSString *textPath = [NSString pathWithComponents:@[self.localRepositoryPath, textFilename]];
    
    [data writeToFile:textPath atomically:YES];
}

- (void)removeAllFilesInLocalRepositoryForSnippet:(IDECodeSnippet*)snippet {
    
    NSError *error = nil;
    for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                                       error:&error]) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if ([s rangeOfString:snippet.identifier].location != NSNotFound) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
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

- (void)removeSnippetsForFilesInLocalRepository:(NSArray*)array {
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
            
            if (dict[ACCodeSnippetIdentifierKey]) {
                
                // we need the snippet identifier
                IDECodeSnippet *s = [[NSClassFromString(@"IDECodeSnippet") alloc] initWithDictionaryRepresentation:dict];
                
                // be sure to remove the snippet actually in the repository
                IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] codeSnippetForIdentifier:s.identifier];
                
                if (snippet) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeCodeSnippet:snippet];
                    });
                }
            }
            
        }
    }
}

- (void)updateSnippetsForFilesInLocalRepository:(NSArray*)array {
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
            
            if (!dict[ACCodeSnippetTitleKey]) {
                NSMutableDictionary *mutableDict = [dict mutableCopy];
                mutableDict[ACCodeSnippetTitleKey] = [filename stringByDeletingPathExtension];
                dict = mutableDict;
            }

            if (!dict[ACCodeSnippetIdentifierKey]) {
                NSMutableDictionary *mutableDict = [dict mutableCopy];
                mutableDict[ACCodeSnippetIdentifierKey] = [ACCodeSnippetSerialization identifier];
                dict = mutableDict;
            }
            
            IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippet") alloc] initWithDictionaryRepresentation:dict];
            
            [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addCodeSnippet:snippet];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // (not calling the overriden version) this will re-save the snippet with Xcode's metadata
                [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] saveUserCodeSnippetToDisk:snippet];
            });
        }
    }
}

- (BOOL)isSnippetFileAtPath:(NSString*)path {
    
    NSString *filename = [path lastPathComponent];
    
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    return (
            exists &&
            !isDirectory &&
            ![filename hasPrefix:@"."] &&
            (
             [filename hasSuffix:@".c"] ||
             [filename hasSuffix:@".m"] ||
             [filename hasSuffix:@".h"] ||
             [filename hasSuffix:@".cpp"] ||
             [filename hasSuffix:@".s"]
             )
            );
}

@end
