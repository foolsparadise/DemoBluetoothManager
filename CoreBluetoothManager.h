//
//  CoreBluetoothManager
//  NULL
//
//  Created by foolsparadise on 23/6/2018.
//  Copyright © 2018 github.com/foolsparadise All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

//蓝牙相关
#define Device_Service_UUID                            @"xxxx" //服务ID
#define Device_Read_UUID                               @"xxxx" //读的ID(read)
#define Device_Write_UUID                              @"xxxx" //管理的ID(write)

/**
 Usage:
 
 [[CoreBluetoothManager shareInstance] startScan]; //开启蓝牙广播
 [CoreBluetoothManager shareInstance].delegate = self;
 - (void)addCBPeripheral2Array:(CBPeripheral *)cperip
 {
 }
 - (void)showCBCentralListView
 {
 }
 - (void)showNotFoundCBPeripheralView
 {
 //已经被系统或者其他APP连接上的设备数组
 NSArray *arrr = [[CoreBluetoothManager shareInstance].centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:Device_Service_UUID]]];
 NSLog(@"showNotFoundCBPeripheralView===%@  count:%lu", arrr, (unsigned long)arrr.count);
 NSString * savedUUID; //之前点击确认要连接的蓝牙设备的
 [[CoreBluetoothManager shareInstance] reconnectedPeripheral:savedUUID];

 }
 //向蓝牙发送数据
 CoreBluetoothManager *bluetoothManager = [CoreBluetoothManager shareInstance];
 [bluetoothManager sendHello];
 [bluetoothManager.centralManager connectPeripheral:self.peripheral options:nil];
 [bluetoothManager setIsConnected:YES];
 */
@protocol CoreBluetoothManagerDelegate <NSObject>
@optional
- (void)addCBPeripheral2Array:(CBPeripheral *)cperip;
- (void)showCBCentralListView;
- (void)showNotFoundCBPeripheralView;
@end

@interface CoreBluetoothManager : NSObject
@property (nonatomic, weak)   id <CoreBluetoothManagerDelegate> delegate;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBCharacteristic *characteristics;
@property (nonatomic, strong) CBPeripheral     *peripheral;
@property (nonatomic, assign) BOOL             isConnected;

+ (instancetype)shareInstance;

- (void)sendHello; //only for test
- (void)reconnectedPeripheral:(NSString *)savedUUID;

@end

NS_ASSUME_NONNULL_END
