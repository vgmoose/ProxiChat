#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIImageView *main_circle;

@end

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
        if ([filenames[rando] hasSuffix:@".png"] && ![filenames[rando] hasSuffix:@"b_.png"])
            break;
    }
    
    NSLog(@"Ch0osen file is : %@", filenames[rando]);
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
    [socketIO connectToHost:@"localhost" onPort:3007];
}

# pragma mark -
# pragma mark socket.IO-objc delegate methods

- (void) socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"socket.io connected.");
    
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
    
    [socketIO sendEvent:@"set_status" withData: @"wasup"];
    [self.locationManager startUpdatingLocation];
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveEvent()");
    
    if ([packet.name isEqualToString:@"assign_id"])
    {
        _id = packet.args[0][@"id"];
        [[NSUserDefaults standardUserDefaults] setObject:_id forKey:@"userId"];
        NSLog(@"Got ID: %@", _id);
    }
    else if ([packet.name isEqualToString:@"new_people"])
    {
        NSLog(@"%@", packet.args);
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
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"test1" forKey:@"key1"];
    [dict setObject:@"test2" forKey:@"key2"];
    [socketIO sendEvent:@"welcome" withData:dict];
    
    [socketIO sendEvent:@"welcome" withData:@"testWithString"];
    
    NSArray *arr = [NSArray arrayWithObjects:@"test1", @"test2", nil];
    [socketIO sendEvent:@"welcome" withData:arr];
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    if ([error code] == SocketIOUnauthorized) {
        NSLog(@"not authorized");
    } else {
        NSLog(@"onError() %@", error);
    }
}


- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"socket.io disconnected. did error occur? %@", error);
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

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    [socketIO sendEvent:@"set_coordinates" withData: [NSString stringWithFormat:@"%f %f", location.coordinate.latitude, location.coordinate.longitude]];
    [self.locationManager stopUpdatingLocation];
    [socketIO sendEvent:@"get_people" withData: @"testWithString"];
//    [UIView animateWithDuration:1.0 animations:^{
//        _main_circle.frame =  CGRectMake(_main_circle.frame.origin.x, _main_circle.frame.origin.y, 150, 150);}];
//    NSLog(@"HERE'S THE THING lat%f - lon%f", location.coordinate.latitude, location.coordinate.longitude);
}

@end
