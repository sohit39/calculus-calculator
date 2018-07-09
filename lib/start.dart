import 'package:flutter/material.dart';


class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            SizedBox(height: 10.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Image.asset('assets/new-green-hollow-circle.png', width: 100.0, height: 100.0,),
                SizedBox(height: 16.0),
                Text(
                  'PhotoCalculus',
                  style: TextStyle(
                      fontFamily: "Raleway",
                      fontSize: 40.0,
                      color: Colors.white,

                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0),
                Text(
                  "Simply take photos of derivatives and integrals, and watch the answers appear!",
                  style: TextStyle(
                  fontFamily: "Raleway3",
                  fontSize: 19.0,
                  color: Colors.white,

                ),
                textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0,),
                Text(
                  "Phone MUST be rotated 90 degrees to the left when taking photos",
                  style: TextStyle(
                    fontFamily: "Raleway2",
                    fontSize: 19.0,
                    color: Colors.white,

                  ),
                  textAlign: TextAlign.center,
                ),
                Image.asset('assets/rotatedevice.gif', height: 200.0,)

              ],
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                new PrimaryColorOverride(color: const Color(0xFF5CDB95),
                    child: RaisedButton(
                      child: Text('START' ,style: TextStyle(fontFamily: "Raleway2",color:const Color(0xFF05386B))),
                      elevation: 8.0,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7.0)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },

                    )),
              ],
            ),
            SizedBox(height: 5.0),
            Text("Note: Derivatives must be in d/dx form.", style: TextStyle(
              fontFamily: "Raleway",
              fontSize: 19.0,
              color: Colors.white,
            ), textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
  }
}

class PrimaryColorOverride extends StatelessWidget {
  const PrimaryColorOverride({Key key, this.color, this.child})
      : super(key: key);

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      child: child,
      data: Theme.of(context).copyWith(primaryColor: color),
    );
  }
}