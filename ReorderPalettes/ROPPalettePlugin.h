//
//  ROPPalettePlugin.h
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsPaletteProtocol.h>

typedef NS_ENUM(NSUInteger, ROPPalettePluginEnumeratingOptions) {
    ROPPalettePluginEnumeratingOptionsNone = 0,
    ROPPalettePluginEnumeratingOptionsPreferOriginalSortID = 1 << 0
};

@interface ROPPalettePlugin : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *className;
@property (nonatomic, readonly) NSUInteger sortID;

+ (NSArray<NSBundle *> *)availablePaletteBundles;
+ (NSArray<ROPPalettePlugin *> *)availablePalettePluginsWithOptions:(ROPPalettePluginEnumeratingOptions)options;
+ (NSDictionary<NSString *, NSNumber *> *)dictionaryFromPalettePlugins:(NSArray<ROPPalettePlugin *> *)plugins;

- (instancetype)initWithInstance:(id<GlyphsPalette>)instance options:(ROPPalettePluginEnumeratingOptions)options;
- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier className:(NSString *)className sortID:(NSUInteger)sortID;

- (NSComparisonResult)compare:(ROPPalettePlugin *)object;

@end
