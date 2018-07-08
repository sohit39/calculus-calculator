import 'package:flutter/material.dart';
import 'camera.dart';
import 'start.dart';

class CalculusCalculator extends StatefulWidget {
  _CalculusCalculatorState createState() => _CalculusCalculatorState();
}
class _CalculusCalculatorState extends State<CalculusCalculator> {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculus Calculator',
      home: new CameraApp(),
      initialRoute: '/start',
      onGenerateRoute: _getRoute,
    );
  }

  Route<dynamic> _getRoute(RouteSettings settings) {
    if (settings.name == '/start') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => StartPage(),
        fullscreenDialog: true,
      );
    }

    return null;
  }
}