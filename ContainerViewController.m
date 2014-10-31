//
//  ContainerViewController.m
//  Proxi
//
//  Created by Ricky Ayoub on 10/31/14.
//  Copyright (c) 2014 beta_interactive. All rights reserved.
//

#import "ContainerViewController.h"

@interface ContainerViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *main_circle;

@end

@implementation ContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    //
    // the image we're going to mask and shadow
    UIImageView* image = _main_circle;
    [image setImage:[UIImage imageNamed:filenames[rando]]];
    ////    image.center = self.view.center;
    // use the image's layer to mask the image into a circle
    image.layer.cornerRadius = roundf(image.frame.size.width/2.0);
    image.layer.masksToBounds = YES;
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
