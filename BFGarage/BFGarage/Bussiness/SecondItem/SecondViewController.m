//
//  SecondViewController.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "SecondViewController.h"
#import "DeviceTableViewCell.h"
#import "ScanViewController.h"

@interface SecondViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, weak) IBOutlet UIButton *linkButton;
@property(nonatomic, weak) IBOutlet UIButton *scanButton;

@property(nonatomic, weak) IBOutlet UITableView *rootTableView;
@property(nonatomic, strong) NSIndexPath *selectIndex;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UINib *UserCenterLeftContentCellNib = [UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil];
    [self.rootTableView registerNib:UserCenterLeftContentCellNib forCellReuseIdentifier:@"DeviceTableViewCellIdentifier"];
    
    self.navigationItem.title = @"Setting";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadDevicelist)
                                                 name:NSNOTIFICATION_ACTIVITYSUCCESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectFailed)
                                                 name:NSNOTIFICATION_CONNECTFAILED
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

//激活失败
- (void)connectFailed {
//    [_animationView stopAnimating];//开始播放动画
//    _animationView.hidden = YES;
}

#pragma mark - button actions
//激活操作
- (IBAction)activityConnect:(id)sender {
    [[AppContext sharedAppContext] connectGarage:nil];
}

//二维码扫描
- (IBAction)scanQRCode:(id)sender {
    ScanViewController *scanVC = [[ScanViewController alloc] init];
    [self.navigationController pushViewController:scanVC animated:YES];
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
    cell.titleLabel.text = model.name ? model.name : model.macStr;
    cell.cellIndex = indexPath;
    __weak typeof(self) weakSelf = self;
    [cell setQrBlock:^(NSIndexPath *cellIndex){
        weakSelf.selectIndex = cellIndex;
        [weakSelf showQRView];
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle==UITableViewCellEditingStyleDelete)
    {
        // 删除数据的操作
        [[AppContext sharedAppContext] deleteGarage:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNOTIFICATION_ACTIVITYSUCCESS object:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Garage Name" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *txtName = [alert textFieldAtIndex:0];
    txtName.placeholder = @"Please enter name";
    [alert show];
    
    self.selectIndex = indexPath;
}

#pragma mark - UIAlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        UITextField *txt = [alertView textFieldAtIndex:0];
        //获取txt内容即可
        GarageModel *model = [AppContext sharedAppContext].garageArray[self.selectIndex.row];
        model.name = txt.text;
        [[AppContext sharedAppContext] addNewGarage:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNOTIFICATION_ACTIVITYSUCCESS object:nil];
    }
}

//显示二维码生成页面
- (void)showQRView {
    BFALERT(@"显示二维码页面");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
