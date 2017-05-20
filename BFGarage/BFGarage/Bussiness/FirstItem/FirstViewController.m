//
//  FirstViewController.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "FirstViewController.h"
#import "DeviceTableViewCell.h"

@interface FirstViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, weak) IBOutlet UITableView *rootTableView;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UINib *UserCenterLeftContentCellNib = [UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil];
    [self.rootTableView registerNib:UserCenterLeftContentCellNib forCellReuseIdentifier:@"DeviceTableViewCellIdentifier"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadDevicelist)
                                                 name:NSNOTIFICATION_CONNECTSUCCESS
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//刷新设备列表
- (void)reloadDevicelist{
    [self.rootTableView reloadData];
}

#pragma mark - UITableViewDelegate & UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [AppContext sharedAppContext].garageArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIndentifierStr = @"DeviceTableViewCellIdentifier";
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifierStr forIndexPath:indexPath];
    GarageModel *model = [AppContext sharedAppContext].garageArray[indexPath.row];
    cell.textLabel.text = model.macStr;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GarageModel *model = [AppContext sharedAppContext].garageArray[indexPath.row];
    [[AppContext sharedAppContext] connectGarage:model];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
