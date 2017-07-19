
//上线配置项
#define ALL_SWITCH  1
#if (ALL_SWITCH == 1)
#define LOG_SWITCH       0          //PLog开关 0为关闭 1为开启
#else
#define LOG_SWITCH       1          //PLog 和 AHPLog开关 0为关闭 1为开启
#endif

//在LogView中输入Log
#if LOG_SWITCH
#define BFLog(format, ...) [[AppContext sharedAppContext].logView setLog:[NSString stringWithFormat:format, ##__VA_ARGS__]]

#else
#define BFLog(format, ...)

#endif

//----------------------------------------------------------------------------

//本地文件存储路径
#define  GET_CACHE_DIR NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]

//提示框
#define BFALERT(msg) [[[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil, nil] show];

//购买链接
#define URL_BUY @"https://www.amazon.com/dp/B073P3VS3K/ref=olp_product_details/145-0881945-7442921?_encoding=UTF8&me="

//设备开锁成功通知
#define NSNOTIFICATION_CONNECTSUCCESS @"notification.connect.connectsuccess"
//激活设备成功通知
#define NSNOTIFICATION_ACTIVITYSUCCESS @"notification.connect.activitysuccess"
//设备开锁失败通知
#define NSNOTIFICATION_CONNECTFAILED @"notification.connect.connectfailed"


