//
//  ROPPalettePluginManager.h
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 15/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROPPalettePluginManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readwrite, getter=isEnabled) BOOL enabled;

@end
