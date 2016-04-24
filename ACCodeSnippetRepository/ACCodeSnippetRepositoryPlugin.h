//
//  ACCodeSnippetRepositoryPlugin.h
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 12/02/14.
//  Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ACCodeSnippetRepositoryConfigurationWindowController.h"

@interface ACCodeSnippetRepositoryPlugin : NSObject <NSWindowDelegate, ACCodeSnippetRepositoryConfigurationWindowControllerDelegate>

@property (nonatomic, strong) NSTimer *updatesTimer;

@end