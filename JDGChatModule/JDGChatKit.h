//
//  JDGChatKit.h
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPStream.h"
#import "XMPPRosterMemoryStorage.h"


@protocol JDGChatKitDelegate <NSObject>

@optional
- (NSString *)passwordForAuthentication;


@end
@interface JDGChatKit : NSObject{
    XMPPStream *xmppStream;
    XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
    XMPPRosterMemoryStorage *xmppRosterStorage;
}

@property (nonatomic, retain) NSString *username;
@property (nonatomic, assign) id<JDGChatKitDelegate> delegate;

@end