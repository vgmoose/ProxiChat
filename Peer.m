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
    UILabel* tv = [[UILabel alloc] init];
    [tv setTag:12];
    
    _convo = @"";
    [tv sizeToFit]; //added
    [tv layoutIfNeeded]; //added
    
    tv.text = @"Hello";
    
    [tv.layer setCornerRadius:20];

    
    circ.frame = self.bounds;
    tv.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+80, self.bounds.size.width, self.bounds.size.height-50);
    
    tv.textColor = [UIColor whiteColor];
    
    

    UIColor * color = [UIColor colorWithRed:34/255.0f green:152/255.0f blue:255/255.0f alpha:1.0f];
    tv.backgroundColor = color;
    
    CGSize size = tv.frame.size;
    
    /** Shadow */
    CALayer *shadowLayer = [CALayer new];
    shadowLayer.frame = CGRectMake(20,20,size.width,size.height);
    shadowLayer.cornerRadius = 10;
    
    shadowLayer.backgroundColor = color.CGColor;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 0.6;
    shadowLayer.shadowOffset = CGSizeMake(0,0);
    shadowLayer.shadowRadius = 3;
    
    
    
    /** Label */
    UILabel *label = tv;
//    label.text = @"H";
    label.textAlignment = UITextAlignmentCenter;
//    label.frame = CGRectMake(0, 0, size.width, size.height);
    label.backgroundColor = color;
    label.layer.cornerRadius = 10;
    [label.layer setMasksToBounds:YES];
    label.backgroundColor = color;
    
    /** Add the Label to the shawdow layer */
    [shadowLayer addSublayer:label.layer];
    
//    [self.layer addSublayer:shadowLayer];
    

    _shown = false;
    
    [self addSubview:circ];
    [self addSubview:tv];
    
    
//    [UIView animateWithDuration:0
//                          delay:1
//                        options:UIViewAnimationOptionRepeat
//                     animations:^{
//                         self.frame = CGRectOffset(self.frame, drand48()*20, drand48()*20);
//
//                     }
//                     completion:nil];
    
    return self;
}

- (void) tweenTo : (CGPoint)point startingAt: (CGPoint)opoint
{
    // set initial position (far out from current thing)
    int delay = 0;
    if (!_shown)
    {
//        NSLog(@"this is animating");
        self.frame = CGRectMake(opoint.x, opoint.y, self.frame.size.width, self.frame.size.height);
        delay = 2;
    }

    _shown = true;
    
    [UIView animateWithDuration:1
                          delay:delay
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = CGRectMake(point.x, point.y, self.frame.size.width, self.frame.size.height);
                     }
                     completion:nil];
    NSLog(@"ANIMATION COMPLETED");

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

- (void) setStatusString : (NSString*) statustext
{
    UILabel* tv = (UILabel*)[self viewWithTag:12];
    [tv setText:statustext];
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *)event
{
    self.transform = CGAffineTransformMakeScale(1.1f, 1.1f); // shrink to half.
    _moved = false;
    _myVC.heldPeer = self;
    [_myVC reflowPeers];

}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *)event
{
    self.transform = CGAffineTransformMakeScale(1.0f, 1.0f); // shrink to half.
    
    // we didn't move, start the chat
    if (!_moved)
    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
//                                                        message:@"You must be connected to the internet to use this app."
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
        [UIView animateWithDuration:0.5
                              delay:0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.frame = CGRectMake(10, 25, self.frame.size.width, self.frame.size.height);
                         }
                         completion:^(BOOL b){
                             if (b)
                                 [_myVC startConversationWith: self];
                         }];
    }
    else
    {
        _myVC.heldPeer = nil;
        [_myVC endConversation];
        [_myVC reflowPeers];
    }
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _moved = true;
    UITouch *aTouch = [touches anyObject];
    CGPoint location = [aTouch locationInView:self];
    CGPoint previousLocation = [aTouch previousLocationInView:self];
    self.frame = CGRectOffset(self.frame, (location.x - previousLocation.x), (location.y - previousLocation.y));
    
//    if (_myVC.heldPeer && aTouch.)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
//                                                        message:@"You must be connected to the internet to use this app."
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
}



@end

// loads the picture and history from the database if they exist
//- (void) loadCachedPicAndHistory
//{
//    
//}

