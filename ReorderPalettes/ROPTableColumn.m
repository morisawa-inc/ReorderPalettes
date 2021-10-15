//
//  ROPTableColumn.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 15/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

#import "ROPTableColumn.h"

@implementation ROPTableColumn

- (NSSize)fittingSize {
    NSSize size = NSZeroSize;
    NSTableView *tableView = [self tableView];
    NSInteger column = [[tableView tableColumns] indexOfObject:self];
    for (NSUInteger row = 0; row < [tableView numberOfRows]; ++row) {
        NSTableCellView *cellView = [tableView viewAtColumn:column row:row makeIfNecessary:YES];
        NSView *contentView = [cellView textField];
        if (!contentView) contentView = [[cellView subviews] firstObject];
        NSSize cellFittingSize = [contentView intrinsicContentSize];
        size.width = MAX(size.width, MIN([self maxWidth], cellFittingSize.width + 4.0));
    }
    return size;
}

- (void)sizeToFit {
    [self setWidth:[self fittingSize].width];
}

@end
