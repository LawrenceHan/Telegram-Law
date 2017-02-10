#import "TGInterfaceManager.h"

#import "TGAppDelegate.h"

#import "TGTelegraph.h"
#import "TGMessage.h"
#import "TGPeerIdAdapter.h"

#import "TGDatabase.h"

#import "TGNavigationBar.h"

#import "TGLinearProgressView.h"

#import "TGModernConversationController.h"
#import "TGGroupModernConversationCompanion.h"
#import "TGPrivateModernConversationCompanion.h"
#import "TGSecretModernConversationCompanion.h"
#import "TGBroadcastModernConversationCompanion.h"
#import "TGChannelConversationCompanion.h"

#import "TGTelegraphUserInfoController.h"
#import "TGSecretChatUserInfoController.h"
#import "TGPhonebookUserInfoController.h"
#import "TGBotUserInfoController.h"

#import "TGGenericPeerMediaListModel.h"
#import "TGModernMediaListController.h"

#import "TGOverlayControllerWindow.h"
#import "TGOverlayController.h"
#import "TGNotificationController.h"

#import "TGAlertView.h"

@interface TGInterfaceManager ()
{
    TGNotificationController *_notificationController;
}

@property (nonatomic, strong) UIWindow *preloadWindow;

@end

@implementation TGInterfaceManager

@synthesize actionHandle = _actionHandle;

@synthesize preloadWindow = _preloadWindow;

