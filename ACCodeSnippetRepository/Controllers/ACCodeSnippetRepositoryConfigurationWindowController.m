//
//  ACCodeSnippetRepositoryConfigurationWindowController.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 06/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACCodeSnippetRepositoryConfigurationWindowController.h"
#import "ACCodeSnippetGitDataStore.h"
#import "IDECodeSnippetRepositorySwizzler.h"


@interface ACCodeSnippetRepositoryConfigurationWindowController ()
@property (nonatomic, strong) NSURL *snippetRemoteRepositoryURL;
@end

@implementation ACCodeSnippetRepositoryConfigurationWindowController

#pragma mark - Initialization 

// fork button -> fork + import all snippets + message "do you want to import all your current snippets in your git?"



- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.remoteRepositoryTextfield.stringValue = self.gitDataStore.remoteRepositoryURL.absoluteString?:@"";
}

- (ACCodeSnippetGitDataStore*)gitDataStore {
    if ([self.delegate respondsToSelector:@selector(dataStoresForCodeSnippetConfigurationWindowController:)]) {
        NSArray *dataStores = [self.delegate dataStoresForCodeSnippetConfigurationWindowController:self];
        for (id dataStore in dataStores) {
            if ([dataStore isKindOfClass:ACCodeSnippetGitDataStore.class]) {
                return dataStore;
            }
            break;
        }
    }
    return nil;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if (![[NSURL URLWithString:textField.stringValue] isEqualTo:self.gitDataStore.remoteRepositoryURL]) {
        self.forkRemoteRepositoryButton.enabled = YES;
    } else {
        self.forkRemoteRepositoryButton.enabled = NO;
    }
}


#pragma mark - Actions

- (IBAction)openSnippetDirectoryAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[self snippetDirectoryPath]];
}

- (IBAction)forkRemoteRepositoryAction:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to fork %@?", self.remoteRepositoryTextfield.stringValue]
                                     defaultButton:@"Fork"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"This will remove all snippets from the current git repository and replace them with snippets from the new fork."];
    
    __weak __block ACCodeSnippetRepositoryConfigurationWindowController *weakSelf = self;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
                
            case NSModalResponseCancel: {
                // nothing
                break;
            }
                
            case NSModalResponseOK: {
                
                [weakSelf.gitDataStore removeAllCodeSnippets];
                [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeDataStore:weakSelf.gitDataStore];
                
                ACCodeSnippetGitDataStore *dataStore = [[ACCodeSnippetGitDataStore alloc] initWithRemoteRepositoryURL:[NSURL URLWithString:weakSelf.remoteRepositoryTextfield.stringValue]];
                [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:dataStore];
                [dataStore importCodeSnippets];
                
                break;
            }
                
            default:
                break;
        }
    }];
}

#pragma mark -

- (NSString*)snippetDirectoryPath {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *snippetDirectoryPath = [NSString pathWithComponents:@[libraryPath, @"Developer", @"Xcode", @"UserData", @"CodeSnippets"]];
    return snippetDirectoryPath;
}

@end
