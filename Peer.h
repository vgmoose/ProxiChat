//
//  Peer.h
//  Proxi
//
//  Created by Ricky Ayoub on 11/6/14.
//  Copyright (c) 2014 beta_interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewControllerAndPeer.h"

@class ViewController;

@interface Peer : UIView
@property (strong, nonatomic) NSString* _id;
@property (strong, nonatomic) NSString* status;
@property (strong, nonatomic) NSString* pic;
@property (assign, nonatomic) BOOL shown;
@property (assign, nonatomic) BOOL moved;
- (void) tweenTo : (CGPoint) point startingAt:(CGPoint) opoint;
@property (assign, nonatomic) ViewController* myVC;
- (void) setImageString : (NSString*) imagename;
- (void) setStatusString : (NSString*) imagename;
@end

//NSString* name;
//UIImage* avatar;
//NSString* status;
//NSMutableArray* history;
//NSString* picHash;
