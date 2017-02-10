/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "ASActor.h"

@interface TGConversationReadHistoryActor : ASActor

+ (NSString *)genericPath;

- (void)conversationReadHistoryRequestFailed;
- (void)conversationReadHistoryRequestSuccess:(NSArray *)readMessages;

+ (void)executeStandalone:(int64_t)conversationId;

@end
