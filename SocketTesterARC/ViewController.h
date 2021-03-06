//
//  ViewController.h
//  SocketTesterARC
//
//  Created by Kyeck Philipp on 01.06.12.
//  Copyright (c) 2012 beta_interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SocketIO.h"
#import "ViewControllerAndPeer.h"
@class Peer;

@interface ViewController : UIViewController <SocketIODelegate, CLLocationManagerDelegate, UITextFieldDelegate, UIWebViewDelegate>
{
    SocketIO *socketIO;
    NSString* _id;
    NSString* imagefilename;
    int sendee;
}
- (void)startConversationWith:(Peer*)friend;
- (void)reflowPeers;
- (void)endConversation;
- (void)scrollDown;

//- (void) startConversationWith: (Peer*) friend;
@property CLLocationManager *locationManager;
@property BOOL dirty;
@property int counter;
@property Peer* heldPeer;
@property BOOL permafloat;
@end
