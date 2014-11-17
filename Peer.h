//
//  Peer.h
//  Proxi
//
//  Created by Ricky Ayoub on 11/6/14.
//  Copyright (c) 2014 beta_interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Peer : NSObject
@property (strong, nonatomic) NSString* _id;
@property (strong, nonatomic) NSString* status;
@property (strong, nonatomic) NSString* pic;
@property (strong, nonatomic) UIView* bubble;

@end

//NSString* name;
//UIImage* avatar;
//NSString* status;
//NSMutableArray* history;
//NSString* picHash;
