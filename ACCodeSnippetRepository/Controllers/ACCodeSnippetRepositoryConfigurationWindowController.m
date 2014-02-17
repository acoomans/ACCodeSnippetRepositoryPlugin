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
    [[NSWorkspace sharedWorkspace] openFile:[self pathForSnippetDirectory]];
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
                
                [self.window beginSheet:self.forkingRemoteRepositoryPanel completionHandler:nil];
                [self.progressIndicator startAnimation:self];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    
                    [self backupSnippets];
                    
                    [weakSelf.gitDataStore removeAllCodeSnippets];
                    [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeDataStore:weakSelf.gitDataStore];
                    
                    ACCodeSnippetGitDataStore *dataStore = [[ACCodeSnippetGitDataStore alloc] initWithRemoteRepositoryURL:[NSURL URLWithString:weakSelf.remoteRepositoryTextfield.stringValue]];
                    [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:dataStore];
                    [dataStore importCodeSnippets];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.window endSheet:self.forkingRemoteRepositoryPanel];
                        [self.progressIndicator stopAnimation:self];
                    });
                });

                break;
            }
                
            default:
                break;
        }
    }];
}

- (IBAction)backupAction:(id)sender {
    [self backupSnippets];
}

- (void)backupSnippets {
    NSError *error;
    if ([[NSFileManager defaultManager] createDirectoryAtPath:self.pathForBackupDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
        for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pathForSnippetDirectory error:&error]) {
            if ([filename hasSuffix:@".codesnippet"]) {
                NSString *path = [NSString pathWithComponents:@[self.pathForSnippetDirectory, filename]];
                NSString *toPath = [NSString pathWithComponents:@[self.pathForBackupDirectory, filename]];
                [[NSFileManager defaultManager] copyItemAtPath:path toPath:toPath error:&error];
            }
        }
    }
}

#pragma mark - Paths

- (NSString*)pathForSnippetDirectory {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    return [NSString pathWithComponents:@[libraryPath, @"Developer", @"Xcode", @"UserData", @"CodeSnippets"]];
}

- (NSString*)pathForBackupDirectory {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYMMdd-HHmm"];
    return [NSString pathWithComponents:@[self.pathForSnippetDirectory, [NSString stringWithFormat:@"backup-%@", [dateFormatter stringFromDate:currentDate]]]];
}

@end
