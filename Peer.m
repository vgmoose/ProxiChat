//
//  Peer.m
//  Proxi
//
//  Created by Ricky Ayoub on 11/6/14.
//  Copyright (c) 2014 beta_interactive. All rights reserved.
//

#import "Peer.h"

@implementation Peer

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.frame = frame;
    UIImageView* circ = [[UIImageView alloc] init];
    [circ setTag:11];
    circ.frame = self.bounds;
    
    [self addSubview:circ];
    
    return self;
}

- (void) setImageString : (NSString*) imagename
{
    UIImageView* circ = (UIImageView*)[self viewWithTag:11];
    
    // set the image
    [circ setImage:[UIImage imageNamed:imagename]];
    NSLog(@"aaAaaa %@", imagename);
    
    float size2 = self.frame.size.width;
    
    [circ.layer setCornerRadius:size2/2];
    [circ.layer setMasksToBounds:YES];
    circ.clipsToBounds = YES;
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 5.f;
    self.layer.shadowOffset = CGSizeMake(0.f, 5.f);
    self.layer.shadowOpacity = .5f;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:size2/2].CGPath;
    
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *aTouch = [touches anyObject];
    CGPoint location = [aTouch locationInView:self];
    CGPoint previousLocation = [aTouch previousLocationInView:self];
    self.frame = CGRectOffset(self.frame, (location.x - previousLocation.x), (location.y - previousLocation.y));
}

@end

// loads the picture and history from the database if they exist
//- (void) loadCachedPicAndHistory
//{
//    
//}

