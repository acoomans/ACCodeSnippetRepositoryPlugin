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
@property (nonatomic, strong) ACCodeSnippetRepositoryConfigurationWindowController *configurationWindowController;
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
        ACCodeSnippetGitDataStore *gitDataStore = [[ACCodeSnippetGitDataStore alloc] init];
        [gitDataStore addObserver:self forKeyPath:@"mainQueue.operationCount" options:0 context:NULL];
        
        //TODO: add multiple datastores
        IDECodeSnippetRepository *codeSnippetRepository = [NSClassFromString(@"IDECodeSnippetRepository") sharedRepository];
        [codeSnippetRepository addDataStore:gitDataStore];
        [codeSnippetRepository addObserver:self forKeyPath:@"dataStores" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        
        // Create menu items, initialize UI, etc.
        NSMenu *pluginMenu = [self pluginMenu];
        pluginMenu.autoenablesItems = NO;
        
        if (pluginMenu) {
            
            NSMenuItem *actionMenuItem = nil;
            
            self.updateMenuItem = actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Update snippets" action:@selector(updateAction:) keyEquivalent:@""];
            actionMenuItem.target = self;
            [pluginMenu addItem:actionMenuItem];
            
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Configure snippets repository" action:@selector(configureAction:) keyEquivalent:@""];
            actionMenuItem.target = self;
            [pluginMenu addItem:actionMenuItem];
            
            //[pluginMenu addItem:[NSMenuItem separatorItem]];
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

- (void)updateAction:(id)sender {
    for (id<ACCodeSnippetDataStoreProtocol> dataStore in [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] dataStores]) {
        [dataStore updateCodeSnippets];
    }
}


- (void)configureAction:(id)sender {
    self.configurationWindowController = [[ACCodeSnippetRepositoryConfigurationWindowController alloc] initWithWindowNibName:NSStringFromClass(ACCodeSnippetRepositoryConfigurationWindowController.class)];
    self.configurationWindowController.delegate = self;
    self.configurationWindowController.window.delegate = self;
    [self.configurationWindowController.window makeKeyWindow];
}


#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    
    if (notification.object == self.configurationWindowController.window) {
        self.configurationWindowController = nil;
    }
    
    /*
    if (notification.object == self.logWindowController.window) {
        self.logWindowController = nil;
    }*/
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"mainQueue.operationCount"]) {
        
        IDECodeSnippetRepository *codeSnippetRepository = [NSClassFromString(@"IDECodeSnippetRepository") sharedRepository];
        
        if ([[object valueForKeyPath:keyPath] integerValue] > 0) {
            self.updateMenuItem.title = @"Updating snippets...";
            self.updateMenuItem.enabled = NO;
            
        } else if ([[codeSnippetRepository.dataStores valueForKeyPath:@"@sum.mainQueue.operationCount"] integerValue] == 0) {
            self.updateMenuItem.title = @"Update snippets";
            self.updateMenuItem.enabled = YES;
        }
        
    } else if ([keyPath isEqualToString:@"dataStores"]) {
        
        for (id dataStore in change[NSKeyValueChangeOldKey]) {
            [dataStore removeObserver:self forKeyPath:@"mainQueue.operationCount"];
        }
        
        for (id dataStore in change[NSKeyValueChangeNewKey]) {
            [dataStore addObserver:self forKeyPath:@"mainQueue.operationCount" options:0 context:NULL];
        }
    }
}

#pragma mark - ACCodeSnippetRepositoryConfigurationWindowControllerDelegate

- (NSArray*)dataStoresForCodeSnippetConfigurationWindowController:(ACCodeSnippetRepositoryConfigurationWindowController*)configurationWindowController {
    return [[NSClassFromString(@"IDECodeSnippetRepository") sharedRepository] dataStores];
}

@end
