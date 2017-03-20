//
//  JDGChatModule.swift
//  JDGChatModule
//
//  Created by Jefry Da Gucci on 3/20/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

import Foundation
import XMPPFramework
import KissXML

open class JDGChatModule:NSObject{
    
    var xmppStream:XMPPStream?
    var xmppReconnect:XMPPReconnect?
    var xmppRoster:XMPPRoster?
    var xmppRosterStorage:XMPPRosterStorage?
    
    func setupStream(){
        
        xmppStream      = XMPPStream()
        xmppReconnect   = XMPPReconnect()
        
        #if !TARGET_IPHONE_SIMULATOR
                xmppStream?.enableBackgroundingOnSocket = true
        #endif
        
        xmppRosterStorage = XMPPRosterMemoryStorage()
        xmppRoster      = XMPPRoster( rosterStorage: xmppRosterStorage)
        xmppRoster?.autoFetchRoster = true
        xmppRoster?.autoAcceptKnownPresenceSubscriptionRequests = true
        
        xmppReconnect?.activate(xmppStream)
        xmppRoster?.activate(xmppStream)
        
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func tearDownStream(){
        xmppStream?.removeDelegate(self)
        xmppRoster?.removeDelegate(self)
        xmppReconnect?.deactivate()
        xmppRoster?.deactivate()
        xmppStream?.disconnect()
        
        xmppRoster          = nil
        xmppReconnect       = nil
        xmppRosterStorage   = nil
        xmppStream          = nil
    }
    
    func send(message text:String, toID jid:String){
        let body = DDXMLElement( name: "body")
        (body as DDXMLNode)
        
        xmppStream?.sendAuthElement(body)
    }
}
