//
//  ROPWindowController.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import "ROPWindowController.h"
#import "ROPPalettePlugin.h"
#import "ROPTableColumn.h"

static inline void MoveObjectInArray(NSMutableArray *mutableArray, NSUInteger atIndex, NSUInteger toIndex) {
    id object = [mutableArray objectAtIndex:atIndex];
    [mutableArray removeObjectAtIndex:atIndex];
    [mutableArray insertObject:object atIndex:toIndex];
}

@interface ROPWindowController () <NSTableViewDataSource> {
@private
    BOOL _isRunningModal;
}
@property (nonatomic, readwrite) NSMutableArray<ROPPalettePlugin *> *mutablePalettePlugins;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSArrayController *arrayController;
@end

@implementation ROPWindowController

- (instancetype)init {
    if ((self = [self initWithWindowNibName:NSStringFromClass([self class]) owner:self])) {
        _mutablePalettePlugins = [[NSMutableArray alloc] initWithCapacity:0];
        [_mutablePalettePlugins addObjectsFromArray:[ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsNone]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_tableView registerForDraggedTypes:@[@"public.text"]];
    [_tableView setDataSource:self];
}

- (IBAction)handleReset:(id)sender {
    [self willChangeValueForKey:@"mutablePalettePlugins"];
    [_mutablePalettePlugins setArray:[ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsPreferOriginalSortID]];
    [self didChangeValueForKey:@"mutablePalettePlugins"];
}

- (IBAction)handleClose:(id)sender {
    [self close];
}

- (void)runModal {
    if (!_isRunningModal) {
        _isRunningModal = YES;
        [[NSApplication sharedApplication] runModalForWindow:[self window]];
    }
}

- (void)stopModalIfNeeded {
    if (_isRunningModal) {
        [[NSApplication sharedApplication] stopModal];
        _isRunningModal = NO;
    }
}

#pragma mark -

- (BOOL)hasModifiedFromDefaultOrder {
    NSArray<ROPPalettePlugin *> *originallyAvailablePalettePlugins = [ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsPreferOriginalSortID];
    return ![_mutablePalettePlugins isEqualToArray:originallyAvailablePalettePlugins];
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)notification {
    [self stopModalIfNeeded];
    if ([[self delegate] respondsToSelector:@selector(windowController:didReorderPalettePluginsWithDictionary:)]) {
        if ([self hasModifiedFromDefaultOrder]) {
            [[self delegate] windowController:self didReorderPalettePluginsWithDictionary:[ROPPalettePlugin dictionaryFromPalettePlugins:_mutablePalettePlugins]];
        } else {
            [[self delegate] windowController:self didReorderPalettePluginsWithDictionary:nil];
        }
    }
    if ([[self delegate] respondsToSelector:@selector(windowController:willCloseWindow:)]) {
        [[self delegate] windowController:self willCloseWindow:[self window]];
    }
}


#pragma mark - Column Autoresizing

- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column {
    return [(ROPTableColumn *)[[tableView tableColumns] objectAtIndex:column] fittingSize].width;
}

#pragma mark - Drag and Drop Row Reordering

- (nullable id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setString:[NSString stringWithFormat:@"%ld", row] forType:@"public.text"];
    return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    return (dropOperation == NSTableViewDropAbove) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSMutableIndexSet *mutableOriginalRowIndexes = [[NSMutableIndexSet alloc] init];
    [info enumerateDraggingItemsWithOptions:0 forView:tableView classes:@[[NSPasteboardItem class]] searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
        NSPasteboardItem *item = [draggingItem item];
        NSString *stringValue = [item stringForType:@"public.text"];
        if (stringValue) {
            [mutableOriginalRowIndexes addIndex:[stringValue integerValue]];
        }
    }];
    [tableView beginUpdates];
    __block NSInteger originalIndexOffset = 0;
    __block NSInteger currentIndexOffset  = 0;
    [mutableOriginalRowIndexes enumerateIndexesUsingBlock:^(NSUInteger originalRowIndex, BOOL *stop) {
        if (originalRowIndex < row) {
            [tableView moveRowAtIndex:originalRowIndex + originalIndexOffset toIndex:row - 1];
            MoveObjectInArray([_arrayController content], originalRowIndex + originalIndexOffset, row - 1);
            --originalIndexOffset;
        } else {
            [tableView moveRowAtIndex:originalRowIndex toIndex:row + currentIndexOffset];
            MoveObjectInArray([_arrayController content], originalRowIndex, row + currentIndexOffset);
            ++currentIndexOffset;
        }
    }];
    [tableView endUpdates];
    return YES;
}

@end
