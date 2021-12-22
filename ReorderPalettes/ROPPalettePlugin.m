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
@end

@implementation ROPPalettePlugin

+ (NSArray<NSBundle *> *)availablePaletteBundles {
    return [[(id<GSMenuProtocol>)[[NSApplication sharedApplication] delegate] paletteBundles] copy];
}

+ (NSArray<ROPPalettePlugin *> *)availablePalettePluginsWithOptions:(ROPPalettePluginEnumeratingOptions)options {
    NSMutableArray <ROPPalettePlugin *> *mutablePlugins = [[NSMutableArray alloc] initWithCapacity:0];
    id<GSMenuProtocol> delegate = (id<GSMenuProtocol>)[[NSApplication sharedApplication] delegate];
    NSMutableSet<NSString *> *mutableClassNames = [[NSMutableSet alloc] initWithCapacity:0];
    for (NSBundle *bundle in [delegate paletteBundles]) {
        Class principalClass = [bundle principalClass];
        if (principalClass) {
            NSString *className = NSStringFromClass(principalClass);
            if (className && ![mutableClassNames containsObject:className]) {
                NSObject<GlyphsPalette> *instance = [[principalClass alloc] init];
                if ([instance respondsToSelector:@selector(loadPlugin)]) [instance loadPlugin];
                [mutablePlugins addObject:[[[self class] alloc] initWithInstance:instance options:options bundles:[delegate paletteBundles]]];
                [mutableClassNames addObject:className];
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
        [mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:currentSortID] forKey:[plugin className]];
        currentSortID += 10;
    }
    return [mutableDictionary copy];
}

- (instancetype)initWithInstance:(id<GlyphsPalette>)instance options:(ROPPalettePluginEnumeratingOptions)options bundles:(NSArray<NSBundle *> *)bundles {
    BOOL enabled = [[ROPPalettePluginManager sharedManager] isEnabled];
    if (options & ROPPalettePluginEnumeratingOptionsPreferOriginalSortID) [[ROPPalettePluginManager sharedManager] setEnabled:NO];
    NSString *title = [(NSObject *)instance respondsToSelector:@selector(title)] ? [instance title] : @"";
    NSUInteger sortID = [(NSObject *)instance respondsToSelector:@selector(sortID)] ? [instance sortID] : 0;
    [[ROPPalettePluginManager sharedManager] setEnabled:enabled];
    if ((self = [self initWithTitle:title identifier:[GetCorrespondingBundleForInstance(instance, bundles) bundleIdentifier] className:NSStringFromClass([(NSObject *)instance class]) sortID:sortID])) {
        
    }
    return self;
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
