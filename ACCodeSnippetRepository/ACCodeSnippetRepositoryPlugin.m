//
//  ACCodeSnippetRepositoryPlugin.m
//  ACCodeSnippetRepository
//
//  Created by Arnaud Coomans on 12/02/14.
//    Copyright (c) 2014 Arnaud Coomans. All rights reserved.
//

#import "ACCodeSnippetRepositoryPlugin.h"

#import "IDE.h"
#import "IDECodeSnippetRepositorySwizzler.h"
#import "ACCodeSnippetGitDataStore.h"


static ACCodeSnippetRepositoryPlugin *sharedPlugin;
static NSString * const pluginMenuTitle = @"Plug-ins";

@interface ACCodeSnippetRepositoryPlugin()
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation ACCodeSnippetRepositoryPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        
        // add data stores to Xcode's snippet repository
        ACGitRepository *gitRepository = [[ACGitRepository alloc] init];
        ACCodeSnippetGitDataStore *gitDataStore = [[ACCodeSnippetGitDataStore alloc] initWithGitRepository:gitRepository];
        
        [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:gitDataStore];
        
        // Create menu items, initialize UI, etc.
        NSMenu *pluginMenu = [self pluginMenu];
        
        if (pluginMenu) {
            NSMenuItem *actionMenuItem = nil;
            
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Do action" action:@selector(doAction) keyEquivalent:@""];
            actionMenuItem.target = self;
            [pluginMenu addItem:actionMenuItem];
            
            [pluginMenu addItem:[NSMenuItem separatorItem]];
        }
        
    }
    return self;
}

- (id)init {
    return [self initWithBundle:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Menu and actions

- (NSMenu*)pluginMenu {
    NSMenu *pluginMenu = [[[NSApp mainMenu] itemWithTitle:pluginMenuTitle] submenu];
    if (!pluginMenu) {
        pluginMenu = [[NSMenu alloc] initWithTitle:pluginMenuTitle];
        
        NSMenuItem *pluginMenuItem = [[NSMenuItem alloc] initWithTitle:pluginMenuTitle action:nil keyEquivalent:@""];
        pluginMenuItem.submenu = pluginMenu;
        
        [[NSApp mainMenu] addItem:pluginMenuItem];
    }
    return pluginMenu;
}

// Sample Action, for menu item:
- (void)doAction {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Hello, World" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
    
    for (id<ACCodeSnippetDataStoreProtocol> dataStore in [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] dataStores]) {
        [dataStore updateCodeSnippets];
    }
    
}

@end
