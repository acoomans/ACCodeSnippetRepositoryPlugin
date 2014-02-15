//
//  ACCodeSnippetRepositoryConfigurationWindowController.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 06/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ACCodeSnippetRepositoryConfigurationWindowController;

@protocol ACCodeSnippetRepositoryConfigurationWindowControllerDelegate <NSObject>
- (NSArray*)dataStoresForCodeSnippetConfigurationWindowController:(ACCodeSnippetRepositoryConfigurationWindowController*)configurationWindowController;
@end


@interface ACCodeSnippetRepositoryConfigurationWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, weak) id<ACCodeSnippetRepositoryConfigurationWindowControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet NSTextField *remoteRepositoryTextfield;
@property (nonatomic, weak) IBOutlet NSButton *forkRemoteRepositoryButton;

- (IBAction)openSnippetDirectoryAction:(id)sender;
- (IBAction)forkRemoteRepositoryAction:(id)sender;

@end
