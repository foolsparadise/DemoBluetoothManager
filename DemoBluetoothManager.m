//
//  DemoBluetoothManager
//  NULL
//
//  Created by foolsparadise on 23/6/2018.
//  Copyright © 2018 github.com/foolsparadise All rights reserved.
//

#import "DemoBluetoothManager.h"
#import "CoreBluetoothManager.h"

@interface DemoBluetoothManager()
@property(nonatomic,strong)CoreBluetoothManager *CoreManager;
+ (instancetype)shareInstance;
@end

@implementation DemoBluetoothManager

- (CoreBluetoothManager *)CoreManager
{
    dispatch_semaphore_t se = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(se, DISPATCH_TIME_FOREVER);
    if (_CoreManager == nil) {
        _CoreManager = [[CoreBluetoothManager alloc] init];
    }
    dispatch_semaphore_signal(se);
    return _CoreManager;
}

static DemoBluetoothManager *_instance = nil;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    }) ;
    
    return _instance;
}


#pragma mark - API
//[DemoBluetoothManager shareInstance].CoreManager

@end
