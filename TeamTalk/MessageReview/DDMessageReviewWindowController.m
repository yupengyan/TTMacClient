//
//  DDMessageReviewWindowController.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDMessageReviewWindowController.h"
#import "DDMessageReviewModule.h"
#import "DDMessageReviewContactsViewController.h"
#import "DDMessagesReviewContentViewController.h"
#import "DDDatabaseUtil.h"
#import "DDSessionModule.h"
#import "DDGroupModule.h"
#import "DDUserlistModule.h"
#import "GroupEntity.h"
#import "UserEntity.h"
#import "NSWindow+Addition.h"
@interface DDMessageReviewWindowController ()

- (void)p_ininialContacts;
- (id)p_searchUser:(NSString*)content;
- (void)p_searchContent:(NSString*)content;
@end

@implementation DDMessageReviewWindowController
{
    NSArray* allRecent;
    NSArray* _allObjects;
    BOOL _showSearchContent;
}


+ (instancetype)instance
{
    static DDMessageReviewWindowController* g_messageReviewWindowController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_messageReviewWindowController = [[DDMessageReviewWindowController alloc] initWithWindowNibName:@"DDMessageReviewWindow"];
    });
    return g_messageReviewWindowController;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{
    _showSearchContent = NO;
    [self.window addCloseButtonAtTopLeft];
    [_splitView setPosition:100 ofDividerAtIndex:0];

}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self p_ininialContacts];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (DDMessageReviewModule*)module
{
    if (_module)
    {
        _module = [[DDMessageReviewModule alloc] init];
    }
    return _module;
}

#pragma mark IBAction
- (IBAction)deleteSession:(id)sender
{
    id object = [_contactsViewController selectedContact];
    NSString* ID = nil;
    if ([object isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        ID = [(UserEntity*)object userId];
    }
    else if ([object isKindOfClass:NSClassFromString(@"GroupEntity")])
    {
        ID = [(GroupEntity*)object groupId];
    }
    if (!ID)
    {
        return;
    }
    [[DDDatabaseUtil instance] deleteMesagesForSession:ID completion:^(BOOL success) {
        if (success)
        {
            [self p_searchContent:_searchTextField.stringValue];
        }
    }];
}

- (IBAction)refreshMessageReview:(id)sender
{
    [self p_searchContent:_searchTextField.stringValue];
}

#pragma mark NSTextField Delegate
- (void)controlTextDidChange:(NSNotification *)obj
{
	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];
    
    if([textView.string length] == 0 && _showSearchContent)
    {
        [self p_ininialContacts];
    }
}

// -------------------------------------------------------------------------------
//	control:textView:commandSelector
//
//	Handle all commend selectors that we can handle here
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if ([NSStringFromSelector(commandSelector) isEqualToString:@"insertNewline:"])
    {
        NSString* stringValue = [textView string];
        if ([stringValue length] > 0)
        {
            //判断是不是搜索的是用户
            [self p_searchContent:stringValue];
        }
    }
	else
    {
        if ([textView respondsToSelector:commandSelector])
        {
            [textView performSelector:commandSelector withObject:nil afterDelay:0];
        }
    }
    return YES;
}

#pragma mark DDMessageReviewContactsViewController Delegate
- (void)contactsViewController:(DDMessageReviewContactsViewController*)viewController selectObject:(id)object
{
    NSString* sessionID = nil;
    if ([object isKindOfClass:NSClassFromString(@"GroupEntity")]) {
        sessionID = [(GroupEntity*)object groupId];
    }
    else if ([object isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        sessionID = [(UserEntity*)object userId];
    }
    [self.contentViewController updateSession:sessionID];
}

#pragma mark NSSplitView

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 185;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 185;
}

#pragma mark privateAPI
- (void)p_ininialContacts
{
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    __weak DDMessageReviewWindowController* weakSelf = self;
    [[DDDatabaseUtil instance] loadAllSessionCompletion:^(NSArray *sessions, NSError *error) {
        //TODO:不存在的sessionID先不可见
        NSMutableArray* objects = [NSMutableArray array];
        [sessions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj rangeOfString:@"group"].length > 0)
            {
                GroupEntity* group = [groupModule getGroupByGId:obj];
                if (group)
                {
                    [objects addObject:group];
                }
            }
            else
            {
                UserEntity* user = [userModule getUserById:obj];
                if (user)
                {
                    [objects addObject:user];
                }
            }
        }];
        _allObjects = objects;
        [weakSelf.contactsViewController updateContacts:objects];
    }];

}

- (id)p_searchUser:(NSString*)content
{
    __block id object = nil;
    [_allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:NSClassFromString(@"UserEntity")]) {
            NSString* name = [(UserEntity*)obj name];
            if ([name isEqualToString:content])
            {
                object = obj;
            }
        }
        else if ([obj isKindOfClass:NSClassFromString(@"GroupEntity")])
        {
            NSString* name = [(GroupEntity*)obj name];
            if ([name isEqualToString:content])
            {
                object = obj;
            }
        }
    }];
    return object;
}

- (void)p_searchContent:(NSString*)content
{
    if ([content length] > 0)
    {
        //判断是不是搜索的是用户
        if ([self p_searchUser:content])
        {
            _showSearchContent = YES;
            [_contactsViewController updateContacts:@[[self p_searchUser:content]]];
        }
        else
        {
            DDGroupModule* groupModule = [DDGroupModule shareInstance];
            DDUserlistModule* userModule = [DDUserlistModule shareInstance];
            [[DDDatabaseUtil instance] searchMessageContent:content completion:^(NSArray *result) {
                NSMutableArray* objects = [NSMutableArray array];
                [result enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    if ([obj rangeOfString:@"group"].length > 0)
                    {
                        GroupEntity* group = [groupModule getGroupByGId:obj];
                        if (group)
                        {
                            [objects addObject:group];
                        }
                    }
                    else
                    {
                        UserEntity* user = [userModule getUserById:obj];
                        if (user)
                        {
                            [objects addObject:user];
                        }
                    }
                }];
                _showSearchContent = YES;
                [_contactsViewController updateContacts:objects];
            }];
        }
    }
    else
    {
        [self p_ininialContacts];
    }
}
@end
