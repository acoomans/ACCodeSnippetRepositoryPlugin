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
#import "ACCodeSnippetGitDataStore.h"


NSString * const ACCodeSnippetRepositoryUpdateRegularlyKey = @"ACCodeSnippetRepositoryUpdateRegularlyKey";


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
    self.remoteRepositoryTextfield.stringValue = self.gitDataStore.remoteRepositoryURL.absoluteString?:@"";
    
    self.updateRegularlyCheckbox.state = [[[NSUserDefaults standardUserDefaults] objectForKey:ACCodeSnippetRepositoryUpdateRegularlyKey] integerValue];
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
    
    if ([textField.stringValue length]) {
        self.importButton.enabled = YES;
    } else {
        self.importButton.enabled = NO;
    }
}

#pragma mark - Actions

- (IBAction)updateCheckboxAction:(NSButton*)button {
    [[NSUserDefaults standardUserDefaults] setObject:@(button.state) forKey:ACCodeSnippetRepositoryUpdateRegularlyKey];
}


- (IBAction)forkRemoteRepositoryAction:(id)sender {
    
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to fork %@?", self.remoteRepositoryTextfield.stringValue]
                                     defaultButton:@"Fork"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"This will remove all snippets from the current git repository and replace them with snippets from the new fork."];
    
    __weak typeof(self)weakSelf = self;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
                
            case NSModalResponseCancel: {
                // nothing
                break;
            }
                
            case NSModalResponseOK: {
                
                __block ACCodeSnippetGitDataStore *dataStore = weakSelf.gitDataStore;
                
                [weakSelf.window beginSheet:weakSelf.progressPanel completionHandler:nil];
                [weakSelf.progressIndicator startAnimation:weakSelf];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    
                    NSLog(@"----- backup");
                    [weakSelf backupUserSnippets];
                    
                    NSLog(@"----- remove");
                    [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] removeDataStore:dataStore];
                    [dataStore removeAllCodeSnippets];
                    [dataStore.gitRepository removeLocalRepository];

                    NSLog(@"----- add");
                    ACCodeSnippetGitDataStore *dataStore = [[ACCodeSnippetGitDataStore alloc] initWithRemoteRepositoryURL:[NSURL URLWithString:weakSelf.remoteRepositoryTextfield.stringValue]];
                    [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:dataStore];
                    [dataStore importAllCodeSnippets];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.window endSheet:weakSelf.progressPanel];
                        [weakSelf.progressIndicator stopAnimation:weakSelf];
                    });
                    
                    [weakSelf importUserSnippetsAction:weakSelf];
                });

                break;
            }
                
            default:
                break;
        }
    }];
}

- (IBAction)openUserSnippetsDirectoryAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[self pathForSnippetDirectory]];
}

- (IBAction)backupUserSnippetsAction:(id)sender {
    NSLog(@"backupUserSnippetsAction");
    [self backupUserSnippets];
}

- (void)backupUserSnippets {
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

- (IBAction)importUserSnippetsAction:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Do you want to import your existing user code snippets in the repository?"
                                     defaultButton:@"Import"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"This will import all your user code snippets in the current git repository. System code snippets will not be imported."];
    
    __weak typeof(self)weakSelf = self;

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
                
            case NSModalResponseCancel: {
                // nothing
                break;
            }
                
            case NSModalResponseOK: {
                
                __block ACCodeSnippetGitDataStore *dataStore = weakSelf.gitDataStore;
                
                [weakSelf.window beginSheet:weakSelf.progressPanel completionHandler:nil];
                [weakSelf.progressIndicator startAnimation:weakSelf];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    
                    [dataStore exportAllCodeSnippets];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.window endSheet:weakSelf.progressPanel];
                        [weakSelf.progressIndicator stopAnimation:weakSelf];
                    });
                });
                
                break;
            }
                
            default:
                break;
        }
    }];
}

- (IBAction)removeSystemSnippets:(id)sender {
    NSError *error;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.systemSnippetsBackupPath isDirectory:nil] ||
        [[NSFileManager defaultManager] moveItemAtPath:self.systemSnippetsPath
                                                toPath:self.systemSnippetsBackupPath
                                                 error:&error]
        ) {
        
        // we need an empty file or Xcode will complain and crash at startup
        [[NSFileManager defaultManager] createFileAtPath:self.systemSnippetsPath
                                                contents:nil
                                              attributes:0];
        
        [[NSAlert alertWithMessageText:@"Restart Xcode for changes to take effect."
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@""] beginSheetModalForWindow:self.window completionHandler:nil];
    } else {
        [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:nil];
    }
}

- (IBAction)restoreSystemSnippets:(id)sender {
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.systemSnippetsBackupPath isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.systemSnippetsPath error:&error];
        
        if ([[NSFileManager defaultManager] copyItemAtPath:self.systemSnippetsBackupPath
                                                    toPath:self.systemSnippetsPath
                                                     error:&error]) {
            [[NSAlert alertWithMessageText:@"Restart Xcode for changes to take effect."
                             defaultButton:@"OK"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@""] beginSheetModalForWindow:self.window completionHandler:nil];
        } else {
            [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:nil];
        }
    }
}

- (IBAction)openSystemSnippetsDirectoryAction:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:[self systemSnippetsPath] inFileViewerRootedAtPath:nil];
}

- (NSString*)systemSnippetsPath {
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"IDECodeSnippetRepository")];
    return [bundle pathForResource:@"SystemCodeSnippets" ofType:@"codesnippets"];
}

- (NSString*)systemSnippetsBackupPath {
    return [self.systemSnippetsPath stringByAppendingPathExtension:@"backup"];
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

@end
