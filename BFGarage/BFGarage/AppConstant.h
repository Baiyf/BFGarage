//
//  AppConstant.h
//  BFGarage
//
//  Created by baiyufei on 2017/4/23.
//  Copyright © 2017年 com.zhouqinghua. All rights reserved.
//

#define ALL_SWITCH  0

#if (ALL_SWITCH == 1)
    #define LOG_SWITCH       0          //PLog开关 0为关闭 1为开启
#else
    #define LOG_SWITCH       1          //PLog 和 AHPLog开关 0为关闭 1为开启
#endif



#define  GET_CACHE_DIR NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]


#if LOG_SWITCH
#define PLog(format, ...) NSLog(format, ## __VA_ARGS__)

#else
#define PLog(format, ...)

#endif
