//
//  IDECodeSnippetRepositorySwizzler.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 11/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "IDECodeSnippetRepositorySwizzler.h"


static char const * const kIDECodeSnippetRepositorySwizzledDataStores = "kIDECodeSnippetRepositorySwizzledDataStores";


@implementation IDECodeSnippetRepositorySwizzler

+ (void)load {
    [[NSBundle bundleWithIdentifier:@"com.apple.dt.IDE.IDECodeSnippetLibrary"] load];
    [self swizzleWithClass:NSClassFromString(@"IDECodeSnippetRepository")];
}

#pragma mark - overrides

- (void)override_saveUserCodeSnippetToDisk:(id)arg1 { // saveUserCodeSnippetToDisk: instead of addCodeSnippet: so to catch edits as well
    NSLog(@"saveUserCodeSnippetToDisk: %@", arg1);
    
    NSLog(@"%@", [self dataStores]);
    for (id<ACCodeSnippetDataStoreProtocol> dataStore in [self dataStores]) {
        [dataStore addCodeSnippet:(IDECodeSnippet*)arg1];
    }
    
    [self override_saveUserCodeSnippetToDisk:arg1];
}

- (void)override_removeCodeSnippet:(id)arg1 {
    NSLog(@"removeCodeSnippet: %@", arg1);
    
    for (id<ACCodeSnippetDataStoreProtocol> dataStore in [self dataStores]) {
        [dataStore removeCodeSnippet:(IDECodeSnippet*)arg1];
    }
    
    [self override_removeCodeSnippet:arg1];
}


#pragma mark - properties

- (NSArray*)override_dataStores {
    return objc_getAssociatedObject(self, kIDECodeSnippetRepositorySwizzledDataStores);
}

- (void)override_setDataStores:(NSArray*)dataStores {
    objc_setAssociatedObject(self, kIDECodeSnippetRepositorySwizzledDataStores, dataStores, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)override_addDataStore:(id<ACCodeSnippetDataStoreProtocol>)dataStore {
    NSMutableArray *dataStores = [[self dataStores] mutableCopy];
    if (!dataStores) {
        dataStores = [@[] mutableCopy];
    }
    [dataStores addObject:dataStore];
    [self setDataStores:dataStores];
    
    NSLog(@"-- %@", dataStore);
    NSLog(@"-- %@", [self dataStores]);
}

@end
