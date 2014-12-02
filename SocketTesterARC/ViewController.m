#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIImageView *main_circle;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatus;
@property (weak, nonatomic) IBOutlet UILabel *peopleCounter;
@property (weak, nonatomic) IBOutlet UILabel *statusMessage;
@property (weak, nonatomic) IBOutlet UITextField *statusUpdater;

@property (weak, nonatomic) IBOutlet UITextField *typeBox;
@property (weak, nonatomic) IBOutlet UIWebView *chatHistory;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *msgicon;
@property (weak, nonatomic) IBOutlet UIView *dimmer;

@end

NSMutableDictionary* peers;

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // create socket.io client instance
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    
    // you can update the resource name of the handshake URL
    // see https://github.com/pkyeck/socket.IO-objc/pull/80
    // [socketIO setResourceName:@"whatever"];
    
    // if you want to use https instead of http
    // socketIO.useSecure = YES;
    
    // startup location stuffs
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.statusUpdater.delegate = self;
    self.typeBox.delegate = self;
    self.chatHistory.delegate = self;

    
    _dirty = true;

    
    [_statusMessage setText:@""];
//    [_status1 setText:@""];
//    [_status2 setText:@""];
    
//    [_chatHistory setHidden:true];
//    [_typeBox setHidden:true];
    
    // create the peer mutable array
    peers = [NSMutableDictionary dictionary];
    
    srand48(time(0));
    
    // set a random image if one has not been set yet
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSLog(@"FILESYS: %@", bundleRoot);
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSLog(@"files: %@", filenames);
    int size = [filenames count];
    int rando;

    while (true)
    {
        rando = drand48()*size;
        if ([filenames[rando] hasSuffix:@"x.png"] || [filenames[rando] hasPrefix:@"AppIcon"])
            continue;
        if ([filenames[rando] hasSuffix:@".png"] && ![filenames[rando] hasSuffix:@"b_.png"])
            break;
    }
    
    NSLog(@"Chosen file is : %@", filenames[rando]);
    imagefilename = filenames[rando];
    NSLog(@"%@", _main_circle);

    // set the image
    [_main_circle setImage:[UIImage imageNamed:filenames[rando]]];
    
    float size2 = self.container.frame.size.width;
    
    [self.main_circle.layer setCornerRadius:size2/2];
    [self.main_circle.layer setMasksToBounds:YES];
    self.main_circle.clipsToBounds = YES;

    self.container.backgroundColor = [UIColor clearColor];
    self.container.layer.shadowColor = [UIColor blackColor].CGColor;
    self.container.layer.shadowColor = [UIColor blackColor].CGColor;
    self.container.layer.shadowRadius = 5.f;
    self.container.layer.shadowOffset = CGSizeMake(0.f, 5.f);
    self.container.layer.shadowOpacity = .5f;
    self.container.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.container.bounds cornerRadius:size2/2].CGPath;

    // pass cookie(s) to handshake endpoint (e.g. for auth)
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"localhost", NSHTTPCookieDomain,
                                @"/", NSHTTPCookiePath,
                                @"auth", NSHTTPCookieName,
                                @"56cdea636acdf132", NSHTTPCookieValue,
                                nil];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:properties];
    NSArray *cookies = [NSArray arrayWithObjects:cookie, nil];
    
    socketIO.cookies = cookies;
    
    _chatHistory.layer.cornerRadius = 10;
    _chatHistory.clipsToBounds = YES;
    
    NSString *embedHTML = @"<br /><br /><br />";
    
    _chatHistory.userInteractionEnabled = YES;
    _chatHistory.opaque = YES;
    [_chatHistory loadHTMLString: embedHTML baseURL: nil];

    
    [[_chatHistory layer] setBorderColor:
     [[UIColor colorWithRed:255 green:255 blue:255 alpha:1] CGColor]];
    [[_chatHistory layer] setBorderWidth:2];
    
    // try to load an ID (defaults to zero)
    _id = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    
    // connect to the socket.io server that is running locally at port 3000
    [socketIO connectToHost:@"72.19.86.119" onPort:3007];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    // Being compiled with a Base SDK of iOS 8 or later
    // Now do a runtime check to be sure the method is supported
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        // No such method on this device - do something else as needed
    }
