//
//  FirstViewController.m
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#import "FirstViewController.h"
#import "HomeTableCell.h"

@interface FirstViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *rootTableView;
@property (nonatomic, weak) IBOutlet UIImageView *animationView;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UINib *UserCenterLeftContentCellNib = [UINib nibWithNibName:@"HomeTableCell" bundle:nil];
    [self.rootTableView registerNib:UserCenterLeftContentCellNib forCellReuseIdentifier:@"HomeTableCellIdentifier"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectSuccess)
                                                 name:NSNOTIFICATION_CONNECTSUCCESS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadDevicelist)
                                                 name:NSNOTIFICATION_ACTIVITYSUCCESS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectFailed)
                                                 name:NSNOTIFICATION_CONNECTFAILED
                                               object:nil];
    
    
    
    if ([AppContext sharedAppContext].garageArray.count==0) {
        self.rootTableView.hidden = YES;
    }
    
    NSArray *imagesArray = [NSArray arrayWithObjects:
                            [UIImage imageNamed:@"open_0.png"],
                            [UIImage imageNamed:@"open_1.png"],
                            [UIImage imageNamed:@"open_2.png"],
                            [UIImage imageNamed:@"open_3.png"],
                            [UIImage imageNamed:@"open_4.png"],
                            [UIImage imageNamed:@"open_5.png"],
                            [UIImage imageNamed:@"open_6.png"],
                            [UIImage imageNamed:@"open_7.png"],
                            [UIImage imageNamed:@"open_8.png"],
                            [UIImage imageNamed:@"open_9.png"],
                            [UIImage imageNamed:@"open_10.png"],
                            [UIImage imageNamed:@"open_9.png"],
                            [UIImage imageNamed:@"open_8.png"],
                            [UIImage imageNamed:@"open_7.png"],
                            [UIImage imageNamed:@"open_6.png"],
                            [UIImage imageNamed:@"open_5.png"],
                            [UIImage imageNamed:@"open_4.png"],
                            [UIImage imageNamed:@"open_3.png"],
                            [UIImage imageNamed:@"open_2.png"],
                            [UIImage imageNamed:@"open_1.png"],
                            [UIImage imageNamed:@"open_0.png"],nil];
    _animationView.animationImages = imagesArray;//将序列帧数组赋给UIImageView的animationImages属性
    _animationView.animationDuration = 2.0;//设置动画时间
    _animationView.animationRepeatCount = 0;//设置动画次数 0 表示无限
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//刷新设备列表
- (void)reloadDevicelist{
    
    if ([AppContext sharedAppContext].garageArray.count>0) {
        self.rootTableView.hidden = NO;
        [self.rootTableView reloadData];
    }else{
        self.rootTableView.hidden = YES;
        [self.rootTableView reloadData];
    }
}

- (void)connectSuccess {
    [_animationView stopAnimating];//开始播放动画
    _animationView.hidden = YES;
}

- (void)connectFailed {
    [_animationView stopAnimating];//开始播放动画
    _animationView.hidden = YES;
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
    static NSString *cellIndentifierStr = @"HomeTableCellIdentifier";
    HomeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifierStr forIndexPath:indexPath];
    GarageModel *model = [AppContext sharedAppContext].garageArray[indexPath.row];
    cell.titleLabel.text = model.name ? model.name : model.macStr;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GarageModel *model = [AppContext sharedAppContext].garageArray[indexPath.row];
    [[AppContext sharedAppContext] connectGarage:model];
    
    _animationView.hidden = NO;
    [_animationView startAnimating];//开始播放动画
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
