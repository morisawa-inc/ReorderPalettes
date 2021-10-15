//
//  ReorderPalettesPlugin.m
//  ReorderPalettes
//
//  Created by tfuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import "ReorderPalettesPlugin.h"
#import "ROPWindowController.h"
#import "ROPPalettePlugin.h"
#import "ROPPalettePluginManager.h"
#import <GlyphsCore/GlyphsPaletteProtocol.h>
#import <objc/runtime.h>

static NSString * ReorderPalettesPluginBundleIdentifier = nil;

typedef NSUInteger (*GlyphsPaletteSortIDFunction)(id<GlyphsPalette>, SEL);
static NSDictionary<NSString *, NSValue *> *ReorderPalettesPluginOriginalSortIDFunctionDictionary = nil;

static NSUInteger ReorderPalettesPluginGlyphsPaletteSortID(id<GlyphsPalette>self, SEL _cmd) {
    if (ReorderPalettesPluginBundleIdentifier) {
        if ([[ROPPalettePluginManager sharedManager] isEnabled]) {
            NSDictionary<NSString *, NSNumber *> *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:ReorderPalettesPluginBundleIdentifier];
            if (dictionary) {
                NSString *bundleIdentifier = [[NSBundle bundleForClass:[(NSObject *)self class]] bundleIdentifier];
                NSNumber *number = [dictionary objectForKey:bundleIdentifier];
                if (number) return [number unsignedIntegerValue];
            }
        }
    }
    GlyphsPaletteSortIDFunction originalGlyphsPaletteSortID = NULL;
    if (ReorderPalettesPluginOriginalSortIDFunctionDictionary) {
        originalGlyphsPaletteSortID = [[ReorderPalettesPluginOriginalSortIDFunctionDictionary objectForKey:NSStringFromClass([(NSObject *)self class])] pointerValue];
    }
    return originalGlyphsPaletteSortID ? originalGlyphsPaletteSortID(self, _cmd) : 0;
}

#pragma mark -

static inline void ReorderPalettesPluginSwizzleMethods(Class cls, SEL selector, IMP alternative, IMP *original) {
    if (cls && selector && alternative && original) {
        Method originalMethod = class_getInstanceMethod(cls, selector);
        *original = (void *)method_getImplementation(originalMethod);
        if (!class_addMethod(cls, selector, alternative, method_getTypeEncoding(originalMethod))) {
            method_setImplementation(originalMethod, alternative);
        }
    }
}

#pragma mark -

@interface ReorderPalettesPlugin () <ROPWindowControllerDelegate>
@property (nonatomic, readonly) NSMenuItem *menuItem;
@property (nonatomic, readonly) ROPWindowController *windowController;
@end

@implementation ReorderPalettesPlugin

- (instancetype)init {
    if ((self = [super init])) {
        ReorderPalettesPluginBundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    }
    return self;
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSMenuItem *)showRegistrationWindowMenuItem {
    for (NSMenuItem *menuItem in [[NSApp mainMenu] itemArray]) {
        for (NSMenuItem *submenuItem in [[menuItem submenu] itemArray]) {
            if ([submenuItem action] == NSSelectorFromString(@"showRegistrationWindow:")) {
                return submenuItem;
            }
        }
    }
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"Reorder Palettes...", nil);
}

- (void)loadPlugin {
    NSMenuItem *showRegistrationWindowMenuItem = [self showRegistrationWindowMenuItem];
    if (showRegistrationWindowMenuItem) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self title] action:@selector(handleMenuItemAction:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [[showRegistrationWindowMenuItem menu] insertItem:menuItem atIndex:[[showRegistrationWindowMenuItem menu] indexOfItem:showRegistrationWindowMenuItem] + 1];
        [[showRegistrationWindowMenuItem menu] insertItem:[NSMenuItem separatorItem] atIndex:[[showRegistrationWindowMenuItem menu] indexOfItem:showRegistrationWindowMenuItem] + 1];
        _menuItem = menuItem;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSMutableDictionary<Class, NSValue *> *mutableOriginalSortIDFunctionDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (NSBundle *bundle in [ROPPalettePlugin availablePaletteBundles]) {
        [bundle load];
        GlyphsPaletteSortIDFunction originalGlyphsPaletteSortID = NULL;
        ReorderPalettesPluginSwizzleMethods([bundle principalClass], @selector(sortID), (IMP)ReorderPalettesPluginGlyphsPaletteSortID, (IMP *)&originalGlyphsPaletteSortID);
        if (originalGlyphsPaletteSortID) {
            [mutableOriginalSortIDFunctionDictionary setObject:[NSValue valueWithPointer:originalGlyphsPaletteSortID] forKey:NSStringFromClass([bundle principalClass])];
        }
    }
    ReorderPalettesPluginOriginalSortIDFunctionDictionary = [mutableOriginalSortIDFunctionDictionary copy];
#pragma clang diagnostic pop
}

- (void)handleMenuItemAction:(id)sender {
    ROPWindowController *windowController = [[ROPWindowController alloc] init];
    [windowController setDelegate:self];
    [windowController showWindow:nil];
    [[windowController window] center];
    [windowController runModal];
    _windowController = windowController;
}

#pragma mark -

- (void)windowController:(ROPWindowController *)windowController didReorderPalettePluginsWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary {
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:ReorderPalettesPluginBundleIdentifier];
}

- (void)windowController:(ROPWindowController *)windowController willCloseWindow:(NSWindow *)window {
    _windowController = nil;
}

@end