#else
    // Being compiled with a Base SDK of iOS 7.x or earlier
    // No such method - do something else as needed
#endif
    [self.locationManager startUpdatingLocation];


}

# pragma mark -
# pragma mark socket.IO-objc delegate methods

- (void) socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"socket.io connected.");
    [_connectionStatus setText:@"Connection Status:\nConnected"];
    
    if (_id == 0)
    {
        NSLog(@"Requesting an ID...");
        [socketIO sendEvent:@"get_new_id" withData:@"testWithString"];
    }
    else
    {
        NSLog(@"ID is %@, telling server", _id);
        [socketIO sendEvent:@"login" withData:[NSString stringWithFormat: @"%@", _id]];
    }
    

}

- (void) reflowPeers
{
    int count = [peers count];
    NSLog(@"Reflowing %d peers...", count);
    NSMutableArray* keys = [NSMutableArray arrayWithArray:[peers allKeys]];
    
    // if a peer is being held
    if (_heldPeer)
    {
        for (int x=0; x<[keys count]; x++)
        {
            if (peers[keys[x]] == _heldPeer)
            {
                [keys removeObjectAtIndex:x];
                count--;
                break;
            }
        }
    }

    for (int j = 0; j < count; j++)
    {
        
        int x = 120 + sin(j*(2*3.14159265 / count)) * 110 + drand48()*10-5;
        int y = 185 + cos(j*(2*3.14159265 / count)) * 110 + drand48()*10-5;
        int ox = 120 + sin(j*(2*3.14159265 / count)) * 350;
        int oy = 185 + cos(j*(2*3.14159265 / count)) * 350;
//        NSLog(@"Telling %@ to tween to %d, %d",keys[j], x, y);
        [peers[keys[j]] tweenTo: CGPointMake(x, y) startingAt: CGPointMake(ox, oy)];
    }
    
    _dirty = false;
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveEvent()");
    
    if ([packet.name isEqualToString:@"assign_id"])
    {
        _id = packet.args[0][@"id"];
        [[NSUserDefaults standardUserDefaults] setObject:_id forKey:@"userId"];
        [_connectionStatus setText:[NSString stringWithFormat:@"Connection Status:\nAssigned ID#%@", _id]];
        NSLog(@"Got ID: %@", _id);
    }
    else if ([packet.name isEqualToString:@"new_people"])
    {        
        // for each person
        for (int x=0; x<[packet.args[0] count]; x++)
        {
            NSString* thisID = packet.args[0][x][@"id"];
            Peer* thisPeer = [peers objectForKey:thisID];
            
            // if this id doesn't already exist in peer dict
            if (!thisPeer)
            {
                // add the peer
                Peer* thisPeer = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
                peers[thisID] = thisPeer;
                
                thisPeer.myVC = self;
                
                // add the view to the GUI
                [[self view] addSubview:thisPeer];
                
                // set its information
                thisPeer._id = thisID;
                
                // mark bubble graph as dirty
                _dirty = true;
            }
            
            // update peer information
            thisPeer.status = packet.args[0][x][@"status"];
            thisPeer.pic = packet.args[0][x][@"pic"];
            [thisPeer setImageString:thisPeer.pic];
            [thisPeer setStatusString:thisPeer.status];
        }
        
        if (_dirty)
            [self reflowPeers];
        [_peopleCounter setText:[NSString stringWithFormat:@"People Nearby:\n%d", [packet.args[0] count]]];
        
    }
    else if ([packet.name isEqualToString:@"get_message"])
    {
        NSString *embedHTML = [NSString stringWithFormat:@"%@<br style='clear:both'/><div style='border-radius:20px 20px 20px 20px; background-color: #c4c4c4; display:inline-block; float:left; font-family: Helvetica, arial, sans-serif; color: black; padding: 5px 10px'>%@</div>", _heldPeer.convo, packet.args[0][@"message"]];
        _heldPeer.convo = embedHTML;
        [_chatHistory loadHTMLString: embedHTML baseURL: nil];
        
//           [_chatHistory setText:];
//        if(_chatHistory.text.length > 0 ) {
//            NSRange bottom = NSMakeRange(_chatHistory.text.length -1, 1);
//            [_chatHistory scrollRangeToVisible:bottom];
//        }
    }

    
    // test acknowledge
//    SocketIOCallback cb = ^(id argsData) {
//        NSDictionary *response = argsData;
//        // do something with response
//        NSLog(@"ack arrived: %@", response);
    
        // test forced disconnect
//        [socketIO disconnectForced];
//    };
//    [socketIO sendMessage:@"hello back!" withAcknowledge:cb];
    //    [socketIO sendEvent:@"set_pic" withData:imagefilename];

    
    // test different event data types
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    [dict setObject:@"test1" forKey:@"key1"];
//    [dict setObject:@"test2" forKey:@"key2"];
//    [socketIO sendEvent:@"welcome" withData:dict];
    
//
//    NSArray *arr = [NSArray arrayWithObjects:@"test1", @"test2", nil];
//    [socketIO sendEvent:@"welcome" withData:arr];
    
//    [_container addSubview:_main_circle];
//    [self.view addSubview:_container];
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    if ([error code] == SocketIOUnauthorized) {
        NSLog(@"not authorized");
    } else {
        NSLog(@"onError() %@", error);
    }
    [_connectionStatus setText:@"Connection Status:\nUnknown Error"];
    
    // try to reconnect
    [socketIO connectToHost:@"127.0.0.1" onPort:3007];
    
//    Peer* thisPeer = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
//    Peer* thisPeer2 = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
//    Peer* thisPeer3 = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
//    Peer* thisPeer4 = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
//    Peer* thisPeer5 = [[Peer alloc] initWithFrame:CGRectMake(150, 150, 75, 75)];
//
//    peers[@"1"] = thisPeer;
//    peers[@"2"] = thisPeer2;
//    peers[@"3"] = thisPeer3;
//    peers[@"4"] = thisPeer4;
//    peers[@"5"] = thisPeer5;
//
//    
//    thisPeer.myVC = self;
//    thisPeer2.myVC = self;
//    thisPeer3.myVC = self;
//    thisPeer4.myVC = self;
//    thisPeer5.myVC = self;
//
//    
//    // add the view to the GUI
//    [[self view] addSubview:thisPeer];
//    [[self view] addSubview:thisPeer2];
//    [[self view] addSubview:thisPeer3];
//    [[self view] addSubview:thisPeer4];
//    [[self view] addSubview:thisPeer5];
//    
//    // set its information
//    thisPeer._id = @"1";
//    thisPeer2._id = @"2";
//    thisPeer3._id = @"3";
//    thisPeer4._id = @"4";
//    thisPeer5._id = @"5";
//
//    
//    // update peer information
//    thisPeer.pic = @"Zebra.tif.png";
//    [thisPeer setImageString:thisPeer.pic];
//    
//    // update peer information
//    thisPeer2.pic = @"Eagle.tif.png";
//    [thisPeer2 setImageString:thisPeer2.pic];
//    
//    // update peer information
//    thisPeer3.pic = @"Hockey.tif.png";
//    [thisPeer3 setImageString:thisPeer3.pic];
//    
//    // update peer information
//    thisPeer4.pic = @"Snowflake.tif.png";
//    [thisPeer4 setImageString:thisPeer4.pic];
//    
//    // update peer information
//    thisPeer5.pic = @"Guitar.tif.png";
//    [thisPeer5 setImageString:thisPeer5.pic];
}


- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"socket.io disconnected. did error occur? %@", error);
    [_connectionStatus setText:@"Connection Status:\nDisconnected"];
    
    // try to reconnect
    [socketIO connectToHost:@"127.0.0.1" onPort:3007];
}

# pragma mark -

- (void) viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _statusUpdater)
    {
        [socketIO sendEvent:@"set_status" withData: textField.text];
        [_statusMessage setText: textField.text];
        [textField resignFirstResponder];
        [textField setText:@""];

    }
    else if (textField == _typeBox)
    {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:textField.text forKey:@"message"];
        [dict setObject:[NSString stringWithFormat:@"%d",sendee] forKey:@"id"];
            [socketIO sendEvent:@"send_message" withData:dict];
        
        NSString *embedHTML = [NSString stringWithFormat:@"%@<br style='clear:both'/><div style='border-radius:20px 20px 20px 20px; background-color: #47a9ff; display:inline-block; float:right; font-family: Helvetica, arial, sans-serif; color: white; padding: 5px 10px'>%@</div>", [_chatHistory stringByEvaluatingJavaScriptFromString:@"document.body.outerHTML"], _typeBox.text];
        _heldPeer.convo = embedHTML;
        
        [_chatHistory loadHTMLString: embedHTML baseURL: nil];
        
        [textField setText:@""];
