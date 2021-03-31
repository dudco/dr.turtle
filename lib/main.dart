import 'dart:async';
import 'dart:io';

import 'package:flex_ble/faq.dart';
import 'package:flex_ble/option.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      home: MyHomePage(title: 'Flutter BLE Demo Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BleManager _bleManager = BleManager();
  bool _isScanning = false;
  bool _connected = false;
  bool _isListened = false;
  Peripheral _curPeripheral; // 연결된 장치 변수
  BleDeviceItem device;
  int badNumber = 0;
  String currentPosture = "general";

  final connectedSnackBar = SnackBar(
      content: Text("Dr.Turtle 디바이스와 연결되었습니다!"),
      backgroundColor: Colors.lightGreen);
  final disconnectedSnackBar = SnackBar(
      content: Text("Dr.Turtle 디바이스와 연결이 해제 되었습니다."),
      backgroundColor: Colors.red);
  final scanningSnackBar =
      SnackBar(content: Text("Dr.Turtle 디바이스를 찾는 중입니다..."));
  final warningSnackBar = SnackBar(
      content: Text("현재 자세가 위험합니다!"),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating);
  final dangerSnackBar = SnackBar(
      content: Text("현재 자세가 좋지않습니다!"),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating);
  final generalSnackBar = SnackBar(
      content: Text("현재 자세를 유지해주세요!"),
      backgroundColor: Colors.lightGreen,
      behavior: SnackBarBehavior.floating);

  @override
  void initState() {
    super.initState();
    this.init();
  }

  // BLE 초기화 함수
  void init() async {
    //ble 매니저 생성
    try {
      await _bleManager.createClient();
      _checkPermissions();
      scan();
    } catch (e) {
      print(e);
    }
  }

  // 권한 확인 함수 권한 없으면 권한 요청 화면 표시, 안드로이드만 상관 있음
  _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.contacts.request().isGranted) {}
      Map<Permission, PermissionStatus> statuses =
          await [Permission.location].request();
      print(statuses[Permission.location]);
    }
  }

  //scan 함수
  void scan() async {
    if (!_isScanning) {
      ScaffoldMessenger.of(context).showSnackBar(scanningSnackBar);

      //SCAN 시작
      _bleManager
          .startPeripheralScan(scanMode: ScanMode.balanced)
          .listen((scanResult) {
        //listen 이벤트 형식으로 장치가 발견되면 해당 루틴을 계속 탐.
        //periphernal.name이 없으면 advertisementData.localName 확인 이것도 없다면 unknown으로 표시

        print(
            "Scanned Peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}, Identifier ${scanResult.peripheral.identifier}");
        if (scanResult.peripheral.name == "Arduino" ||
            scanResult.peripheral.identifier ==
                "D7025D22-10F6-6588-CBD3-4FEA1ACA0C1E") {
          device = BleDeviceItem(scanResult.peripheral.name, scanResult.rssi,
              scanResult.peripheral, scanResult.advertisementData);
          connect(device);
          _bleManager.stopPeripheralScan();
          _isScanning = false;
        }
        //페이지 갱신용
        setState(() {});
      });
      setState(() {
        //BLE 상태가 변경되면 화면도 갱신
        _isScanning = true;
      });
    } else {
      //스켄중이었으면 스캔 중지
      _bleManager.stopPeripheralScan();
      setState(() {
        //BLE 상태가 변경되면 페이지도 갱신
        _isScanning = false;
      });
    }
  }

  //BLE 연결시 예외 처리를 위한 래핑 함수
  _runWithErrorHandling(runFunction) async {
    try {
      await runFunction();
    } on BleError catch (e) {
      print("BleError caught: ${e.errorCode.value} ${e.reason}");
    } catch (e) {
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      print("${e.runtimeType}: $e");
    }
  }

  //연결 함수
  connect(BleDeviceItem device) async {
    if (_connected) {
      //이미 연결상태면 연결 해제후 종료
      await _curPeripheral?.disconnectOrCancelConnection();
      return;
    }

    //선택한 장치의 peripheral 값을 가져온다.
    Peripheral peripheral = device.peripheral;

    if (!_isListened) {
      _isListened = true;
      //해당 장치와의 연결상태를 관촬하는 리스너 실행
      peripheral.observeConnectionState().listen((connectionState) {
        // 연결상태가 변경되면 해당 루틴을 탐.
        switch (connectionState) {
          case PeripheralConnectionState.connected:
            {
              _connected = true;
              print('connected');
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(connectedSnackBar);
              setState(() {});
            }
            break;
          case PeripheralConnectionState.disconnected:
            {
              _connected = false;
              print('disconnected');
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(disconnectedSnackBar);
              setState(() {});
            }
            break;
          default:
            {
              print("unkown connection state is: \n $connectionState");
            }
            break;
        }
      });
    }

    _runWithErrorHandling(() async {
      //해당 장치와 이미 연결되어 있는지 확인
      bool isConnected = await peripheral.isConnected();
      if (isConnected) {
        print('device is already connected');
        //이미 연결되어 있기때문에 무시하고 종료..
        return;
      }

      //연결 시작!
      await peripheral.connect().then((_) {
        //연결이 되면 장치의 모든 서비스와 캐릭터리스틱을 검색한다.
        peripheral
            .discoverAllServicesAndCharacteristics()
            .then((_) => peripheral.services())
            .then((services) async {
          print("PRINTING SERVICES for ${peripheral.name}");
          //각각의 서비스의 하위 캐릭터리스틱 정보를 디버깅창에 표시한다.
          for (var service in services) {
            print("Found service ${service.uuid}");
            List<Characteristic> characteristics =
                await service.characteristics();
            for (var characteristic in characteristics) {
              print("${characteristic.uuid}");
            }
          }
          //모든 과정이 마무리되면 연결되었다고 표시
          _connected = true;
          print("${peripheral.name} has CONNECTED");

          var characteristicUpdates = peripheral.monitorCharacteristic(
              "00001101-0000-1000-8000-00805f9b34fb",
              "00002101-0000-1000-8000-00805f9b34fb");

          //데이터 받는 리스너 핸들 변수
          StreamSubscription monitoringStreamSubscription;

          //이미 리스너가 있다면 취소
          await monitoringStreamSubscription?.cancel();
          monitoringStreamSubscription = characteristicUpdates.listen(
            (value) {
              print("read data: ${value.value}"); //데이터 출력
              if (value.value[0] <= 40) {
                if (currentPosture != "danger") {
                  badNumber += 1;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(dangerSnackBar);
                }
                currentPosture = "danger";
              } else {
                if (currentPosture != "general") {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(generalSnackBar);
                }
                currentPosture = "general";
              }
              setState(() {});
            },
            onError: (error) {
              print("Error while monitoring characteristic \n$error"); //실패시
            },
            cancelOnError: true, //에러 발생시 자동으로 listen 취소
          );
        });
      });
    });
  }

  _launchURL() async {
    if (Platform.isIOS) {
      if (await canLaunch('youtube://www.youtube.com/watch?v=rAA_jAOuhWE')) {
        await launch('youtube://www.youtube.com/watch?v=rAA_jAOuhWE',
            forceSafariVC: false);
      } else {
        if (await canLaunch('https://www.youtube.com/watch?v=rAA_jAOuhWE')) {
          await launch('https://www.youtube.com/watch?v=rAA_jAOuhWE');
        } else {
          throw 'Could not launch https://www.youtube.com/watch?v=rAA_jAOuhWE';
        }
      }
    } else {
      const url = 'https://www.youtube.com/watch?v=rAA_jAOuhWE';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  //페이지 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: !_connected && !_isScanning
          ? FloatingActionButton(
              onPressed: () {
                scan();
              },
              backgroundColor: Colors.pinkAccent,
              child: const Icon(Icons.search),
            )
          : null,
      body: SafeArea(
        child: Container(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "오늘의 나의 자세 지수는?",
                          style: TextStyle(fontFamily: 'Jalnan'),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "나쁜자세 $badNumber회",
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontFamily: 'Jalnan',
                                          ),
                                        ),
                                        SizedBox(height: 30),
                                        Stack(
                                          children: [
                                            currentPosture == 'general'
                                                ? SizedBox(
                                                    child: Image.asset(
                                                      "assets/img/GreenTurtle.png",
                                                      fit: BoxFit.contain,
                                                    ),
                                                    height: 30,
                                                  )
                                                : SizedBox(
                                                    child: Image.asset(
                                                      "assets/img/RedTurtle.png",
                                                      fit: BoxFit.contain,
                                                    ),
                                                    height: 30,
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "바른자세를 위한 추천",
                          style: TextStyle(fontFamily: 'Jalnan'),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _launchURL();
                                      },
                                      child: Image.asset(
                                        "assets/img/Thumbnail.png",
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            child: InkWell(
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Image.asset(
                                      "assets/img/Optionwheel.png",
                                      fit: BoxFit.contain),
                                ),
                              ),
                              onTap: () => {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OptionPage(),
                                  ),
                                )
                              },
                            ),
                          ),
                          SizedBox(width: 30),
                          Card(
                            child: InkWell(
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Image.asset("assets/img/LightBulb.png",
                                      fit: BoxFit.contain),
                                ),
                              ),
                              onTap: () => {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FaqPage(),
                                  ),
                                )
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//BLE 장치 정보 저장 클래스
class BleDeviceItem {
  String deviceName;
  Peripheral peripheral;
  int rssi;
  AdvertisementData advertisementData;

  BleDeviceItem(
      this.deviceName, this.rssi, this.peripheral, this.advertisementData);
}
