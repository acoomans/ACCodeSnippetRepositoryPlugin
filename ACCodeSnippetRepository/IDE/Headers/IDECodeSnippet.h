// class-dump

@class DVTCustomDataSpecifier, DVTPlatformFamily, DVTSourceCodeLanguage;

@interface IDECodeSnippet : NSObject
{
    DVTCustomDataSpecifier *_customDataSpecifier;
    DVTPlatformFamily *_platformFamily;
    DVTSourceCodeLanguage *_language;
    NSString *_completionPrefix;
    long long _relativePriority;
    NSSet *_completionScopes;
    NSString *_identifier;
    NSString *_contents;
    NSString *_summary;
    long long _version;
    NSString *_title;
    BOOL _userSnippet;
}

+ (id)displayNameForCompletionScope:(id)arg1;
+ (id)completionScopesForLanguage:(id)arg1;
+ (id)keyPathsForValuesAffectingSystemSnippet;
+ (id)userEditableKeyPaths;
@property(retain) DVTCustomDataSpecifier *customDataSpecifier; // @synthesize customDataSpecifier=_customDataSpecifier;
@property long long version; // @synthesize version=_version;
@property(readonly) NSString *identifier; // @synthesize identifier=_identifier;
@property(getter=isUserSnippet) BOOL userSnippet; // @synthesize userSnippet=_userSnippet;
@property(copy) NSSet *completionScopes; // @synthesize completionScopes=_completionScopes;
@property long long relativePriority; // @synthesize relativePriority=_relativePriority;
@property(copy) NSString *completionPrefix; // @synthesize completionPrefix=_completionPrefix;
@property(copy) NSString *summary; // @synthesize summary=_summary;
@property(copy) NSString *title; // @synthesize title=_title;
@property(copy) NSString *contents; // @synthesize contents=_contents;
@property(retain) DVTPlatformFamily *platformFamily; // @synthesize platformFamily=_platformFamily;
@property(retain) DVTSourceCodeLanguage *language; // @synthesize language=_language;
//- (void).cxx_destruct;
- (id)dictionaryRepresentation;
- (id)description;
@property(readonly, getter=isSystemSnippet) BOOL systemSnippet;
@property(readonly) NSImage *image;
- (id)initWithDictionaryRepresentation:(id)arg1;
- (id)initWithContents:(id)arg1 language:(id)arg2 platformFamily:(id)arg3 userSnippet:(BOOL)arg4;

@end
