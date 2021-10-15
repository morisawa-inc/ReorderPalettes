//
//  ROPPalettePluginManager.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 15/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import "ROPPalettePluginManager.h"

@implementation ROPPalettePluginManager

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static ROPPalettePluginManager *sharedInstance = nil;
    dispatch_once(&once, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _enabled = YES;
    }
    return self;
}

@end
