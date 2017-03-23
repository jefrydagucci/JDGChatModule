//
//  JDGChatKit.h
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPFramework.h>

@class JDGChatKit;
@protocol JDGChatKitDelegate <NSObject>
@optional
- (NSString *)passwordForAuthentication:(XMPPJID *)jid;

@end

@protocol JDGChatKitStreamDelegate <NSObject>
@optional

- (void)jdg_chatKit:(JDGChatKit *)kit didAuthenticate:(XMPPStream *)stream;
- (void)jdg_chatKit:(JDGChatKit *)kit didNotAuthenticate:(NSXMLElement *)error;

- (void)jdg_chatKit:(JDGChatKit *)kit willReceiveMessage:(XMPPMessage *)message stream:(XMPPStream *)stream;
- (void)jdg_chatKit:(JDGChatKit *)kit didReceiveMessage:(XMPPMessage *)message stream:(XMPPStream *)stream;

- (void)jdg_chatKit:(JDGChatKit *)kit willSendMessage:(XMPPMessage *)message stream:(XMPPStream *)stream;
- (void)jdg_chatKit:(JDGChatKit *)kit didSendMessage:(XMPPMessage *)message stream:(XMPPStream *)stream;


@end

@interface JDGChatKit : NSObject{
    XMPPStream *xmppStream;
    XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
    XMPPRosterMemoryStorage *xmppRosterStorage;
}

@property (nonatomic, assign) id<JDGChatKitDelegate> delegate;
@property (nonatomic, assign) id<JDGChatKitStreamDelegate> streamDelegate;

+ (instancetype)shared;

#pragma mark - connect
- (BOOL)connect:(NSString *)jid;

- (void)disconnect;

- (void)goOnline;

- (void)goOffline;

#pragma mark - message
- (void)sendMessage:(NSString *)message toID:(NSString *)jid;

@end


@interface XMPPMessage (JDGChatKitMessage)

- (NSData *)imageAttachmentData;

- (UIImage *)imageAttachment;

@end

@interface JDGChatKit (JDGChatKitMessage)

- (void)sendMessage:(NSString *)message image:(UIImage *)image toID:(NSString *)jid;

@end
