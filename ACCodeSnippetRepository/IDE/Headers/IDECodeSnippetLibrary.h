// class-dump

@class DVTObservingToken;

@interface IDECodeSnippetLibrary : NSObject //DVTLibraryController
{
    DVTObservingToken *_kvoSnippetRepositoryToken;
    NSMapTable *_strongSnippetToAssetMap;
    NSArray *_orderedPlatformFamilies;
    BOOL _isAddingUserCodeSnippet;
    NSSet *_lastSnippets;
}

//- (void).cxx_destruct;
- (id)codeDetailController:(id)arg1 contentsForAsset:(id)arg2 representedObject:(id)arg3;
- (id)codeDetailController:(id)arg1 languageForAsset:(id)arg2 representedObject:(id)arg3;
- (id)editorViewControllerForAsset:(id)arg1;
- (BOOL)canRemoveAsset:(id)arg1;
- (BOOL)canEditAsset:(id)arg1;
- (BOOL)removeAssets:(id)arg1 error:(id *)arg2;
- (BOOL)createAsset:(id *)arg1 forLibrarySourceWithIdentifier:(id *)arg2 fromPasteboard:(id)arg3;
- (BOOL)canCreateAssetsFromPasteboard:(id)arg1 targetingLibrarySourceIdentifier:(id *)arg2;
- (id)readableAssetPasteboardTypes;
- (void)dealloc;
- (void)finalize;
- (void)viewWillUninstall;
- (void)primitiveInvalidate;
- (void)libraryDidLoad;
- (struct CGSize)detailAreaSize;
- (void)populatePasteboard:(id)arg1 withAssets:(id)arg2;
- (void)addUserSnippet:(id)arg1 withAsset:(id)arg2;
- (void)codeSnippetsDidUpdate;
- (void)removeAssetForCodeSnippet:(id)arg1;
- (void)addAssetForCodeSnippet:(id)arg1;
- (void)addAsset:(id)arg1 toLibrarySourceIdentifierForPlatformFamily:(id)arg2;
- (void)addLibraryGroupsIfNeeded;
- (void)setLibraryAsset:(id)arg1 forCodeSnippet:(id)arg2;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)stopObservingSnippet:(id)arg1;
- (void)startObservingSnippet:(id)arg1;
- (id)observingKeyPathsForCodeSnippet:(id)arg1;
- (id)libraryAssetForCodeSnippet:(id)arg1;
- (id)createLibraryAssetForCodeSnippet:(id)arg1;
- (id)platformIconForPlatformFamily:(id)arg1;
- (id)defaultPlatformIcon;

@end
