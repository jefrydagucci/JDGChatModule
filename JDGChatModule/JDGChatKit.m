//
//  JDGChatKit.m
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

#import "JDGChatKit.h"

@implementation JDGChatKit

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
    if (![xmppStream isDisconnected]) {
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    
    //    if (customCertEvaluation)
    //    {
    //        [settings setObject:@(YES) forKey:GCDAsyncSocketManuallyEvaluateTrust];
    //    }
}

/**
 * Allows a delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if the stream is secured with settings that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 * That is, if a delegate implements xmppStream:willSecureWithSettings:, and plugs in that key/value pair.
 *
 * Thus this delegate method is forwarding the TLS evaluation callback from the underlying GCDAsyncSocket.
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * This is why this method uses a completionHandler block rather than a normal return value.
 * The idea is that you should be performing SecTrustEvaluate on a background thread.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
 *
 * Keep in mind that you can do all kinds of cool stuff here.
 * For example:
 *
 * If your development server is using a self-signed certificate,
 * then you could embed info about the self-signed cert within your app, and use this callback to ensure that
 * you're actually connecting to the expected dev server.
 *
 * Also, you could present certificates that don't pass SecTrustEvaluate to the client.
 * That is, if SecTrustEvaluate comes back with problems, you could invoke the completionHandler with NO,
 * and then ask the client if the cert can be trusted. This is similar to how most browsers act.
 *
 * Generally, only one delegate should implement this method.
 * However, if multiple delegates implement this method, then the first to invoke the completionHandler "wins".
 * And subsequent invocations of the completionHandler are ignored.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    
    // The delegate method should likely have code similar to this,
    // but will presumably perform some extra security code stuff.
    // For example, allowing a specific self-signed certificate that is known to the app.
    
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
    if([_delegate respondsToSelector:@selector(passwordForAuthentication)]){
        NSString *pass = [_delegate passwordForAuthentication];
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
    
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    
    NSLog(@"receive IQ %@", iq);
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    
    // A simple example of inbound message handling.
    
    if ([message isChatMessageWithBody]){
        XMPPUserMemoryStorageObject *user = [xmppRosterStorage userForJID:[message from]];
        NSString *displayName = [user displayName];
        NSString *body = [[message elementForName:@"body"] stringValue];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XMPPGetMessage" object:nil userInfo:@{@"user": message.from.user}];
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
            
        }
        else{
            // We are not active, so use a local notification instead
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = @"Ok";
            localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{

}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    
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
