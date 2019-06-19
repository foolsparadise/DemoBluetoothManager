//
//  CoreBluetoothManager
//  NULL
//
//  Created by foolsparadise on 23/6/2018.
//  Copyright © 2018 github.com/foolsparadise All rights reserved.
//

#import "CoreBluetoothManager.h"

@interface CoreBluetoothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>{
    CBCharacteristic *datachar;
}
@property (nonatomic, strong) NSTimer *countdownTimer; //倒计时，重试次数
@property (nonatomic, assign) float countdowns15;
@property (nonatomic, strong) NSMutableData *Datas2BLE;

@end

@implementation CoreBluetoothManager

static CoreBluetoothManager *_instance = nil;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    }) ;
    
    return _instance;
}


- (id)init{
    self = [super init];
    if (self) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

+ (BOOL)isConnected{
    return [CoreBluetoothManager shareInstance].isConnected;
}

+ (void)setConnected:(BOOL)isconnected{
    [CoreBluetoothManager shareInstance].isConnected = isconnected;
}

- (void)sendHello {
    Byte flag  = 0x1a;
    char chars[128] = "hello";
    Byte charsLength = strlen(chars);
    self.Datas2BLE = nil;
    self.Datas2BLE = [[NSMutableData alloc] initWithBytes:&flag length:1];
    [self.Datas2BLE appendBytes:&charsLength length:1];
    [self.Datas2BLE appendBytes:chars length:charsLength];
    char *tmpstr = (char *)[self.Datas2BLE bytes];
    NSLog(@"写入char:%s", tmpstr);
    NSLog(@"写入data:%@", self.Datas2BLE);
}

- (void)startScan {
    [self stopScan];
    [self cleanup];
    //[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:Device_Service_UUID]]  options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:NO]}];
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:Device_Service_UUID]]  options:nil];
    [self stopcountdownTimer];
    self.countdowns15 = 0;
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.countdownTimer forMode:NSRunLoopCommonModes];
}

- (void)stopScan {
    if (self.centralManager)
        [self.centralManager stopScan];
}

- (void)stopcountdownTimer {
    if (self.countdownTimer) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
    }
}

- (void)countdownTimerAction{
    self.countdowns15 += 1;
    if (self.countdowns15 == 15) {
        [self.centralManager stopScan];
        [self.delegate showNotFoundCBPeripheralView];
        [self stopcountdownTimer];
    }
}
- (void)cleanup
{
    if(self.peripheral.state != CBPeripheralStateConnected) return;
    //if (self.peripheral.services != nil)
    {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:Device_Service_UUID]])
                    {
                        if (characteristic.isNotifying) {
                            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
}
- (void)cancelConnectPeripheral {
    [self stopScan];
    [self cleanup];
    [self stopcountdownTimer];
    if (self.peripheral) {
        NSLog(@"取消ble连接：%@",self.peripheral.name);
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
    self.peripheral = nil;
}

- (void)connectPeripheral:(CBPeripheral *)peripheral{
    self.peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES}];
}
- (void)reconnectedPeripheral:(NSString *)savedUUID
{
    NSUUID *res = [[NSUUID alloc] initWithUUIDString:savedUUID];
    NSArray *arr2 = [[CoreBluetoothManager shareInstance].centralManager retrievePeripheralsWithIdentifiers:@[res]];
    NSLog(@"%@", arr2);
    for (CBPeripheral *peripheral in arr2) {
        [self.delegate addCBPeripheral2Array:peripheral];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopcountdownTimer];
            [self.centralManager stopScan];
            [self.delegate showCBCentralListView];
        });
        break;
        
    }
    
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSString *message = nil;
    switch (central.state) {
            /*
             typedef NS_ENUM(NSInteger, CBManagerState) {
             CBManagerStateUnknown = 0,
             CBManagerStateResetting,
             CBManagerStateUnsupported,
             CBManagerStateUnauthorized,
             CBManagerStatePoweredOff,
             CBManagerStatePoweredOn,
             } NS_ENUM_AVAILABLE(10_13, 10_0);
             */
        case 1:
            message = @"该设备不支持蓝牙功能,请检查系统设置";
            break;
        case 2:
            message = @"该设备蓝牙未授权,请检查系统设置";
            break;
        case 3:
            message = @"该设备蓝牙未授权,请检查系统设置";
            break;
        case 4:
        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                _bleAlerView = [[UIAlertView alloc] initWithTitle:nil message:@"蓝牙未开启或者未授权,请重新打开屏幕下方控制板的蓝牙图标" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//                [_bleAlerView show];
//            });
        }
            break;
        case 5:{
            message = @"蓝牙已经成功开启,请稍后再试";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[CoreBluetoothManager shareInstance] startScan];
            });
        }
            break;
        default:
            break;
    }
    if(message!=nil&&message.length!=0)
    {
        NSLog(@"message == %@",message);
    }
}

