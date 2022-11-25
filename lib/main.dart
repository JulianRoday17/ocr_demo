import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ocr/features/invoice_detection/screens/invoice_screen.dart';
import 'package:ocr/features/ktp_detection/screens/ktp_home_screen.dart';

List<CameraDescription> cameras = [];
Map<int, Color> color = {
  50: Color.fromRGBO(18, 176, 107, .1),
  100: Color.fromRGBO(18, 176, 107, .2),
  200: Color.fromRGBO(18, 176, 107, .3),
  300: Color.fromRGBO(18, 176, 107, .4),
  400: Color.fromRGBO(18, 176, 107, .5),
  500: Color.fromRGBO(18, 176, 107, .6),
  600: Color.fromRGBO(18, 176, 107, .7),
  700: Color.fromRGBO(18, 176, 107, .8),
  800: Color.fromRGBO(18, 176, 107, .9),
  900: Color.fromRGBO(18, 176, 107, 1),
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: MaterialColor(0XFF1AAF6A, color)),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('OCR Demo'),
            centerTitle: true,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: Size(kToolbarHeight, kToolbarHeight),
              child: Material(
                color: Color(0XFF1AAF6A), //<-- SEE HERE
                child: TabBar(
                    indicator: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white),
                    indicatorColor: Colors.orange,
                    labelColor: Color(0XFF1AAF6A),
                    unselectedLabelColor: Colors.white,
                    tabs: [
                      Tab(
                        text: 'KTP',
                      ),
                      // Tab(
                      //   text: 'NPWP',
                      // ),
                      Tab(
                        text: 'Invoice',
                      )
                    ]),
              ),
            ),
          ),
          body: SafeArea(
              child: Column(children: [
            // TabBar(
            //     indicator: BoxDecoration(
            //         border: Border.all(color: Color(0XFF1AAF6A)),
            //         color: Color(0XFF1AAF6A)),
            //     indicatorColor: Colors.orange,
            //     labelColor: Colors.white,
            //     unselectedLabelColor: Colors.green,
            //     tabs: [
            //       Tab(
            //         text: 'KTP',
            //       ),
            //       // Tab(
            //       //   text: 'NPWP',
            //       // ),
            //       Tab(
            //         text: 'Invoice',
            //       )
            //     ]),
            Expanded(
              child: TabBarView(children: [
                KtpHomeScreen(),
                // Container(
                //   child: Center(
                //     child: Text('NPWP'),
                //   ),
                // ),
                TextRecognizerView()
              ]),
            )
          ])),
          backgroundColor: Colors.white,
        ));
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    const Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
