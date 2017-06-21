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

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *nodeviceImageWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *nodeviceImageHeight;

@property (nonatomic, weak) IBOutlet UITableView *rootTableView;
@property (nonatomic, weak) IBOutlet UIImageView *animationView;

@property (nonatomic, strong) NSTimer *openTimer;
@property (nonatomic, assign) BOOL enableOpen;
@end

@implementation FirstViewController
@synthesize openTimer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.enableOpen = YES;
    
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
                                             selector:@selector(connectFailed:)
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
    _animationView.animationImages = imagesArray;   //将序列帧数组赋给UIImageView的animationImages属性
    _animationView.animationDuration = 2.0;         //设置动画时间
    _animationView.animationRepeatCount = 0;        //设置动画次数 0 表示无限
    
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.nodeviceImageWidth.constant = 200;
        self.nodeviceImageHeight.constant = 210;
    }
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

#pragma mark - 连接结果通知
//蓝牙连接成功
- (void)connectSuccess {
    [_animationView stopAnimating];//停止播放动画
    _animationView.hidden = YES;
}
//蓝牙连接失败
- (void)connectFailed:(NSNotification *)notification {
    [_animationView stopAnimating];//停止播放动画
    _animationView.hidden = YES;
    if (self.tabBarController.selectedIndex == 0 && self.navigationController.visibleViewController == self) {
        if ([notification.object isKindOfClass:[NSString class]]) {
            NSString *alert = notification.object;
            BFALERT(alert);
        }else {
            BFALERT(@"Can not find the device");
        }
    }
    
    //打开开关
    [self openEnabled];
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
    if (!self.enableOpen) {
        return;
    }
    
    _animationView.hidden = NO;
    [_animationView startAnimating];//开始播放动画
    
    GarageModel *model = [AppContext sharedAppContext].garageArray[indexPath.row];
    [[AppContext sharedAppContext] connectGarage:model];
    
    [self startOpenTimer];
}

//开始计时，防止4秒内重复点击
- (void)startOpenTimer {
    self.enableOpen = NO;
    if (openTimer) {
        [openTimer invalidate];
        openTimer = nil;
    }
    
    //开一个定时器监控连接超时的情况
    openTimer = [NSTimer scheduledTimerWithTimeInterval:4.0f
                                                    target:self
                                                  selector:@selector(openEnabled)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)openEnabled {
    self.enableOpen = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
