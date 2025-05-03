//
//  ViewController.m
//  FlutterHybridiOS
//
//  Created by cherych on 2025/5/2.
//

#import "ViewController.h"
#import <Flutter/Flutter.h>
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)popToFlutterPage:(id)sender {
//    FlutterViewController* flutterViewController = [[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
////        [GeneratedPluginRegistrant registerWithRegistry:flutterViewController];  //如果使用了插件
//        [flutterViewController setInitialRoute:@"myApp"];
//        [self.navigationController pushViewController:flutterViewController animated:YES];
    
    FlutterEngine *flutterEngine = [(AppDelegate *)[[UIApplication sharedApplication] delegate] flutterEngine];
        FlutterViewController *flutterViewController = [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
        [self.navigationController pushViewController:flutterViewController animated:YES];
}

@end
