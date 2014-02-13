//
//  IDECodeSnippetRepositorySwizzler.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "Swizzler.h"
#import "IDE.h"
#import "ACCodeSnippetDataStoreProtocol.h"

@interface IDECodeSnippetRepository (Swizzled)
@property (nonatomic, strong) NSArray *dataStores;
- (void)addDataStore:(id<ACCodeSnippetDataStoreProtocol>)dataStore;
@end

@interface IDECodeSnippetRepositorySwizzler : Swizzler
@property (nonatomic, strong) NSArray *dataStores;
@end
