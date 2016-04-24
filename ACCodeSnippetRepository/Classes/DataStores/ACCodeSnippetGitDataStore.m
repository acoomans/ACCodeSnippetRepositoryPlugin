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
#import "NSDictionary+Merge.h"

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
        self.mainQueue.maxConcurrentOperationCount = 1;
        self.gitRepository = gitRepository;
    }
    return self;
}


#pragma mark - Properties

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

- (void)dataStoreWillAdd {
    NSLog(@"%@ dataStoreWillAdd", self);
    if (![self.gitRepository localRepositoryExists]) {
        [self.gitRepository forkRemoteRepositoryWithURL:self.remoteRepositoryURL inDirectory:self.localRepositoryPath];
    }
}

- (void)dataStoreDidAdd {
    NSLog(@"%@ dataStoreDidAdd", self);
}

- (void)dataStoreWillRemove {
    NSLog(@"%@ dataStoreWillRemove", self);
    [self.mainQueue waitUntilAllOperationsAreFinished];
}

- (void)dataStoreDidRemove {
    NSLog(@"%@ dataStoreDidRemove", self);
}


- (void)addCodeSnippet:(IDECodeSnippet*)snippet {
    if (!self.gitRepository) return;
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak typeof(self)weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"%@ addCodeSnippet: %@", weakSelf, snippet);
        
        if (![blockSnippet.title isEqualToString:@"My Code Snippet"]) {
            //[weakSelf removeAllFilesInLocalRepositoryForSnippet:blockSnippet];
            [weakSelf addFileInLocalRepositoryForSnippet:blockSnippet overwrite:YES];
            [weakSelf.gitRepository commit];
            [weakSelf.gitRepository push];
        }
    }];
    [self.mainQueue addOperation:blockOperation];
    
}

- (void)removeCodeSnippet:(IDECodeSnippet*)snippet {
    if (!self.gitRepository) return;
    
    __block IDECodeSnippet *blockSnippet = snippet;
    __weak typeof(self)weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"%@ removeCodeSnippet: %@", weakSelf, snippet);
        
        [weakSelf removeAllFilesInLocalRepositoryForSnippet:blockSnippet];
        [weakSelf.gitRepository commit];
        [weakSelf.gitRepository push];
    }];
    [self.mainQueue addOperation:blockOperation];
}

- (void)syncCodeSnippets {
    if (!self.gitRepository) return;
    
    __weak typeof(self)weakSelf = self;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"%@ updateCodeSnippets", weakSelf);
        
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

- (void)importAllCodeSnippets {
    
    NSLog(@"%@ importCodeSnippets", self);
    
    NSError *error = nil;
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                             error:&error];
    [self updateSnippetsForFilesInLocalRepository:filenames];
}

- (void)exportAllCodeSnippets {
    NSLog(@"%@ exportAllCodeSnippets", self);
    
    IDECodeSnippetRepository *codeSnippetRepository = [NSClassFromString(@"IDECodeSnippetRepository") sharedRepository];
    for (IDECodeSnippet *snippet in codeSnippetRepository.codeSnippets) {
        [self addFileInLocalRepositoryForSnippet:snippet overwrite:NO];
    }
    [self.gitRepository commitWithMessage:@"Imported user code snippets"];
    [self.gitRepository push];
}

- (void)removeAllCodeSnippets {
    
    NSLog(@"%@ removeAllCodeSnippets", self);
    
    NSError *error = nil;
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                             error:&error];
    [self removeSnippetsForFilesInLocalRepository:filenames];
}



#pragma mark - File operations

- (BOOL)addFileInLocalRepositoryForSnippet:(IDECodeSnippet*)snippet overwrite:(BOOL)overwrite {
    
    NSLog(@"%@ addFileInLocalRepositoryForSnippet: %@", self, snippet);
    
    NSData *data = [ACCodeSnippetSerialization dataWithDictionary:[snippet dictionaryRepresentation]
                                                           format:0
                                                          options:0
                                                            error:nil];
    
    NSString *filename = [self fileInLocalRepositoryForSnippet:snippet];
    if (!filename) {
        filename = [[[[snippet.title lowercaseString] stringByAppendingString:@".m"] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringBySanitizingFilename];
    }
    
    NSString *path = [NSString pathWithComponents:@[self.localRepositoryPath, filename]];
    
    if (overwrite || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [data writeToFile:path atomically:YES];
        return YES;
    }
    return NO;
}

- (void)removeAllFilesInLocalRepositoryForSnippet:(IDECodeSnippet*)snippet {
    
    NSLog(@"%@ removeAllFilesInLocalRepositoryForSnippet: %@", self, snippet);
    
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

- (NSString*)fileInLocalRepositoryForSnippet:(IDECodeSnippet*)snippet {
    
    NSError *error = nil;
    for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localRepositoryPath
                                                                                   error:&error]) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if ([s rangeOfString:snippet.identifier].location != NSNotFound) {
                return filename;
            }
        }
    }
    return nil;
}


#pragma mark - Snippet operations

- (void)updateSnippetsForFilesInLocalRepository:(NSArray*)array {
    
    NSLog(@"%@ updateSnippetsForFilesInLocalRepository: %@", self, array);
    
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
            
            dict = [dict dictionaryByMergingDictionary:@{
                                                         ACCodeSnippetTitleKey: [filename stringByDeletingPathExtension],
                                                         ACCodeSnippetIdentifierKey: [ACCodeSnippetSerialization identifier],
                                                         ACCodeSnippetUserSnippetKey: @(YES),
                                                         ACCodeSnippetLanguageKey: ACCodeSnippetLanguageObjectiveC,
                                                         }];

            __block IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippet") alloc] initWithDictionaryRepresentation:dict];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                IDECodeSnippetRepository *repository = [NSClassFromString(@"IDECodeSnippetRepository") sharedRepository];
                [repository override_saveUserCodeSnippetToDisk:snippet];
                
                if (![repository codeSnippetForIdentifier:snippet.identifier]) {
                    [repository addCodeSnippet:snippet];
                }
                
                NSData *data = [ACCodeSnippetSerialization dataWithDictionary:dict
                                                                       format:0
                                                                      options:0
                                                                        error:nil];
                [data writeToFile:path atomically:YES];
            });
        }
    }
}

- (void)removeSnippetsForFilesInLocalRepository:(NSArray*)array {
    
    NSLog(@"%@ removeSnippetsForFilesInLocalRepository: %@", self, array);
    
    NSError *error;
    
    for (NSString *filename in array) {
        
        NSString *path = [self.localRepositoryPath stringByAppendingPathComponent:filename];
        
        if ([self isSnippetFileAtPath:path]) {
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSDictionary *dict = [ACCodeSnippetSerialization dictionaryWithData:data options:0 format:0 error:&error];
            
            if (dict[ACCodeSnippetIdentifierKey]) {
                
                // be sure to remove the snippet actually in the repository
                __block IDECodeSnippet *snippet = [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] codeSnippetForIdentifier:dict[ACCodeSnippetIdentifierKey]];
                
                if (snippet) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeCodeSnippet:snippet];
                    });
                }
            }
            
        }
    }
}

#pragma mark - path and files

- (NSString*)pathForSnippetDirectory {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    return [NSString pathWithComponents:@[libraryPath, @"Developer", @"Xcode", @"UserData", @"CodeSnippets"]];
}

- (NSString*)localRepositoryPath {
    return [self pathForSnippetDirectory];
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

#pragma mark - description

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ (%@)", [super description], self.remoteRepositoryURL];
}

@end
