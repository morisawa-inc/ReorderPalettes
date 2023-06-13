//
//  ROPPalettePlugin.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import "ROPPalettePlugin.h"
#import "ROPPalettePluginManager.h"
#import <GlyphsCore/GlyphsPaletteProtocol.h>

static NSBundle * GetCorrespondingBundleForInstance(id instance, NSArray<NSBundle *> *bundles) {
    for (NSBundle *bundle in bundles) {
        if ([instance isMemberOfClass:[bundle principalClass]]) return bundle;
    }
    return nil;
}

@protocol GSMenuProtocol <NSObject>
- (NSMutableArray<NSBundle *> *)paletteBundles;
- (NSMutableArray<Class> *)paletteClasses;
- (NSMutableDictionary<NSString *, NSBundle *> *)pluginBundles;
@end

@implementation ROPPalettePlugin

+ (NSArray<NSBundle *> *)availablePaletteBundles {
    id<GSMenuProtocol> menu = (id<GSMenuProtocol>)[[NSApplication sharedApplication] delegate];
    if ([menu respondsToSelector:@selector(paletteClasses)]) {
        NSMutableArray<NSBundle *> *mutableBundles = [[NSMutableArray alloc] initWithCapacity:0];
        NSSet<Class> *paletteClasses = [NSSet setWithArray:[menu paletteClasses]];
        for (NSBundle *bundle in [[menu pluginBundles] allValues]) {
            if ([paletteClasses containsObject:[bundle principalClass]]) {
                [mutableBundles addObject:bundle];
            }
        }
        return [mutableBundles copy];
    }
    return [[menu paletteBundles] copy];
}

+ (NSArray<ROPPalettePlugin *> *)availablePalettePluginsWithOptions:(ROPPalettePluginEnumeratingOptions)options {
    NSMutableArray <ROPPalettePlugin *> *mutablePlugins = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableSet<NSString *> *mutableClassNames = [[NSMutableSet alloc] initWithCapacity:0];
    NSArray<NSBundle *> *availablePaletteBundles = [[self class] availablePaletteBundles];
    for (NSBundle *bundle in availablePaletteBundles) {
        Class principalClass = [bundle principalClass];
        if (principalClass) {
            NSString *className = NSStringFromClass(principalClass);
            if (className && ![mutableClassNames containsObject:className]) {
                @try {
                    NSObject<GlyphsPalette> *instance = [[principalClass alloc] init];
                    if ([instance respondsToSelector:@selector(loadPlugin)]) [instance loadPlugin];
                    ROPPalettePlugin *plugin = [[[self class] alloc] initWithInstance:instance options:options bundles:availablePaletteBundles];
                    if (plugin) {
                        [mutablePlugins addObject:plugin];
                        [mutableClassNames addObject:className];
                    }
                } @catch (NSException *exception) {
                    NSLog(@"%@", [exception description]);
                }
            }
        }
    }
    [mutablePlugins sortUsingSelector:@selector(compare:)];
    return [mutablePlugins copy];
}

+ (NSDictionary<NSString *, NSNumber *> *)dictionaryFromPalettePlugins:(NSArray<ROPPalettePlugin *> *)plugins {
    NSMutableDictionary <NSString *, NSNumber *> *mutableDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSUInteger currentSortID = 0;
    for (ROPPalettePlugin *plugin in plugins) {
        if ([plugin className]) {
            [mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:currentSortID] forKey:[plugin className]];
            currentSortID += 10;
        }
    }
    return [mutableDictionary copy];
}

- (instancetype)initWithInstance:(id<GlyphsPalette>)instance options:(ROPPalettePluginEnumeratingOptions)options bundles:(NSArray<NSBundle *> *)bundles {
    Class class = [(NSObject *)instance class];
    if (class) {
        NSString *className = NSStringFromClass([(NSObject *)instance class]);
        NSString *identifier = [GetCorrespondingBundleForInstance(instance, bundles) bundleIdentifier];
        if (className && identifier) {
            BOOL enabled = [[ROPPalettePluginManager sharedManager] isEnabled];
            if (options & ROPPalettePluginEnumeratingOptionsPreferOriginalSortID) [[ROPPalettePluginManager sharedManager] setEnabled:NO];
            NSString *title = [(NSObject *)instance respondsToSelector:@selector(title)] ? [instance title] : @"";
            NSUInteger sortID = [(NSObject *)instance respondsToSelector:@selector(sortID)] ? [instance sortID] : 0;
            [[ROPPalettePluginManager sharedManager] setEnabled:enabled];
            if ((self = [self initWithTitle:title identifier:identifier className:className sortID:sortID])) {
                
            }
            return self;
        }
    }
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier className:(NSString *)className sortID:(NSUInteger)sortID {
    if ((self = [self init])) {
        _title = title;
        _identifier = identifier;
        _className = className;
        _sortID = sortID;
    }
    return self;
}

- (NSComparisonResult)compare:(ROPPalettePlugin *)object {
    if ([self sortID] < [object sortID]) return NSOrderedAscending;
    if ([self sortID] > [object sortID]) return NSOrderedDescending;
    return [[self title] compare:[object title]];
}

- (NSUInteger)hash {
    return [_className hash];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        if ([[object className] isEqualToString:[self className]]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@"<%@, %@, %lu>", [self title], [self identifier], [self sortID]];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end
