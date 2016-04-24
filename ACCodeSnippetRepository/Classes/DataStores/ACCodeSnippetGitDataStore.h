//
//  ACCodeSnippetGitDataStore.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 12/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACCodeSnippetDataStoreProtocol.h"
#import "ACGitRepository.h"

@interface ACCodeSnippetGitDataStore : NSObject <ACCodeSnippetDataStoreProtocol>

@property (nonatomic, strong) ACGitRepository *gitRepository;
@property (nonatomic, strong) NSOperationQueue *mainQueue;
@property (nonatomic, strong, readonly) NSString *localRepositoryPath;
@property (nonatomic, copy) NSURL *remoteRepositoryURL;

- (id)initWithGitRepository:(ACGitRepository*)gitRepository;
- (id)initWithRemoteRepositoryURL:(NSURL*)remoteRepositoryURL;

@end
