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
#import <CoreImage/CoreImage.h>

@interface SecondViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIButton *linkButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *linkButtonWidth;
@property (nonatomic, weak) IBOutlet UIButton *scanButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *scanButtonWidth;

@property (nonatomic, weak) IBOutlet UITableView *rootTableView;

// 二维码页面
@property (nonatomic, weak) IBOutlet UIView *qrTipsView;
@property (nonatomic, weak) IBOutlet UIImageView *qrImageView;
// 激活提示页面
@property (nonatomic, weak) IBOutlet UIView *activityTipsView;

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
                                             selector:@selector(connectFailed:)
                                                 name:NSNOTIFICATION_CONNECTFAILED
                                               object:nil];
    
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.linkButtonWidth.constant = 140;
        self.scanButtonWidth.constant = 140;
    }
}

//刷新设备列表
- (void)reloadDevicelist{
    [self.rootTableView reloadData];
    
    self.activityTipsView.hidden = YES;
}

//激活失败
- (void)connectFailed:(NSNotification *)notification {
    self.activityTipsView.hidden = YES;
    if (self.tabBarController.selectedIndex == 1 && self.navigationController.visibleViewController == self) {
        if ([notification.object isKindOfClass:[NSString class]]) {
            NSString *alert = notification.object;
            BFALERT(alert);
        }else {
            BFALERT(@"Application could not find any new devices for pairing.\n Some devices may requirefactory reset before it can be activited.");
        }
    }
}

#pragma mark - button actions
//激活操作
- (IBAction)activityConnect:(id)sender {
    self.activityTipsView.hidden = NO;
    
    [[AppContext sharedAppContext] connectGarage:nil];
}

//二维码扫描
- (IBAction)scanQRCode:(id)sender {
    ScanViewController *scanVC = [[ScanViewController alloc] init];
    scanVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:scanVC animated:YES];
}

//点击取消QR页面
- (IBAction)dismissQRView:(id)sender {
    self.qrTipsView.hidden = YES;
}

//点击取消激活提示页面
- (IBAction)dismissActivityView:(id)sender {
    self.activityTipsView.hidden = YES;
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
        [weakSelf showQRAlertView];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Garage Name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    alert.tag = 80;
    UITextField *txtName = [alert textFieldAtIndex:0];
    txtName.placeholder = @"Please enter name";
    [alert show];
    
    self.selectIndex = indexPath;
}

#pragma mark - UIAlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 80) {
        if (buttonIndex == 1) {
            UITextField *txt = [alertView textFieldAtIndex:0];
            //获取txt内容即可
            GarageModel *model = [AppContext sharedAppContext].garageArray[self.selectIndex.row];
            model.name = txt.text;
            [[AppContext sharedAppContext] addNewGarage:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNOTIFICATION_ACTIVITYSUCCESS object:nil];
        }
    }
    else {
        if (buttonIndex == 1) {
            [self showQRView];
        }
    }
}

- (void)showQRAlertView {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please pay attention to the protection of the QR code in order to avoid the loss of your property." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
    alert.tag = 81;
    [alert show];
}

//显示二维码生成页面
- (void)showQRView {
    GarageModel *model = [AppContext sharedAppContext].garageArray[self.selectIndex.row];
    
    // 1. 创建一个二维码滤镜实例(CIFilter)
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];
    
    // 2. 给滤镜添加数据
    NSString *secretString = [NSString stringWithFormat:@"%@",model.secretKey2];
    NSDictionary *infoDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             model.name, @"name",
                             model.macStr, @"macStr",
                             secretString, @"secretKey2", nil];
    NSData *data =    [NSJSONSerialization dataWithJSONObject:infoDic options:NSJSONWritingPrettyPrinted error:nil];
    // 3.使用KVC的方式给filter赋值
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4. 生成二维码
    CIImage *image = [filter outputImage];
    
    // 5. 显示二维码
    self.qrImageView.image = [self excludeFuzzyImageFromCIImage:image size:200];
    
    self.qrTipsView.hidden = NO;
}

#pragma mark -- 对图像进行清晰处理，很关键！
- (UIImage *)excludeFuzzyImageFromCIImage:(CIImage *)image size:(CGFloat)size

{
    CGRect extent = CGRectIntegral(image.extent);
    
    //通过比例计算，让最终的图像大小合理（正方形是我们想要的）
    CGFloat scale = MIN(size / CGRectGetWidth(extent), size / CGRectGetHeight(extent));
    
    size_t width = CGRectGetWidth(extent) * scale;
    
    size_t height = CGRectGetHeight(extent) * scale;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
    
    CIContext * context = [CIContext contextWithOptions: nil];
    
    CGImageRef bitmapImage = [context createCGImage: image fromRect: extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    
    CGContextScaleCTM(bitmapRef, scale, scale);
    
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    //切记ARC模式下是不会对CoreFoundation框架的对象进行自动释放的，所以要我们手动释放
    CGContextRelease(bitmapRef);
    
    CGImageRelease(bitmapImage);
    
    CGColorSpaceRelease(colorSpace);
    
    return [UIImage imageWithCGImage: scaledImage];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


