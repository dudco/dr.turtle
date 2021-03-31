import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "FaQ",
          style: TextStyle(fontFamily: 'Jalman', color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(0, 208, 208, 208),
          ),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q1. 블루투스 연결이 안돼요.",
                      style: TextStyle(fontFamily: "Jalnan"),
                    ),
                    SizedBox(height: 10),
                    Text(
                        "iOS: 설정 - Bluetooth에서 기타 기기에서 'Dr.Turtle'을 터치하여 '나의 기기'로 등록되어 있는지 확인하세요.")
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q2. 알림 소리/진동이 시끄러워요",
                      style: TextStyle(fontFamily: "Jalnan"),
                    ),
                    Text(
                        "Dr.TURTLE 어플리케이션 메인 화면 하단의 회색 톱니바퀴를 누르세요. 설정 화면에서 소리/진동 버튼을 눌러 꺼 주시면 더 이상 알림 소리가 나지 않습니다.")
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q3. 메인화면의 거북이는 뭔가요?",
                      style: TextStyle(fontFamily: "Jalnan"),
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: Image.asset(
                              "assets/img/GreenTurtle.png",
                              fit: BoxFit.contain,
                            ),
                            height: 30,
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Image.asset(
                              "assets/img/RedTurtle.png",
                              fit: BoxFit.contain,
                            ),
                            height: 30,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                        "당신의 현재 거북목 위험도를 나타냅니다.\n직관적인 아이콘으로 사용자의 경추 상태를 확인하고 바른자세를 유지할 수 있도록 돕습니다.\n연두색 거북이 - 정상\n빨간색 거북이 - 매우 위험")
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
