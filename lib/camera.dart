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
import 'start.dart';


class Camera extends StatefulWidget {
  @override
  _CameraState createState() {
    return new _CameraState();
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

class _CameraState extends State<Camera> {
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
  var count = 0;
  bool showLoader = false;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('PhotoCalculus',
          style: TextStyle(color: Colors.white, fontSize: 20.0, fontFamily: "Raleway", ),),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StartPage()));
            },
          ),
        ],
        bottomOpacity: 0.5,
        backgroundColor: Colors.blue[900],

      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.history),
        onPressed: () {
          Navigator.push(context, EquationHistory());
        },
        backgroundColor: Colors.blue[900],),
      floatingActionButtonLocation: const _StartTopFloatingActionButtonLocation(),
      body: new Stack(children: <Widget>[new Column(
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
                color: Colors.blue[900],

              ),
            ),
          ),
//            new Container(padding: const EdgeInsets.all(5.0),
//                child: new Text(predictedEquation,
//                  style: TextStyle(color: Colors.black,
//                      fontSize: 20.0,),),  ),
//            //if loading, display indicator, else display Text
//            new Container(padding: const EdgeInsets.all(5.0),
//                child: _progressBarActive == true
//                    ? const CircularProgressIndicator(
//                  backgroundColor: Colors.red,)
//                    : new Text(answer,
//                  style: TextStyle(color: Colors.black,
//                      fontSize: 20.0),)),
//            _simpsonBar == false ? new Container() : new Container(
//                padding: const EdgeInsets.all(5.0),
//                child: _progressBarActive == true
//                    ? const CircularProgressIndicator(
//                  backgroundColor: Colors.red,)
//                    : new Container(
//                    color: Colors.blue[200], child: new Text(simposonAnswer,
//                  style: TextStyle(color: Colors.black,
//                      fontSize: 20.0),))),
          /*new Container(color: Colors.blue[900],
                child: new Padding(padding: const EdgeInsets.all(5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _cameraTogglesRowWidget(),
                      _thumbnailWidget(),
                    ],
                  ),
                )),*/
        ],
      )]),
      bottomNavigationBar: new BottomAppBar(
        color: Colors.blue[900],
        child:  _captureControlRowWidget(),
      ),
    );
  }
  void showHistory() {
    Navigator.push(context, EquationHistory());
  }
  int hexToInt(String hex)
  {
    int val = 0;
    int len = hex.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = hex.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new FormatException("Invalid hexadecimal value");
      }
    }
    return val;
  }
  void initializeCam() async {
    CameraDescription a;
    if (Platform.operatingSystem == "android") {
      a = new CameraDescription(
          name: "0", lensDirection: CameraLensDirection.back);
    }
    else {
      a = new CameraDescription(
          name: "com.apple.avfoundation.avcapturedevice.built-in_video:0", lensDirection: CameraLensDirection.back);
    }
    controller = new CameraController(a, ResolutionPreset.high);
    if (controller != null) {
      await controller.dispose();
    }
    controller = new CameraController(a, ResolutionPreset.high);
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
  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      initializeCam();
      return const Text(
        'No Camera Available',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return new CameraPreview(controller);
//      return new AspectRatio(
//        aspectRatio: controller.value.aspectRatio,
//        child: new CameraPreview(controller),
//      );
    }

  }

  /// Display the thumbnail of the captured image or video.
  /*Widget _thumbnailWidget() {
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
  }*/

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return
      showLoader ? new LinearProgressIndicator() : new IconButton(
        color: Colors.white,
        highlightColor: Colors.blue[900],
        icon: const Icon(Icons.camera_alt),
        iconSize: 40.0,
        onPressed: controller != null &&
            controller.value.isInitialized &&
            !controller.value.isRecordingVideo
            ? onTakePictureButtonPressed
            : null,
      );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  /*Widget _cameraTogglesRowWidget() {
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
  }*/

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
          showLoader = true;
        });
        if (filePath != null) {
          //showInSnackBar('Picture saved to $filePath');
          callMathPixApi(imagePath);
        }

      }
    });
  }

  //calls the MathPix API and sends the JSON to a helper method
  void callMathPixApi(String imagePath) {
    setState(() {
      _progressBarActive = true;
    });

    //conversion into Base64
    File imageFile = new File(imagePath);
    List<int> imageBytes = imageFile.readAsBytesSync();
    Base64Encoder base64Encoder = new Base64Encoder();
    String base64 = base64Encoder.convert(imageBytes);
    JsonEncoder jsonEncoder = new JsonEncoder();
    var body = jsonEncoder.convert({'src': "data:image/jpeg;base64," + base64});
    print(base64);

    var url = "https://api.mathpix.com/v3/latex/";
    http.post(
        url,
        headers: {'app-id': 'gatiganti44914_sas_edu_sg',
          'app_key': '452f9b9e710f6e03b263',
          'Content-Type': 'application/json'},
        body: body).then(handleSuccess).catchError(handleFailure);
  }

  //handles the JSON file received from MathPix, and analyzes whether it really is a calculus equation or not
  handleSuccess(http.Response response) {
    print('it worked!');
    print(response.body);
    //Map of possible types of pictures.
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
      print("Setting state");
      setState(() {
        showLoader = false;
        _progressBarActive = false;
      });
      showAnswers();
    }
  }

  handleFailure(error) {
    print('Something went wrong.');
    print(error.message);
  }
  //Uses MathPix JSON probabilites and confidences in order to predict whether it really is a math equation.
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

  //if MathPix call was successful, the resulting LaTex goes to this method and is converted into the necessary format for Newton
  //e.g. \\int _ {0} ^ {2} x^2 has to be converted into /area/0:2|x^2
  void evaluateLatexExpression(String jsonString) {
    JsonDecoder decoder = new JsonDecoder();
    Map data = decoder.convert(jsonString);
    String latex = data["latex"];
    String OPERATION = "";
    int operationLength = 0;
    Map<String, String> OPERATIONS = new Map();
    OPERATIONS["\\int _ {"] = "area/";
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
    //if it is a definite integral
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

  bool isDigit(String s) {
    return "1234567890".contains(s);
  }
  //Since Newton had some trouble evaluating definite integrals, I wrote the Simpson's Method, which is how calculators evaluate definite integrals
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
      double input = aNum + h * i;
      cm.bindVariable(xa, new Number(input));
      sum += 4.0 / 3.0 * exp.evaluate(EvaluationType.REAL, cm);
    }
    for (int i = 2; i < N - 1; i += 2) {
      double input = aNum + h * i;
      cm.bindVariable(xa, new Number(input));
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
  //cleans up the equation so Newton or my other methods can understand it
  String findEquation(String equation, bool area) {
    equation = equation.replaceAll("{", "");
    equation = equation.replaceAll("}", "");
    equation = equation.replaceAll(" ", "");
    equation = equation.replaceAll("dx", "");
    equation = equation.replaceAll("\\cdot", "*");
    equation = equation.replaceAll("\\operatorname", "");
    equation = equation.replaceAll("\\", "");
    //so there is a bracket for the equation/terms following the square root.
    if(equation.contains("sqrt"))
      equation = equation.substring(0, equation.indexOf("sqrt") + 4) + "(" + equation.substring(equation.indexOf("sqrt") + 4) + ")";
    print(equation);
    setState(() {
      predictedEquation = "Predicted: " + equation;
    });

    return equation;
  }

  //converts the LaTex form of a bounded integral into an Array of terms
  List findEquationWithBounds(String equation) {
    equation = equation.replaceAll("{", "");
    equation = equation.replaceAll("}", "");
    //equation = equation.replaceAll("\\", "");
    //equation = equation.replaceAll("operatorname", "");
    List equationWithBounds = new List(3);
    equationWithBounds[0] = equation.substring(
        equation.indexOf("_") + 2,
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
    print(answer2);
    setState(() {
      print("here");
      answer = answer2;
      print(answer);
      _progressBarActive = false;
    });
    showAnswers();

    //must addFirst as we are implementing a Stack using a Queue.
    EquationHistory.equations.addFirst(new ListTile(
      leading: new Icon(Icons.check_circle),
      title: new Text(operationForListView),
      subtitle: new Text(predictedEquation + " Answer: " + answer2),
    ));
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
  void showAnswers() {
    String finalText = "";
    setState(() {
      showLoader = false;
    });
    if(!(predictedEquation == "Predicted Equation"))
      finalText+=predictedEquation+ "\n";
    finalText+= "Answer: " + answer;
    print("ASNWER: " + answer);

    if(_simpsonBar == true)
      finalText+= "\n" + "Simpson's Method: " + double.parse(simposonAnswer.substring(simposonAnswer.indexOf(":") + 1)).toStringAsFixed(3);
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Container(
              child: new Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: new Text(finalText,
                      textAlign: TextAlign.center,
                      style: new TextStyle(
                          color: Colors.blue[900],
                          fontSize: 18.0
                      )
                  )
              )
          );
        });
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Camera(),
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

//class that shows the equation history page and contains the Stack for the history (Stack implemented as Queue).
class EquationHistory extends MaterialPageRoute<Null> {
  static Queue<Widget> equations = new Queue();
  EquationHistory() : super(builder: (BuildContext ctx) {
    return new Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: new AppBar(
        title: new Text('Your Equation History'),
        backgroundColor: Colors.black,
      ),
      body: new ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
          children: equations.toList()
      ),
    );
  });
}