//        if(_chatHistory.text.length > 0 ) {
//            NSRange bottom = NSMakeRange(_chatHistory.text.length -1, 1);
//            [_chatHistory scrollRangeToVisible:bottom];
//        }

    }

    return YES;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    // get locaiton
    CLLocation *locationData = [locations lastObject];
    NSString* locationString = [NSString stringWithFormat:@"%f %f", locationData.coordinate.latitude, locationData.coordinate.longitude];

    // send location to server
    [socketIO sendEvent:@"set_coordinates" withData: locationString];

    // stop the locaiton daemon
//    [self.locationManager stopUpdatingLocation];
    [socketIO sendEvent:@"get_people" withData: @"testWithString"];
    
    // update the location debug string
    [_location setText:[NSString stringWithFormat:@"Current Location:\n%@", locationString]];
    
//    // animate main circle
//    [UIView animateWithDuration:1.0 animations:^{
//        _container.frame =  CGRectMake(_container.frame.origin.x, _container.frame.origin.y, 100, 100);}];
//    
//    // animate main circle
//    [UIView animateWithDuration:1.0 animations:^{
//        _main_circle.frame =  CGRectMake(_main_circle.frame.origin.x, _main_circle.frame.origin.y, 100, 100);}];
    
    //    NSLog(@"HERE'S THE THING lat%f - lon%f", location.coordinate.latitude, location.coordinate.longitude);
}

- (void)startConversationWith:(Peer*)friend {
    [UIView animateWithDuration:0.5 animations:^() {
        _dimmer.alpha = 0.55;
        _chatHistory.alpha = 1;
        _typeBox.alpha = 1;
        [_typeBox becomeFirstResponder];

    }];
    [self.view bringSubviewToFront: _dimmer];
    [self.view bringSubviewToFront: _typeBox];
    [self.view bringSubviewToFront: _chatHistory];
    [self.view bringSubviewToFront: _heldPeer];
    
//        [_chatHistory loadHTMLString: friend.convo baseURL: nil];

//    [_chatHistory setText:@"Chatting with a new partner\n"];
    sendee = [friend._id intValue];
}

- (void)endConversation {
    [UIView animateWithDuration:0.5 animations:^() {
        _dimmer.alpha = 0;
        _chatHistory.alpha = 0;
        _typeBox.alpha = 0;
    }];

    [self.view endEditing:YES];
    
    NSString *embedHTML = @"";
    [_chatHistory loadHTMLString: embedHTML baseURL: nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGPoint bottomOffset = CGPointMake(0, webView.scrollView.contentSize.height - webView.scrollView.bounds.size.height);
    [webView.scrollView setContentOffset:bottomOffset animated:NO];
}


- (IBAction)touchup:(id)sender {
 /*   if ((UIButton *)sender == _button1) {
        sendee = 1;
    }
    else if ((UIButton *)sender == _button2)
        sendee = 2;
    else 
  */
    if ((UIBarButtonItem *)sender == _msgicon)
    {
        [UIView animateWithDuration:0.5 animations:^() {
            _chatHistory.alpha = 0;
            _typeBox.alpha = 0;
        }];
        [self.view endEditing:YES];
        _heldPeer = nil;
        [self reflowPeers];
    }
}


@end
