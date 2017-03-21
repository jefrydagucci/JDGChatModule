//
//  JDGChatKit.m
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

#import "JDGChatKit.h"

@interface JDGChatKit ()
<XMPPStreamDelegate>

@end

@implementation JDGChatKit

+ (instancetype)shared{
    static id sharedInstance;
    if(!sharedInstance){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[[self class] alloc] init];
            [sharedInstance setupStream];
        });
    }
    return sharedInstance;
}
- (void)setupStream{
    xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    {
        xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    
    xmppReconnect = [[XMPPReconnect alloc] init];
    xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    
    [xmppReconnect         activate:xmppStream];
    [xmppRoster            activate:xmppStream];
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
}


- (void)teardownStream{
    [xmppStream removeDelegate:self];
    [xmppRoster removeDelegate:self];
    [xmppReconnect deactivate];
    [xmppRoster deactivate];
    [xmppStream disconnect];
    xmppStream = nil;
    xmppReconnect = nil;
    xmppRoster = nil;
    xmppRosterStorage = nil;
}

#pragma mark - message
- (void)sendMessage:(NSString *)message toID:(NSString *)jid{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    NSXMLElement *_message = [NSXMLElement elementWithName:@"message"];
    [_message addAttributeWithName:@"type" stringValue:@"chat"];
    [_message addAttributeWithName:@"to" stringValue:jid];
    [_message addChild:body];
    
    NSXMLElement * thread = [NSXMLElement elementWithName:@"thread" stringValue:@"SomeThreadName"];
    [_message addChild:thread];
    
    [xmppStream sendElement:_message];
}

#pragma mark - connect
- (BOOL)connect:(NSString *)jid{
    if ([xmppStream isConnected]) {
        return YES;
    }
    [xmppStream setMyJID:[XMPPJID jidWithString:jid]];
    
    NSError *error = nil;
    if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]){
        
        return NO;
    }
    
    return YES;
}

- (void)disconnect{
    [self goOffline];
    [xmppStream disconnect];
}

- (void)goOnline{
    XMPPPresence *presence = [XMPPPresence presence];
    [xmppStream sendElement:presence];
}

- (void)goOffline{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [xmppStream sendElement:presence];
}

#pragma mark XMPPStream Delegate
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    
    NSString *expectedCertName = [xmppStream.myJID domain];
    if (expectedCertName)
    {
        [settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
    }
    
}
- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bgQueue, ^{
        
        SecTrustResultType result = kSecTrustResultDeny;
        OSStatus status = SecTrustEvaluate(trust, &result);
        
        if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
            completionHandler(YES);
        }
        else {
            completionHandler(NO);
        }
    });
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender{
    
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender{
    if([_delegate respondsToSelector:@selector(passwordForAuthentication:)]){
        NSString *pass = [_delegate passwordForAuthentication:sender.myJID];
        NSError *error;
        if (![xmppStream authenticateWithPassword:pass error:&error]){
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error{
    //JDGChatKitBug
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    
    NSLog(@"receive IQ %@", iq);
    return NO;
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message{
    if ([_streamDelegate respondsToSelector:@selector(jdg_chatKit:willSendMessage:stream:)]){
        [_streamDelegate jdg_chatKit:self willSendMessage:message stream:sender];
    }
    return message;
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    if ([_streamDelegate respondsToSelector:@selector(jdg_chatKit:didSendMessage:stream:)]){
        [_streamDelegate jdg_chatKit:self didSendMessage:message stream:sender];
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    if ([_streamDelegate respondsToSelector:@selector(jdg_chatKit:didReceiveMessage:stream:)]){
        [_streamDelegate jdg_chatKit:self didReceiveMessage:message stream:sender];
    }
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender willReceiveMessage:(XMPPMessage *)message{
    if ([_streamDelegate respondsToSelector:@selector(jdg_chatKit:willReceiveMessage:stream:)]){
        [_streamDelegate jdg_chatKit:self willReceiveMessage:message stream:sender];
    }
    return message;
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    //JDGChatKitBug
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error{
    //JDGChatKitBug
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    //JDGChatKitBug
}

#pragma mark XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence{
    
    XMPPUserMemoryStorageObject *user = [xmppRosterStorage userForJID:[presence from]];
    NSString *displayName = [user displayName];
    NSString *jidStrBare = [presence fromStr];
    NSString *body = nil;
    
    if (![displayName isEqualToString:jidStrBare]){
        body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
    }
    else{
        body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
    }
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                            message:body
                                                           delegate:nil
                                                  cancelButtonTitle:@"Not implemented"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else{
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Not implemented";
        localNotification.alertBody = body;
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    
}


@end
