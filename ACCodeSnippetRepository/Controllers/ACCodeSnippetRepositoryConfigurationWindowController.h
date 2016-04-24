//
//  ACCodeSnippetRepositoryConfigurationWindowController.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 06/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const ACCodeSnippetRepositoryUpdateRegularlyKey;


@class ACCodeSnippetRepositoryConfigurationWindowController;

@protocol ACCodeSnippetRepositoryConfigurationWindowControllerDelegate <NSObject>
- (NSArray*)dataStoresForCodeSnippetConfigurationWindowController:(ACCodeSnippetRepositoryConfigurationWindowController*)configurationWindowController;
@end


@interface ACCodeSnippetRepositoryConfigurationWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, weak) id<ACCodeSnippetRepositoryConfigurationWindowControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet NSTextField *remoteRepositoryTextfield;
@property (nonatomic, weak) IBOutlet NSButton *forkRemoteRepositoryButton;
@property (nonatomic, weak) IBOutlet NSButton *importButton;

@property (nonatomic, weak) IBOutlet NSPanel *progressPanel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, weak) IBOutlet NSButton *updateRegularlyCheckbox;

@end
