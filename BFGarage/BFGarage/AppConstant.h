//
//  AppConstant.h
//  BFGarage






//本地文件存储路径
#define  GET_CACHE_DIR NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]

//提示框
#define BFALERT(msg) [[[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];


//上线配置项
#define ALL_SWITCH  0
#if (ALL_SWITCH == 1)
#define LOG_SWITCH       0          //PLog开关 0为关闭 1为开启
#else
#define LOG_SWITCH       1          //PLog 和 AHPLog开关 0为关闭 1为开启
#endif

//Log重定义
#if LOG_SWITCH
#define PLog(format, ...) NSLog(format, ## __VA_ARGS__)

#else
#define PLog(format, ...)

#endif

//激活设备成功通知
#define NSNOTIFICATION_CONNECTSUCCESS @"notification.connect.activitySuccess"



