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
@property (weak, nonatomic) IBOutlet UITextView *chatHistory;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *msgicon;

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

    
    [_statusMessage setText:@""];
//    [_status1 setText:@""];
//    [_status2 setText:@""];
    
    [_chatHistory setHidden:true];
    [_typeBox setHidden:true];
    
    // create the peer mutable array
    peers = [NSMutableArray init];
    
    
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
    
    NSLog(@"Ch0osen file is : %@", filenames[rando]);
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
    
    // try to load an ID (defaults to zero)
    _id = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    
    // connect to the socket.io server that is running locally at port 3000
    [socketIO connectToHost:@"127.0.0.1" onPort:3007];
    


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
    
    [self.locationManager startUpdatingLocation];
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
                Peer* thisPeer = [Peer init];
                peers[thisID] = thisPeer;
                
                // set its information
                thisPeer._id = thisID;
            }
            
            // update peer information
            thisPeer.status = packet.args[0][x][@"status"];
            thisPeer.pic = packet.args[0][x][@"pic"];
        }
        
        [_peopleCounter setText:[NSString stringWithFormat:@"People Nearby:\n%d", [packet.args[0] count]]];
        
    }
    else if ([packet.name isEqualToString:@"get_message"])
    {
        NSLog(@"NONOONON: %@", packet.args);
           [_chatHistory setText:[NSString stringWithFormat:@"%@\nThem: %@",_chatHistory.text, packet.args[0][@"msg"]]];
        if(_chatHistory.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_chatHistory.text.length -1, 1);
            [_chatHistory scrollRangeToVisible:bottom];
        }
    }

    
    // test acknowledge
    SocketIOCallback cb = ^(id argsData) {
        NSDictionary *response = argsData;
        // do something with response
        NSLog(@"ack arrived: %@", response);
        
        // test forced disconnect
        [socketIO disconnectForced];
    };
    [socketIO sendMessage:@"hello back!" withAcknowledge:cb];
    
    // test different event data types
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    [dict setObject:@"test1" forKey:@"key1"];
//    [dict setObject:@"test2" forKey:@"key2"];
//    [socketIO sendEvent:@"welcome" withData:dict];
    
    [socketIO sendEvent:@"set_pic" withData:imagefilename];
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
        [_chatHistory setText:[NSString stringWithFormat:@"%@\nYou: %@",_chatHistory.text, _typeBox.text]];
        [textField setText:@""];
        if(_chatHistory.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_chatHistory.text.length -1, 1);
            [_chatHistory scrollRangeToVisible:bottom];
        }

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
- (IBAction)touchup:(id)sender {
    [_chatHistory setHidden:false];
    [_chatHistory setText:@"Chatting with a new partner\n"];
    [_typeBox setHidden:false];
 /*   if ((UIButton *)sender == _button1) {
        sendee = 1;
    }
    else if ((UIButton *)sender == _button2)
        sendee = 2;
    else 
  */
    if ((UIBarButtonItem *)sender == _msgicon)
    {
        [_chatHistory setHidden:true];
        [self.view endEditing:YES];
        [_typeBox setHidden:true];
    }
}


@end
