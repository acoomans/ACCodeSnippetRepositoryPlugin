//
//  ACCodeSnippetRepositoryConfigurationWindowController.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 06/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACCodeSnippetRepositoryConfigurationWindowController.h"
#import "ACCodeSnippetDataStoreProtocol.h"
#import "ACCodeSnippetGitDataStore.h"
#import "IDECodeSnippetRepositorySwizzler.h"


@interface ACCodeSnippetRepositoryConfigurationWindowController ()
@property (nonatomic, strong) NSURL *snippetRemoteRepositoryURL;
@end

@implementation ACCodeSnippetRepositoryConfigurationWindowController

#pragma mark - Initialization


- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (NSArray*)dataStores {
    if ([self.delegate respondsToSelector:@selector(dataStoresForCodeSnippetConfigurationWindowController:)]) {
        return [self.delegate dataStoresForCodeSnippetConfigurationWindowController:self];
    }
    return nil;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if ([textField.stringValue length]) {
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
    
    [self.window endSheet:self.addRemoteRepositoryPanel];
    
    NSURL *remoteRepositoryURL = [NSURL URLWithString:self.remoteRepositoryTextfield.stringValue];
    
    BOOL isPresent = NO;
    for (id<ACCodeSnippetDataStoreProtocol>dataStore in self.dataStores) {
        if ([dataStore.remoteRepositoryURL isEqualTo:remoteRepositoryURL]) {
            isPresent = YES;
            break;
        }
    }
    
    if (!isPresent) {
        [self.window beginSheet:self.addingRemoteRepositoryPanel completionHandler:nil];
        [self.progressIndicator startAnimation:self];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            ACCodeSnippetGitDataStore *dataStore = [[ACCodeSnippetGitDataStore alloc] initWithRemoteRepositoryURL:remoteRepositoryURL];
            [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:dataStore];
            [dataStore importCodeSnippets];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.remoteRepositoriesTableView reloadData];
                [self.window endSheet:self.addingRemoteRepositoryPanel];
                [self.progressIndicator stopAnimation:self];
            });
        });
    } else {
        [[NSAlert alertWithError:[NSError errorWithDomain:@"Repository already exists" code:-1 userInfo:nil]] beginSheetModalForWindow:self.window completionHandler:nil];
    }
    
}

- (IBAction)addRemoteRepositoryAction:(id)sender {
    [self.window beginSheet:self.addRemoteRepositoryPanel completionHandler:nil];
}

- (IBAction)cancelSheet:(id)sender {
    [self.window endSheet:self.addRemoteRepositoryPanel];
}

- (IBAction)deleteRemoteRepositoryAction:(id)sender {
    
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to remove %@?", self.remoteRepositoryTextfield.stringValue]
                                     defaultButton:@"Remove"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"This will remove all snippets from the current git repository."];
    
    __weak __block ACCodeSnippetRepositoryConfigurationWindowController *weakSelf = self;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            [weakSelf backupSnippets];
            
            id<ACCodeSnippetDataStoreProtocol> dataStore = weakSelf.dataStores[weakSelf.remoteRepositoriesTableView.selectedRow];
            [dataStore removeAllCodeSnippets];
            [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeDataStore:dataStore];
            [weakSelf.remoteRepositoriesTableView reloadData];
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

- (IBAction)openGithubAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/acoomans/ACCodeSnippetRepositoryPlugin"]];
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

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self.dataStores count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    id<ACCodeSnippetDataStoreProtocol> dataStore = self.dataStores[rowIndex];
    return dataStore.remoteRepositoryURL;
}

@end
