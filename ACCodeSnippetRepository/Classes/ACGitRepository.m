//
//  ACGitRepository.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACGitRepository.h"
#import "NSTask+Extras.h"

NSString * const ACGitRepositoryFileChangeModifiedKey = @"M";
NSString * const ACGitRepositoryFileChangeCopiedKey = @"C";
NSString * const ACGitRepositoryFileChangeRenamedKey = @"R";
NSString * const ACGitRepositoryFileChangeAddedKey = @"A";
NSString * const ACGitRepositoryFileChangeDeletedKey = @"D";
NSString * const ACGitRepositoryFileChangeUnmergedKey = @"U";


@implementation ACGitRepository

- (instancetype)initWithLocalRepositoryDirectory:(NSString*)localRepositoryPath {
    self = [super init];
    if (self) {
        self.localRepositoryPath = localRepositoryPath;
    }
    return self;
}

- (NSURL*)remoteRepositoryURL {
    if (![self localRepositoryExists]) return nil;
    
    NSPipe *pipe = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/git";
    task.arguments = @[@"remote", @"-v"];
    task.currentDirectoryPath = self.localRepositoryPath;
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] availableData];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray *array = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (array.count > 2) {
        return [NSURL URLWithString:array[1]];
    }
    
    return nil;
}

- (void)setRemoteRepositoryURL:(NSURL *)remoteRepositoryURL {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"remote", @"set-url", @"origin", remoteRepositoryURL.absoluteString]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
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

- (NSString*)identifierForCurrentCommit {
    if (![self localRepositoryExists]) return nil;
    
    NSPipe *pipe = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/git";
    task.arguments = @[@"rev-parse", @"HEAD"];
    task.currentDirectoryPath = self.localRepositoryPath;
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] availableData];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)commit {
    [self commitWithMessage:@""];
}

- (void)commitWithMessage:(NSString*)message {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"add", @"--all", @"."]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
    
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"commit", @"--allow-empty-message", @"-m", message]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
}

- (void)fetch {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                  arguments:@[@"fetch", @"origin"]
                     inCurrentDirectoryPath:self.localRepositoryPath
                     standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
}

- (void)pull {
    if (![self localRepositoryExists]) return;
    
    NSString *output;
    NSTask *task = [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                                 arguments:@[@"pull", @"-s", @"recursive", @"-X", @"theirs", @"--no-commit"]
                                    inCurrentDirectoryPath:self.localRepositoryPath
                                    standardOutputAndError:&output];
    self.taskLog = [self.taskLog stringByAppendingString:output];
    
    if (task.terminationStatus != 0) {
        [NSTask launchAndWaitTaskWithLaunchPath:@"/usr/bin/git"
                                      arguments:@[@"pull", @"-s", @"theirs", @"--no-commit"]
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

- (NSDictionary*)changedFilesSinceCommitWithIdentifier:(NSString*)identifier {
    return [self changedFilesSinceCommitWithIdentifier:identifier commitWithidentifier:@"HEAD"];
}

- (NSDictionary*)changedFilesWithOrigin {
    return [self changedFilesSinceCommitWithIdentifier:@"HEAD" commitWithidentifier:@"origin"];
}

- (NSDictionary*)changedFilesSinceCommitWithIdentifier:(NSString*)sinceIdentifier commitWithidentifier:(NSString*)toIdentifier {
    if (![self localRepositoryExists]) return nil;
    
    NSPipe *pipe = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/git";
    task.arguments = @[@"diff", @"--name-status", sinceIdentifier, toIdentifier];
    task.currentDirectoryPath = self.localRepositoryPath;
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] availableData];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    __block NSMutableDictionary *dictionary = [@{} mutableCopy];
    
    [output enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSError *error;
        NSString *pattern = @"(.?)\\s+(.*)";
        __block NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        [line enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            
            [regex enumerateMatchesInString:line
                                    options:0
                                      range:NSMakeRange(0, line.length)
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                     
                                     NSString *key = [line substringWithRange:[result rangeAtIndex:1]];
                                     NSString *value = [line substringWithRange:[result rangeAtIndex:2]];
                                     
                                     NSMutableArray *files = dictionary[key];
                                     if (!files) {
                                         dictionary[key] = files = [@[] mutableCopy];
                                     }
                                     
                                     [files addObject:value];
                                     
                                 }];
        }];
    }];
    return dictionary;
}

- (void)removeLocalRepository {
    if (![self localRepositoryExists]) return;
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:self.localRepositoryPath error:&error];
}

@end
