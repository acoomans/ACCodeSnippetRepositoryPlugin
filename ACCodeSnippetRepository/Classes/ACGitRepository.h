//
//  ACGitRepository.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACGitRepository : NSObject

@property (nonatomic, copy) NSString *localRepositoryPath;
@property (nonatomic, copy) NSString *taskLog;

- (instancetype)initWithLocalRepositoryDirectory:(NSString*)localRepositoryPath;

- (BOOL)localRepositoryExists;

- (void)initializeLocalRepository;
- (void)initializeLocalRepositoryInDirectory:(NSString*)localRepositoryPath;

- (void)forkRemoteRepositoryWithURL:(NSURL*)remoteRepositoryURL inDirectory:(NSString*)localRepositoryPath;

- (void)commit;
- (void)pull;
- (void)push;

- (void)updateLocalWithRemoteRepository;

- (void)removeLocalRepository;

@end
