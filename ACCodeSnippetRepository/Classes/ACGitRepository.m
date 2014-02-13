//
//  ACGitRepository.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACGitRepository.h"
#import "NSTask+Extras.h"

@implementation ACGitRepository

- (instancetype)initWithLocalRepositoryDirectory:(NSString*)localRepositoryPath {
    self = [super init];
    if (self) {
        self.localRepositoryPath = localRepositoryPath;
    }
    return self;
}

- (BOOL)localRepositoryExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.localRepositoryPath];
}

- (void)initializeLocalRepository {
    [self initializeLocalRepositoryInDirectory:self.localRepositoryPath];
}

- (void)initializeLocalRepositoryInDirectory:(NSString*)localRepositoryPath {
    if (
        ![[NSFileManager defaultManager] fileExistsAtPath:localRepositoryPath]) {
        
        NSString *output;
        [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                      arguments:@[@"init", localRepositoryPath]
                         inCurrentDirectoryPath:nil
                         standardOutputAndError:&output];
        self.taskLog = [self.taskLog stringByAppendingString:output];
        
        self.localRepositoryPath = localRepositoryPath;
    }
}

- (void)forkRemoteRepositoryWithURL:(NSURL*)remoteRepositoryURL inDirectory:(NSString*)localRepositoryPath {
    if (
        ![[NSFileManager defaultManager] fileExistsAtPath:localRepositoryPath] &&
        remoteRepositoryURL) {
        
        NSString *output;
        [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                      arguments:@[@"clone", remoteRepositoryURL.absoluteString, localRepositoryPath]
                         inCurrentDirectoryPath:nil
                         standardOutputAndError:&output];
        self.taskLog = [self.taskLog stringByAppendingString:output];
        
        self.localRepositoryPath = localRepositoryPath;
    }
}


- (void)commit {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"add", @"--all", @"."]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
    
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"commit", @"--allow-empty-message", @"-m", @""]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
}


- (void)pull {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    NSTask *task = [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                                 arguments:@[@"pull", @"-s", @"recursive", @"-X", @"ours", @"--no-commit"]
                                    inCurrentDirectoryPath:self.localRepositoryPath
                                    standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
    
    if (task.terminationStatus != 0) {
        [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                      arguments:@[@"pull", @"-s", @"ours", @"--no-commit"]
                         inCurrentDirectoryPath:self.localRepositoryPath
                         standardOutputAndError:&output];
        self.taskLog = [self.taskLog stringByAppendingString:output];
    }
    
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"commit", @"--allow-empty-message", @"-m", @""]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
}

- (void)push {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"push"]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
}

- (void)updateLocalWithRemoteRepository {
    [self commit];
    [self pull];
    [self commit];
    [self push];
}

- (void)removeLocalRepository {
    if (![self localRepositoryExists]) return;
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:self.localRepositoryPath error:&error];
}

@end
