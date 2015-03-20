//
//  XCIDEHelper.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCIDEHelper.h"

#import "IDEWorkspace.h"
#import "DVTFilePath.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCIDEHelper

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (id)currentEditor
{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (IDEWorkspaceDocument *)currentWorkspaceDocument
{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (IDESourceCodeDocument *)currentSourceCodeDocument
{
    if ([[XCIDEHelper currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCIDEHelper currentEditor];
        return editor.sourceCodeDocument;
    }
    
    if ([[XCIDEHelper currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCIDEHelper currentEditor];
        if ([[editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *document = (IDESourceCodeDocument *)editor.primaryDocument;
            return document;
        }
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (IDEEditorDocument *)currentDocument
{
    return [[XCIDEHelper currentEditor] document];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (NSTextView *)currentSourceCodeTextView
{
    if ([[XCIDEHelper currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCIDEHelper currentEditor];
        return editor.textView;
    }
    
    if ([[XCIDEHelper currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCIDEHelper currentEditor];
        return editor.keyTextView;
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)selectedObjCFileNavigableItems
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    id currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = currentWindowController;
        IDEWorkspaceTabController *workspaceTabController = [workspaceController activeWorkspaceTabController];
        IDENavigatorArea *navigatorArea = [workspaceTabController navigatorArea];
        id currentNavigator = [navigatorArea currentNavigator];
        
        if ([currentNavigator isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
            IDEStructureNavigator *structureNavigator = currentNavigator;
            for (id selectedObject in structureNavigator.selectedObjects) {
                if ([selectedObject isKindOfClass:NSClassFromString(@"IDEFileNavigableItem")]) {
                    IDEFileNavigableItem *fileNavigableItem = selectedObject;
                    NSString *uti = fileNavigableItem.documentType.identifier;
                    if ([uti isEqualToString:(NSString *)kUTTypeObjectiveCSource] || [uti isEqualToString:(NSString *)kUTTypeCHeader]) {
                        [mutableArray addObject:fileNavigableItem];
                    }
                }
            }
        }
    }
    
    if (mutableArray.count) {
        return [NSArray arrayWithArray:mutableArray];
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)containerFolderURLsForNavigableItem:(IDENavigableItem *)navigableItem
{
    NSMutableArray *mArray = [NSMutableArray array];
    
    do {
        NSURL *folderURL = nil;
        id representedObject = navigableItem.representedObject;
        if ([navigableItem isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
            // IDE-GROUP (a folder in the navigator)
            IDEGroup *group = (IDEGroup *)representedObject;
            folderURL = group.resolvedFilePath.fileURL;
        } else if ([navigableItem isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")]) {
            // CONTAINER (an Xcode project)
            IDEFileReference *fileReference = representedObject;
            folderURL = [fileReference.resolvedFilePath.fileURL URLByDeletingLastPathComponent];
        } else if ([navigableItem isKindOfClass:NSClassFromString(@"IDEKeyDrivenNavigableItem")]) {
            // WORKSPACE (root: Xcode project or workspace)
            IDEWorkspace *workspace = representedObject;
            folderURL = [workspace.representingFilePath.fileURL URLByDeletingLastPathComponent];
        }
        if (folderURL && ![mArray containsObject:folderURL]) [mArray addObject:folderURL];
        navigableItem = [navigableItem parentItem];
    } while (navigableItem != nil);
    
    if (mArray.count > 0) return [NSArray arrayWithArray:mArray];
    return nil;
}

@end