+ (TGInterfaceManager *)instance
{
    static TGInterfaceManager *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        singleton = [[TGInterfaceManager alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)preload
{
}

- (void)navigateToConversationWithId:(int64_t)conversationId conversation:(TGConversation *)conversation
{
    [self navigateToConversationWithId:conversationId conversation:conversation performActions:nil animated:true];
}

- (void)navigateToConversationWithId:(int64_t)conversationId conversation:(TGConversation *)conversation animated:(bool)animated
{
    [self navigateToConversationWithId:conversationId conversation:conversation performActions:nil animated:animated];
}

- (void)navigateToConversationWithId:(int64_t)conversationId conversation:(TGConversation *)conversation performActions:(NSDictionary *)performActions
{
    [self navigateToConversationWithId:conversationId conversation:conversation performActions:performActions animated:true];
}

- (void)navigateToConversationWithId:(int64_t)conversationId conversation:(TGConversation *)conversation performActions:(NSDictionary *)performActions animated:(bool)animated
{
    [self navigateToConversationWithId:conversationId conversation:conversation performActions:performActions atMessage:nil clearStack:true openKeyboard:false animated:animated];
}

- (void)navigateToConversationWithId:(int64_t)conversationId conversation:(TGConversation *)__unused conversation performActions:(NSDictionary *)performActions atMessage:(NSDictionary *)atMessage clearStack:(bool)__unused clearStack openKeyboard:(bool)openKeyboard animated:(bool)animated
{
    [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:conversationId];
    
    [self dismissBannerForConversationId:conversationId];
    
    TGModernConversationController *conversationController = nil;
    
    for (UIViewController *viewController in TGAppDelegateInstance.rootController.viewControllers)
    {
        if ([viewController isKindOfClass:[TGModernConversationController class]])
        {
            TGModernConversationController *existingConversationController = (TGModernConversationController *)viewController;
            id companion = existingConversationController.companion;
            if ([companion isKindOfClass:[TGGenericModernConversationCompanion class]])
            {
                if (((TGGenericModernConversationCompanion *)companion).conversationId == conversationId)
                {
                    conversationController = existingConversationController;
                    break;
                }
            }
        }
    }
    
    if (conversationController == nil || atMessage[@"mid"] != nil)
    {
        int conversationUnreadCount = [TGDatabaseInstance() unreadCountForConversation:conversationId];
        int globalUnreadCount = [TGDatabaseInstance() cachedUnreadCount];
        
        conversationController = [[TGModernConversationController alloc] init];
        conversationController.shouldOpenKeyboardOnce = openKeyboard;
        
        if (TGPeerIdIsChannel(conversationId))
        {
            conversation = [TGDatabaseInstance() loadChannels:@[@(conversationId)]][@(conversationId)];
            if (conversation != nil) {
                if (conversation.hasExplicitContent) {
                    [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:0];
                    
                    [[[TGAlertView alloc] initWithTitle:TGLocalized(@"ExplicitContent.AlertTitle") message:conversation.restrictionReason.length == 0 ? TGLocalized(@"ExplicitContent.AlertChannel") : [self explicitContentReason:conversation.restrictionReason] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
                    
                    return;
                }
                TGChannelConversationCompanion *companion = [[TGChannelConversationCompanion alloc] initWithPeerId:conversationId conversation:conversation userActivities:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId]];
                if (atMessage != nil)
                    [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
                [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
                [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
                conversationController.companion = companion;
            }
        }
        else if (conversationId <= INT_MIN)
        {
            if ([TGDatabaseInstance() isConversationBroadcast:conversationId])
            {
                TGBroadcastModernConversationCompanion *companion = [[TGBroadcastModernConversationCompanion alloc] initWithConversationId:conversation.conversationId conversation:conversation];
                if (atMessage != nil)
                    [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
                [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
                [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
                conversationController.companion = companion;
            }
            else
            {
                int64_t encryptedConversationId = [TGDatabaseInstance() encryptedConversationIdForPeerId:conversationId];
                int64_t accessHash = [TGDatabaseInstance() encryptedConversationAccessHash:conversationId];
                int32_t uid = [TGDatabaseInstance() encryptedParticipantIdForConversationId:conversationId];
                TGSecretModernConversationCompanion *companion = [[TGSecretModernConversationCompanion alloc] initWithEncryptedConversationId:encryptedConversationId accessHash:accessHash conversationId:conversationId uid:uid activity:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId][@(uid)] mayHaveUnreadMessages:conversationUnreadCount != 0];
                if (atMessage != nil)
                    [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
                [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
                [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
                conversationController.companion = companion;
            }
        }
        else if (conversationId < 0)
        {
            TGConversation *cachedConversation = [TGDatabaseInstance() loadConversationWithIdCached:conversationId];
            TGGroupModernConversationCompanion *companion = [[TGGroupModernConversationCompanion alloc] initWithConversationId:conversationId conversation:cachedConversation userActivities:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId] mayHaveUnreadMessages:conversationUnreadCount != 0];
            if (atMessage != nil)
                [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
            [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
            [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
            conversationController.companion = companion;
        }
        else
        {
            TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)conversationId];
            if (user.hasExplicitContent) {
                [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:0];
                
                [[[TGAlertView alloc] initWithTitle:TGLocalized(@"ExplicitContent.AlertTitle") message:user.restrictionReason.length == 0 ? TGLocalized(@"ExplicitContent.AlertUser") : [self explicitContentReason:user.restrictionReason] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
                
                return;
            }
            
            TGPrivateModernConversationCompanion *companion = [[TGPrivateModernConversationCompanion alloc] initWithUid:(int)conversationId activity:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId][@((int)conversationId)] mayHaveUnreadMessages:conversationUnreadCount != 0];
            companion.botStartPayload = performActions[@"botStartPayload"];
            if (atMessage != nil)
                [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
            [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
            [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
            conversationController.companion = companion;
        }
        
        [conversationController.companion bindController:conversationController];
        
        conversationController.shouldIgnoreAppearAnimationOnce = !animated;
        if (performActions[@"text"] != nil)
            [conversationController setInputText:performActions[@"text"] replace:false selectRange:NSMakeRange(0, 0)];
        
        if (performActions[@"shareLink"] != nil && ((NSDictionary *)performActions[@"shareLink"])[@"url"] != nil) {
            NSString *url = performActions[@"shareLink"][@"url"];
            NSString *text = performActions[@"shareLink"][@"text"];
            NSString *result = @"";
            NSRange textRange = NSMakeRange(0, 0);
            if (text.length != 0) {
                result = [[url stringByAppendingString:@"\n"] stringByAppendingString:text];
                textRange = NSMakeRange(url.length + 1, result.length - url.length - 1);
            } else {
                result = url;
            }
            [conversationController setInputText:result replace:true selectRange:textRange];
            conversationController.shouldOpenKeyboardOnce = true;
        }
        
        [TGAppDelegateInstance.rootController replaceContentController:conversationController];
    }
    else
    {
        if ([(NSArray *)performActions[@"forwardMessages"] count] != 0)
            [(TGGenericModernConversationCompanion *)conversationController.companion standaloneForwardMessages:performActions[@"forwardMessages"]];
        
        if ([(NSArray *)performActions[@"sendMessages"] count] != 0)
            [(TGGenericModernConversationCompanion *)conversationController.companion standaloneSendMessages:performActions[@"sendMessages"]];
        
        if ([(NSArray *)performActions[@"sendFiles"] count] != 0)
            [(TGGenericModernConversationCompanion *)conversationController.companion standaloneSendFiles:performActions[@"sendFiles"]];
        
        if (performActions[@"text"] != nil)
            [conversationController setInputText:performActions[@"text"] replace:false selectRange:NSMakeRange(0, 0)];
        
        if (performActions[@"shareLink"] != nil && ((NSDictionary *)performActions[@"shareLink"])[@"url"] != nil) {
            NSString *url = performActions[@"shareLink"][@"url"];
            NSString *text = performActions[@"shareLink"][@"text"];
            NSString *result = @"";
            NSRange textRange = NSMakeRange(0, 0);
            if (text.length != 0) {
                result = [[url stringByAppendingString:@"\n"] stringByAppendingString:text];
                textRange = NSMakeRange(url.length + 1, result.length - url.length - 1);
            } else {
                result = url;
            }
            [conversationController setInputText:result replace:true selectRange:textRange];
            conversationController.shouldOpenKeyboardOnce = true;
        }
        
        if (performActions[@"botStartPayload"] != nil)
        {
            if ([conversationController.companion isKindOfClass:[TGPrivateModernConversationCompanion class]])
            {
                [(TGPrivateModernConversationCompanion *)conversationController.companion standaloneSendBotStartPayload:performActions[@"botStartPayload"]];
            }
        }
        [TGAppDelegateInstance.rootController popToContentController:conversationController];
        
        if (openKeyboard)
            [conversationController openKeyboard];
    }
}

- (NSString *)explicitContentReason:(NSString *)text {
    NSRange range = [text rangeOfString:@":"];
    if (range.location != NSNotFound) {
        return [text substringFromIndex:range.location + range.length];
    } else {
        return text;
    }
}

- (TGModernConversationController *)configuredPreviewConversationControlerWithId:(int64_t)conversationId {
    return [self configuredPreviewConversationControlerWithId:conversationId performActions:nil];
}

- (TGModernConversationController *)configuredPreviewConversationControlerWithId:(int64_t)conversationId performActions:(NSDictionary *)performActions {
    NSDictionary *atMessage = nil;
    
    int conversationUnreadCount = [TGDatabaseInstance() unreadCountForConversation:conversationId];
    int globalUnreadCount = [TGDatabaseInstance() cachedUnreadCount];
    
    TGModernConversationController *conversationController = [[TGModernConversationController alloc] init];
    conversationController.shouldOpenKeyboardOnce = false;
    
    TGConversation *conversation = nil;
    if (TGPeerIdIsChannel(conversationId))
    {
        conversation = [TGDatabaseInstance() loadChannels:@[@(conversationId)]][@(conversationId)];
        if (conversation != nil) {
            if (conversation.hasExplicitContent) {
                [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:0];
                
                [[[TGAlertView alloc] initWithTitle:TGLocalized(@"ExplicitContent.AlertTitle") message:conversation.restrictionReason.length == 0 ? TGLocalized(@"ExplicitContent.AlertChannel") : [self explicitContentReason:conversation.restrictionReason] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
                
                return nil;
            }
            
            TGChannelConversationCompanion *companion = [[TGChannelConversationCompanion alloc] initWithPeerId:conversationId conversation:conversation userActivities:nil];
            companion.previewMode = true;
            //if (atMessage != nil)
            //    [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
            [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
            [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
            conversationController.companion = companion;
        }
    }
    else if (conversationId <= INT_MIN)
    {
        if ([TGDatabaseInstance() isConversationBroadcast:conversationId])
        {
            TGBroadcastModernConversationCompanion *companion = [[TGBroadcastModernConversationCompanion alloc] initWithConversationId:conversation.conversationId conversation:conversation];
            companion.previewMode = true;
            if (atMessage != nil)
                [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
            [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
            [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
            conversationController.companion = companion;
        }
        else
        {
            int64_t encryptedConversationId = [TGDatabaseInstance() encryptedConversationIdForPeerId:conversationId];
            int64_t accessHash = [TGDatabaseInstance() encryptedConversationAccessHash:conversationId];
            int32_t uid = [TGDatabaseInstance() encryptedParticipantIdForConversationId:conversationId];
            TGSecretModernConversationCompanion *companion = [[TGSecretModernConversationCompanion alloc] initWithEncryptedConversationId:encryptedConversationId accessHash:accessHash conversationId:conversationId uid:uid activity:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId][@(uid)] mayHaveUnreadMessages:conversationUnreadCount != 0];
            companion.previewMode = true;
            if (atMessage != nil)
                [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
            [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
            [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
            conversationController.companion = companion;
        }
    }
    else if (conversationId < 0)
    {
        TGConversation *cachedConversation = [TGDatabaseInstance() loadConversationWithIdCached:conversationId];
        TGGroupModernConversationCompanion *companion = [[TGGroupModernConversationCompanion alloc] initWithConversationId:conversationId conversation:cachedConversation userActivities:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId] mayHaveUnreadMessages:conversationUnreadCount != 0];
        companion.previewMode = true;
        if (atMessage != nil)
            [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
        [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
        [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
        conversationController.companion = companion;
    }
    else
    {
        TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)conversationId];
        if (user.hasExplicitContent) {
            [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:0];
            
            [[[TGAlertView alloc] initWithTitle:TGLocalized(@"ExplicitContent.AlertTitle") message:user.restrictionReason.length == 0 ? TGLocalized(@"ExplicitContent.AlertUser") : [self explicitContentReason:user.restrictionReason] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
            
            return nil;
        }
        
        TGPrivateModernConversationCompanion *companion = [[TGPrivateModernConversationCompanion alloc] initWithUid:(int)conversationId activity:[TGTelegraphInstance typingUserActivitiesInConversationFromMainThread:conversationId][@((int)conversationId)] mayHaveUnreadMessages:conversationUnreadCount != 0];
        companion.previewMode = true;
        companion.botStartPayload = performActions[@"botStartPayload"];
        if (atMessage != nil)
            [companion setPreferredInitialMessagePositioning:[atMessage[@"mid"] intValue]];
        [companion setInitialMessagePayloadWithForwardMessages:performActions[@"forwardMessages"] sendMessages:performActions[@"sendMessages"] sendFiles:performActions[@"sendFiles"]];
        [companion setOthersUnreadCount:MAX(globalUnreadCount - conversationUnreadCount, 0)];
        conversationController.companion = companion;
    }
    
    [conversationController.companion bindController:conversationController];
    
    conversationController.shouldIgnoreAppearAnimationOnce = true;
    
    return conversationController;
}

- (TGModernConversationController *)currentControllerWithPeerId:(int64_t)peerId
{
    for (UIViewController *viewController in TGAppDelegateInstance.rootController.viewControllers)
    {
        if ([viewController isKindOfClass:[TGModernConversationController class]])
        {
            TGModernConversationController *existingConversationController = (TGModernConversationController *)viewController;
            id companion = existingConversationController.companion;
            if ([companion isKindOfClass:[TGGenericModernConversationCompanion class]])
            {
                if (((TGGenericModernConversationCompanion *)companion).conversationId == peerId)
                    return existingConversationController;
            }
        }
    }
    
    return nil;
}

- (void)dismissConversation
{
    [TGAppDelegateInstance.rootController clearContentControllers];
    [TGAppDelegateInstance.rootController.dialogListController selectConversationWithId:0];
}

- (void)navigateToConversationWithBroadcastUids:(NSArray *)__unused broadcastUids forwardMessages:(NSArray *)__unused forwardMessages
{
}

- (void)navigateToProfileOfUser:(int)uid
{
    [self navigateToProfileOfUser:uid preferNativeContactId:0];
}

- (void)navigateToProfileOfUser:(int)uid shareVCard:(void (^)())shareVCard
{
    TGUser *user = [TGDatabaseInstance() loadUser:uid];
    if (user.kind == TGUserKindBot || user.kind == TGUserKindSmartBot)
    {
        TGBotUserInfoController *userInfoController = [[TGBotUserInfoController alloc] initWithUid:uid sendCommand:nil];
        [TGAppDelegateInstance.rootController pushContentController:userInfoController];
    }
    else
    {
        TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:uid];
        userInfoController.shareVCard = shareVCard;
        [TGAppDelegateInstance.rootController pushContentController:userInfoController];
    }
}

- (void)navigateToProfileOfUser:(int)uid encryptedConversationId:(int64_t)encryptedConversationId
{
    [self navigateToProfileOfUser:uid preferNativeContactId:0 encryptedConversationId:encryptedConversationId];
}

- (void)navigateToProfileOfUser:(int)uid preferNativeContactId:(int)preferNativeContactId
{
    [self navigateToProfileOfUser:uid preferNativeContactId:preferNativeContactId encryptedConversationId:0];
}

- (void)navigateToProfileOfUser:(int)uid preferNativeContactId:(int)__unused preferNativeContactId encryptedConversationId:(int64_t)encryptedConversationId
{
    if (encryptedConversationId == 0)
    {
        TGUser *user = [TGDatabaseInstance() loadUser:uid];
        
        if (user.kind == TGUserKindBot || user.kind == TGUserKindSmartBot)
        {
            TGBotUserInfoController *userInfoController = [[TGBotUserInfoController alloc] initWithUid:uid sendCommand:nil];
            [TGAppDelegateInstance.rootController pushContentController:userInfoController];
        }
        else
        {
            TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:uid];
            [TGAppDelegateInstance.rootController pushContentController:userInfoController];
        }
    }
    else
    {
        TGSecretChatUserInfoController *secretChatInfoController = [[TGSecretChatUserInfoController alloc] initWithUid:uid encryptedConversationId:encryptedConversationId];
        [TGAppDelegateInstance.rootController pushContentController:secretChatInfoController];
    }
}

- (void)navigateToMediaListOfConversation:(int64_t)conversationId navigationController:(UINavigationController *)navigationController
{
    if (conversationId == 0)
        return;
    
    TGGenericPeerMediaListModel *model = [[TGGenericPeerMediaListModel alloc] initWithPeerId:conversationId allowActions:conversationId > INT_MIN];
    
    TGModernMediaListController *controller = [[TGModernMediaListController alloc] init];
    controller.model = model;
    
    //TGPhotoGridController *photoController = [[TGPhotoGridController alloc] initWithConversationId:conversationId isEncrypted:conversationId <= INT_MIN];
    [navigationController pushViewController:controller animated:true];
}

- (void)_initializeNotificationControllerIfNeeded
{
    if (_notificationController == nil)
    {
        _notificationController = [[TGNotificationController alloc] init];
        
        __weak TGInterfaceManager *weakSelf = self;
        _notificationController.navigateToConversation = ^(int64_t conversationId)
        {
            __strong TGInterfaceManager *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (TGAppDelegateInstance.contentWindow != nil)
                return;
            
            if (conversationId == 0)
                return;
            
            if (conversationId < 0)
            {
                if ([TGDatabaseInstance() loadConversationWithId:conversationId] == nil)
                    return;
            }
            
            bool animated = true;
            if (TGAppDelegateInstance.rootController.presentedViewController != nil)
            {
                [TGAppDelegateInstance.rootController dismissViewControllerAnimated:true completion:nil];
                animated = false;
            }
            
            for (UIWindow *window in [UIApplication sharedApplication].windows)
            {
                if ([window isKindOfClass:[TGOverlayControllerWindow class]] && window != _notificationController.window)
                {
                    TGOverlayController *controller = (TGOverlayController *)window.rootViewController;
                    [controller dismiss];
                    animated = false;                    
                    break;
                }
            }
            
            [strongSelf navigateToConversationWithId:conversationId conversation:nil animated:animated];
        };
    }
}

- (void)displayBannerIfNeeded:(TGMessage *)message conversationId:(int64_t)conversationId
{
    if (TGAppDelegateInstance.isDisplayingPasscodeWindow || !TGAppDelegateInstance.bannerEnabled || TGAppDelegateInstance.rootController.isSplitView)
        return;
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        TGUser *user = nil;
        TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:conversationId];
        
        if (!conversation.isChannel || conversation.isChannelGroup)
            user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
        
        if (conversationId > 0 || conversation != nil)
        {
            TGDispatchOnMainThread(^
            {
                if ([UIApplication sharedApplication] == nil || [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                    return;
                
                [self _initializeNotificationControllerIfNeeded];

                if ([_notificationController shouldDisplayNotificationForConversation:conversation])
                {
                    NSMutableDictionary *peers = [[NSMutableDictionary alloc] init];
                    if (user != nil)
                        peers[@"author"] = user;
                    
                    if (message.mediaAttachments.count != 0)
                    {
                        NSMutableArray *peerIds = [[NSMutableArray alloc] init];
                        for (TGMediaAttachment *attachment in message.mediaAttachments)
                        {
                            if (attachment.type == TGActionMediaAttachmentType)
                            {
                                TGActionMediaAttachment *actionAttachment = (TGActionMediaAttachment *)attachment;
                                switch (actionAttachment.actionType)
                                {
                                    case TGMessageActionChatAddMember:
                                    case TGMessageActionChatDeleteMember:
                                    {
                                        if (actionAttachment.actionData[@"uids"] != nil) {
                                            [peerIds addObjectsFromArray:actionAttachment.actionData[@"uids"]];
                                        } else if (actionAttachment.actionData[@"uid"] != nil) {
                                            NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                                            [peerIds addObject:nUid];
                                        }
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            }
                            else if (attachment.type == TGReplyMessageMediaAttachmentType)
                            {
                                TGReplyMessageMediaAttachment *replyAttachment = (TGReplyMessageMediaAttachment *)attachment;
                                if (replyAttachment.replyMessage.fromUid != 0)
                                    [peerIds addObject:@(replyAttachment.replyMessage.fromUid)];
                            }
                            else if (attachment.type == TGForwardedMessageMediaAttachmentType)
                            {
                                TGForwardedMessageMediaAttachment *forwardAttachment = (TGForwardedMessageMediaAttachment *)attachment;
                                if (forwardAttachment.forwardPeerId != 0)
                                    [peerIds addObject:@(forwardAttachment.forwardPeerId)];
                            }
                            else if (attachment.type == TGContactMediaAttachmentType)
                            {
                                TGContactMediaAttachment *contactAttachment = (TGContactMediaAttachment *)attachment;
                                if (contactAttachment.uid != 0)
                                    [peerIds addObject:@(contactAttachment.uid)];
                            }
                        }
                        
                        for (NSNumber *peerIdValue in peerIds)
                        {
                            int64_t peerId = peerIdValue.int64Value;
                            if (TGPeerIdIsChannel(peerId))
                            {
                                TGConversation *channel = [TGDatabaseInstance() loadConversationWithId:peerId];
                                if (channel != nil)
                                    peers[@(channel.conversationId)] = channel;
                            }
                            else
                            {
                                TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)peerId];
                                if (user != nil)
                                    peers[@(user.uid)] = user;
                            }
                        }
                    }
                    
                    int32_t replyToMid = (TGPeerIdIsGroup(message.cid) || TGPeerIdIsChannel(message.cid)) ? message.mid : 0;
                    [_notificationController displayNotificationForConversation:conversation identifier:message.mid replyToMid:replyToMid duration:5.0 configure:^(TGNotificationContentView *view, bool *isRepliable)
                    {
                        *isRepliable = (!conversation.isChannel || conversation.isChannelGroup) && (conversation.encryptedData == nil);
                        [view configureWithMessage:message conversation:conversation peers:peers];
                    }];
                }
            });
        }
    }];
}

- (void)dismissBannerForConversationId:(int64_t)conversationId
{
    [_notificationController dismissNotificationsForConversationId:conversationId];
}

- (void)dismissAllBanners
{
    [_notificationController dismissAllNotifications];
}

- (void)localizationUpdated
{
    [_notificationController localizationUpdated];
}

@end