//From Flutter Example Gallery
// Places the Floating Action Button at the top of the content area of the
// app, on the border between the body and the app bar.
class _StartTopFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _StartTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // First, we'll place the X coordinate for the Floating Action Button
    // at the start of the screen, based on the text direction.
    double fabX;
    assert(scaffoldGeometry.textDirection != null);
    switch (scaffoldGeometry.textDirection) {
      case TextDirection.rtl:
      // In RTL layouts, the start of the screen is on the right side,
      // and the end of the screen is on the left.
      //
      // We need to align the right edge of the floating action button with
      // the right edge of the screen, then move it inwards by the designated padding.
      //
      // The Scaffold's origin is at its top-left, so we need to offset fabX
      // by the Scaffold's width to get the right edge of the screen.
      //
      // The Floating Action Button's origin is at its top-left, so we also need
      // to subtract the Floating Action Button's width to align the right edge
      // of the Floating Action Button instead of the left edge.
        final double startPadding = kFloatingActionButtonMargin + scaffoldGeometry.minInsets.right;
        fabX = scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width - startPadding;
        break;
      case TextDirection.ltr:
      // In LTR layouts, the start of the screen is on the left side,
      // and the end of the screen is on the right.
      //
      // Placing the fabX at 0.0 will align the left edge of the
      // Floating Action Button with the left edge of the screen, so all
      // we need to do is offset fabX by the designated padding.
        final double startPadding = kFloatingActionButtonMargin + scaffoldGeometry.minInsets.left;
        fabX = startPadding;
        break;
    }
    // Finally, we'll place the Y coordinate for the Floating Action Button
    // at the top of the content body.
    //
    // We want to place the middle of the Floating Action Button on the
    // border between the Scaffold's app bar and its body. To do this,
    // we place fabY at the scaffold geometry's contentTop, then subtract
    // half of the Floating Action Button's height to place the center
    // over the contentTop.
    //
    // We don't have to worry about which way is the top like we did
    // for left and right, so we place fabY in this one-liner.
    final double fabY = 25 + scaffoldGeometry.contentTop - (scaffoldGeometry.floatingActionButtonSize.height / 2.0)*0.0;
    return new Offset(fabX, fabY);
  }
}
