//
//  Peer.m
//  Proxi
//
//  Created by Ricky Ayoub on 11/6/14.
//  Copyright (c) 2014 beta_interactive. All rights reserved.
//

#import "Peer.h"

@implementation Peer


- (id) init
{
    _bubble = [UIView init];
    [_bubble addSubview:[UIImageView init]];
    
    return self;
}

@end

// loads the picture and history from the database if they exist
//- (void) loadCachedPicAndHistory
//{
//    
//}

