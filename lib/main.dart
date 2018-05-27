import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:collection';
import 'package:math_expressions/math_expressions.dart';


class CameraHome extends StatefulWidget {
  @override
  _CameraHomeState createState() {
    return new _CameraHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw new ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraHomeState extends State<CameraHome> {
  CameraController controller;
  TextEditingController textController = new TextEditingController();
  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  String answer = "Answer";
  String predictedEquation = "Predicted Equation";
  String operationForListView = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _progressBarActive = false;
  bool _simpsonBar = false;
  String simposonAnswer = "";

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('PhotoCalculus Calculator', style: TextStyle(color: Colors.black, fontSize: 20.0),),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, EquationHistory());
            },
          ),
        ],
        backgroundColor: Colors.red,

      ),
      body: new Column(
        children: <Widget>[
          new Expanded(
            child: new Container(
              child: new Padding(
                padding: const EdgeInsets.all(1.0),
                child: new Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: new BoxDecoration(
                color: Colors.black,

              ),
            ),
          ),
          _captureControlRowWidget(),
          new Container(padding: const EdgeInsets.all(5.0),
              child: new Text(predictedEquation,
                style: TextStyle(color: Colors.black,
                    fontSize: 20.0),)),
          new Container(padding: const EdgeInsets.all(5.0),
              child: _progressBarActive == true ? const CircularProgressIndicator(backgroundColor: Colors.red,) :new Text(answer,
                style: TextStyle(color: Colors.black,
                    fontSize: 20.0),)),
          _simpsonBar == false ? new Container() : new Container(padding: const EdgeInsets.all(5.0),
              child: _progressBarActive == true ? const CircularProgressIndicator(backgroundColor: Colors.red,) :new Text(simposonAnswer,
                style: TextStyle(color: Colors.black,
                    fontSize: 20.0),)),
          new Container(color: Colors.red,
              child: new Padding(padding: const EdgeInsets.all(5.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _cameraTogglesRowWidget(),
                  _thumbnailWidget(),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return new AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: new CameraPreview(controller),
      );
    }
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return new Expanded(
      child: new Align(
        alignment: Alignment.centerRight,
        child: videoController == null && imagePath == null
            ? null
            : new SizedBox(
          child: (videoController == null)
              ? new Image.file(new File(imagePath))
              : new Container(
            child: new Center(
              child: new AspectRatio(
                  aspectRatio: videoController.value.size != null
                      ? videoController.value.aspectRatio
                      : 1.0,
                  child: new VideoPlayer(videoController)),
            ),
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.pink)),
          ),
          width: 64.0,
          height: 64.0,
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return new Container(color: Colors.red,child: new Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        new IconButton(
          icon: const Icon(Icons.camera_alt),
          iconSize: 45.0,
          color: Colors.black,
          onPressed: controller != null &&
              controller.value.isInitialized &&
              !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    ));
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          new SizedBox(
            width: 90.0,
            child: new RadioListTile<CameraDescription>(
              title:
              new Icon(getCameraLensIcon(cameraDescription.lensDirection), color: Colors.black,),
              activeColor: Colors.black,
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return new Row(children: toggles);
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = new CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    setState(() {
      _simpsonBar = false;
    });
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        if (filePath != null) {
          showInSnackBar('Picture saved to $filePath');
          callMathPixApi(imagePath);
        }

      }
    });
  }

  void callMathPixApi(String imagePath) {
      setState(() {
        _progressBarActive = true;
      });
      File imageFile = new File(imagePath);
      List<int> imageBytes = imageFile.readAsBytesSync();
      Base64Encoder a = new Base64Encoder();
      String base64 = a.convert(imageBytes);
      JsonEncoder a2 = new JsonEncoder();
      var body = a2.convert({'src': "data:image/jpeg;base64," + base64});
      print(base64);

      var url = "https://api.mathpix.com/v3/latex/";
      http.post(
          url,
          headers: {'app-id': 'gatiganti44914_sas_edu_sg',
            'app_key': '452f9b9e710f6e03b263',
            'Content-Type': 'application/json'},
          body: body).then(handleSuccess).catchError(handleFailure);
  }

  handleSuccess(http.Response response) {
    print('it worked!');
    print(response.body);
    Map<num, String> POSSIBLES = new Map();
    POSSIBLES[-999] = "Sorry, I do not recognise this equation";
    POSSIBLES[0] = "I can evaluate this. Please Wait";
    POSSIBLES[1] = "This is a chart/graph";
    POSSIBLES[2] = "This is a table";
    POSSIBLES[3] = "Sorry, the paper is blank";
    POSSIBLES[4] = "I don't know what this is anymore";
    int type = evaluateExpressionType(response.body);
    setState(() {
      answer = POSSIBLES[type];
    });
    print(POSSIBLES[type]);
    if(type == 0) {
      evaluateLatexExpression(response.body);
    } else {
      setState(() {
        _progressBarActive = false;
      });
    }

  }

  handleFailure(error) {
    print('Something went wrong.');
    print(error.message);
  }

  int evaluateExpressionType(String s) {
    JsonDecoder decoder = new JsonDecoder();
    Map data = decoder.convert(s);
    if(data["detection_map"]["is_not_math"] > 0.8) {
      return -999;
    }
    else if(data["detection_map"]["contains_chart"] > 0.9 || data["detection_map"]["contains_graph"] > 0.9) {
      return 1;
    }
    else if(data["detection_map"]["contains_table"] > 0.85) {
      return 2;
    }
    else if(data["detection_map"]["is_blank"] > 0.8) {
      return 3;
    }
    else if(data["latex_confidence_rate"] > 0.9) {
      return 0;
    }
    else {
      return -999;
    }
  }

  double evaluateLatexExpression(String jsonString) {
    JsonDecoder decoder = new JsonDecoder();
    Map data = decoder.convert(jsonString);
    String latex = data["latex"];
    String OPERATION = "";
    int operationLength = 0;
    Map<String, String> OPERATIONS = new Map();
    //OPERATIONS["\\int _ {"] = "area/";
    OPERATIONS["\\int"] = "integrate/";
    OPERATIONS["\\frac { d } { d x }"] = "derive/";
    for(String s in OPERATIONS.keys) {
      if(latex.indexOf(s) >= 0) {
        OPERATION = OPERATIONS[s];
        operationLength = s.length;
        break;
      }
    }
    String arg = "";
    String equation = latex.substring(operationLength);
    if(equation.contains("_") || OPERATION == "area/") {
      OPERATION = "area/";
      List terms = findEquationWithBounds(equation);
      String firstBound = terms[0];
      String secondBound = terms[1];
      operationForListView = "Definite Integral from " + terms[0] + " to " + terms[1];
      arg = firstBound + ":" + secondBound + "|" + terms[2];
      var url = "https://newton.now.sh/" + OPERATION + arg;
      print(url);
      http.get(url).then(handleNewtonSuccess).catchError(handleFailure);
      print("Simpson:" + evaluateWithSimpson(terms[0], terms[1], terms[2]).toString());
    }
    else {
      operationForListView = OPERATION.substring(0, OPERATION.length-1);
      arg = findEquation(equation, false);
      var url = "https://newton.now.sh/" + OPERATION + arg;
      print(url);
      http.get(url).then(handleNewtonSuccess).catchError(handleFailure);
    }

  }

  double evaluateWithSimpson(String a, String b, String eq) {
    Parser p = new Parser();
    Expression exp = p.parse(eq);
    Variable xa = new Variable('x');
    Variable xb = new Variable('x');
    double aNum = double.parse(a);
    double bNum = double.parse(b);
    ContextModel cm = new ContextModel();
    ContextModel cm2 = new ContextModel();
    int N = 15000;

    double h = (double.parse(b) - double.parse(a)) / (N - 1);
    cm.bindVariable(xa, new Number(aNum)); cm2.bindVariable(xb, new Number(bNum));
    double sum = 1.0 / 3.0 * (exp.evaluate(EvaluationType.REAL, cm) + exp.evaluate(EvaluationType.REAL, cm));

    for (int i = 1; i < N - 1; i += 2) {
      double x = aNum + h * i;
      cm.bindVariable(xa, new Number(x));
      sum += 4.0 / 3.0 * exp.evaluate(EvaluationType.REAL, cm);
    }
    for (int i = 2; i < N - 1; i += 2) {
      double x = aNum + h * i;
      cm.bindVariable(xa, new Number(x));
      sum += 2.0 / 3.0 * exp.evaluate(EvaluationType.REAL, cm);
    }
    print("SIMPSON: " + (sum*h).toString());
    setState(() {
      _simpsonBar = true;
      simposonAnswer = "Simpson: " + (sum*h).toString();
    });
    return sum * h;
  }


  handleNewtonSimplifySuccess(http.Response response) {
    print(response.body);
    JsonDecoder decoder = new JsonDecoder();
    Map data = decoder.convert(response.body);
    String answer2 = data["result"];
    print("NewtonSimplify:" + answer2);
  }

  String findEquation(String equation, bool area) {
    equation = equation.replaceAll("{", "");
    equation = equation.replaceAll("}", "");
    equation = equation.replaceAll(" ", "");
    equation = equation.replaceAll("dx", "");
    equation = equation.replaceAll("\\cdot", "*");
    equation = equation.replaceAll("\\operatorname", "");
    equation = equation.replaceAll("\\", "");
    if(equation.contains("sqrt"))
      equation = equation.substring(0, equation.indexOf("sqrt") + 4) + "(" + equation.substring(equation.indexOf("sqrt") + 4) + ")";
    print(equation);
      setState(() {
        predictedEquation = "Predicted: " + equation;
      });

    return equation;
  }

  List findEquationWithBounds(String equation) {
    equation = equation.replaceAll("{", "");
    equation = equation.replaceAll("}", "");
    //equation = equation.replaceAll("\\", "");
    //equation = equation.replaceAll("operatorname", "");
    List equationWithBounds = new List(3);
    equationWithBounds[0] = equation.substring(
      equation.indexOf("_") + 3,
      equation.indexOf("^") - 1
    );
    print(equationWithBounds[0]);
    int ind = equation.indexOf(" ", equation.indexOf("^") + 3);
    equationWithBounds[1] = equation.substring(
      equation.indexOf("^") + 3,
      equation.indexOf(" ", equation.indexOf("^") + 3)
    );
    print(equationWithBounds[1]);
    equationWithBounds[2] = findEquation(equation.substring(ind+1), true);
    return equationWithBounds;
  }

  handleNewtonSuccess(http.Response response) {
    print(response.body);
    JsonDecoder decoder = new JsonDecoder();
    Map data = decoder.convert(response.body);
    String answer2 = data["result"];
    setState(() {
      answer = answer2;
      _progressBarActive = false;
    });

    EquationHistory.equations.addFirst(new ListTile(
      leading: new Icon(Icons.check_circle),
      title: new Text(operationForListView),
      subtitle: new Text(predictedEquation + " Answer: " + answer2),
    ));
  }




  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recorded to: $videoPath');
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    await _startVideoPlayer();
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
    new VideoPlayerController.file(new File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(true);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imagePath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new CameraHome(),
    );
  }
}

List<CameraDescription> cameras;

Future<Null> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(new CameraApp());
}

class EquationHistory extends MaterialPageRoute<Null> {
  static Queue<Widget> equations = new Queue();
  EquationHistory() : super(builder: (BuildContext ctx) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Your Equation History'),
        backgroundColor: Colors.red,
      ),
      body: new ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        children: equations.toList()
      ),
    );
  });
}