# MyCoreBluetoothDemo

一个在“BlueNRG”蓝牙设备下 测试写的一个连接外设的Demo 
实时读取“BlueNRG”外设的数据


主要步骤：

·1首先利用CoreBluetooth框架下的CBCentralManager进行扫描，一旦发现外设名为“BlueNRG”的设备，马上开始连接。

·2连接上外设（perapheral）之后，扫描外设中的服务，拿到需要的服务(service)。

·3对拿到的服务，服务中有多个特征（characteristic），对这些characteristic进行遍历，拿到我们需要拿到的characteristic。

·4最后就是读取characteristic中的数据，读取数据有两种方式，详情见demo或者apple lib。

·5对拿到的数据进行解析，解析数据根据不同的外设数据解析协议进行。

·6数据显示与更新。
