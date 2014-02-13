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
@property (nonatomic, weak) NSMenuItem *updateMenuItem;
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
        [gitDataStore addObserver:self forKeyPath:@"mainQueue.operationCount" options:0 context:NULL];
        
        [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] addDataStore:gitDataStore];
        
        // Create menu items, initialize UI, etc.
        NSMenu *pluginMenu = [self pluginMenu];
        pluginMenu.autoenablesItems = NO;
        
        if (pluginMenu) {
            
            NSMenuItem *actionMenuItem = nil;
            
            self.updateMenuItem = actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Update snippets" action:@selector(updateAction:) keyEquivalent:@""];
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
- (void)updateAction:(id)sender {
    
    for (id<ACCodeSnippetDataStoreProtocol> dataStore in [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] dataStores]) {
        [dataStore updateCodeSnippets];
    }
}


#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"mainQueue.operationCount"]) {
        
        if ([[object valueForKeyPath:keyPath] integerValue] > 0) {
            self.updateMenuItem.title = @"Updating snippets...";
            self.updateMenuItem.enabled = NO;
        } else {
            self.updateMenuItem.title = @"Update snippets";
            self.updateMenuItem.enabled = YES;
        }
    }
}

@end
