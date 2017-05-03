//
//  ViewController.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/20.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) UITabBarController *tabBarController;
@end

@implementation ViewController
@synthesize tabBarController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (!tabBarController) {
        tabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RootTabBarController"];
        [self.view addSubview:tabBarController.view];
        [self addChildViewController:tabBarController];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
