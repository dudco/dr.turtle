import 'package:flutter/material.dart';

class OptionPage extends StatefulWidget {
  @override
  _OptionPageState createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  var soundSwitch = true;
  var vibrateSwitch = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "설정",
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
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Text("앱버전"),
                      Expanded(child: SizedBox()),
                      Text("v1.0.0"),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text("소리"),
                      Expanded(child: SizedBox()),
                      Switch(
                        value: soundSwitch,
                        onChanged: (val) => {
                          setState(() => {soundSwitch = val})
                        },
                        activeColor: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text("진동"),
                      Expanded(child: SizedBox()),
                      Switch(
                        value: vibrateSwitch,
                        onChanged: (val) => {
                          setState(() => {vibrateSwitch = val})
                        },
                        activeColor: Colors.black,
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
