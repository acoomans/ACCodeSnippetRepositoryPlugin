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


@interface ACCodeSnippetRepositoryConfigurationWindowController : NSWindowController <NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) id<ACCodeSnippetRepositoryConfigurationWindowControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet NSTableView *remoteRepositoriesTableView;

@property (nonatomic, weak) IBOutlet NSPanel *addRemoteRepositoryPanel;
@property (nonatomic, weak) IBOutlet NSTextField *remoteRepositoryTextfield;
@property (nonatomic, weak) IBOutlet NSButton *forkRemoteRepositoryButton;

@property (nonatomic, weak) IBOutlet NSPanel *addingRemoteRepositoryPanel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@end
