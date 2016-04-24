//
//  ACGitRepository.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ACGitRepositoryFileChangeModifiedKey;
extern NSString * const ACGitRepositoryFileChangeCopiedKey;
extern NSString * const ACGitRepositoryFileChangeRenamedKey;
extern NSString * const ACGitRepositoryFileChangeAddedKey;
extern NSString * const ACGitRepositoryFileChangeDeletedKey;
extern NSString * const ACGitRepositoryFileChangeUnmergedKey;


@interface ACGitRepository : NSObject

@property (nonatomic, copy) NSURL *remoteRepositoryURL;
@property (nonatomic, copy) NSString *localRepositoryPath;
@property (nonatomic, copy) NSString *taskLog;

- (instancetype)initWithLocalRepositoryDirectory:(NSString*)localRepositoryPath;

- (BOOL)localRepositoryExists;

- (void)initializeLocalRepository;
- (void)initializeLocalRepositoryInDirectory:(NSString*)localRepositoryPath;

- (void)forkRemoteRepositoryWithURL:(NSURL*)remoteRepositoryURL inDirectory:(NSString*)localRepositoryPath;

- (NSString*)identifierForCurrentCommit;

- (void)commit;
- (void)commitWithMessage:(NSString*)message;
- (void)fetch;
- (void)pull;
- (void)push;

- (void)updateLocalWithRemoteRepository;

- (NSDictionary*)changedFilesSinceCommitWithIdentifier:(NSString*)sinceIdentifier commitWithidentifier:(NSString*)toIdentifier;
- (NSDictionary*)changedFilesSinceCommitWithIdentifier:(NSString*)identifier;
- (NSDictionary*)changedFilesWithOrigin;

- (void)removeLocalRepository;

@end