//查到外设后，停止扫描，连接设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@",[NSString stringWithFormat:@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ \n", peripheral, RSSI, peripheral.identifier, advertisementData]);
    // Match if we have this device from before
    
    NSString *bluetoothName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSRange range = [bluetoothName rangeOfString:@"@" options:NSBackwardsSearch];
    if (range.location != NSNotFound && bluetoothName != nil) {
    }
    
    [self.delegate addCBPeripheral2Array:peripheral];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopcountdownTimer];
        [self.centralManager stopScan];
        [self.delegate showCBCentralListView];
    });
    
}

//连接外设成功，开始发现服务
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@", [NSString stringWithFormat:@"成功连接 peripheral: %@ with UUID: %@",peripheral,peripheral.identifier]);
    [self.peripheral setDelegate:self];
    
    CBUUID    *serviceUUID    = [CBUUID UUIDWithString:Device_Service_UUID];
    NSArray    *serviceArray    = [NSArray arrayWithObjects:serviceUUID, nil];
    [peripheral discoverServices:serviceArray];
    
    self.isConnected = YES;
}

//连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接外设失败:%@",error);
    self.isConnected = NO;
}

//已发现服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    for (CBService *service in peripheral.services) {
        NSLog(@"se5vice uuid %@", service.UUID);
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:Device_Service_UUID]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

//已搜索到Characteristics
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *c in service.characteristics) {
        NSLog(@"sevicc uuid %@", c.UUID);
        if ([c.UUID isEqual:[CBUUID UUIDWithString:Device_Write_UUID]]) {
            self.characteristics = c;
            [peripheral writeValue:self.Datas2BLE forCharacteristic:self.characteristics type:CBCharacteristicWriteWithResponse];
        }
        if ([c.UUID isEqual:[CBUUID UUIDWithString:Device_Read_UUID]]) {
            datachar = c;
            NSLog(@"完成后读取连接状态:%@",datachar);
            [peripheral setNotifyValue:YES forCharacteristic:datachar];
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    [self cancelConnectPeripheral];
    NSLog(@"centralManager掉线:%@\n",error);
    if(error)
    {
        NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
}

//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:Device_Read_UUID]]) {//read
        
        NSData * data = characteristic.value;
        NSLog(@"读取外设数据value:%@",characteristic);
        if(data)
        {
            Byte *resultByte = (Byte *)[data bytes];
            NSLog(@"读取外设数据结果:%s",resultByte);
            NSString *resultStr = [NSString stringWithFormat:@"%s",resultByte];
            if ([resultStr isEqualToString:@"false"]) {
                NSLog(@"写入外设失败");
                self.isConnected = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBPeripheral_Connect_Fail" object:nil];
            }
        }
        
    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"向外设写数据失败:%@\n",error);
    } else
        NSLog(@"向外设写数据成功\n");
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"读取外设数据notify失败");
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:Device_Read_UUID]]) { //read
        NSLog(@"读取外设数据notify:%@",characteristic);
    }
    
}


@end
