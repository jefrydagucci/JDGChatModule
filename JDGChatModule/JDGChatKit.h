//
//  JDGChatKit.h
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPFramework.h>

@protocol JDGChatKitDelegate <NSObject>

@optional
- (NSString *)passwordForAuthentication:(XMPPJID *)jid;


@end
@interface JDGChatKit : NSObject{
    XMPPStream *xmppStream;
    XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
    XMPPRosterMemoryStorage *xmppRosterStorage;
}

@property (nonatomic, assign) id<JDGChatKitDelegate> delegate;

+ (instancetype)shared;

#pragma mark - connect
- (BOOL)connect:(NSString *)jid;

- (void)disconnect;

- (void)goOnline;

- (void)goOffline;

@end
