import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Small QR Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool bottomActive = false;
  bool isTorchOn = false;
  MobileScannerController controller = MobileScannerController(
    // cameraResolution: const Size.fromWidth(720),
    facing: CameraFacing.back,
    autoStart: true,
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Resume the camera when app returns to the foreground.
      controller.start();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      // Pause or stop the camera when app goes to the background.
      controller.stop();
      setState(() {
        isTorchOn = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = MobileScannerController(
      // cameraResolution: const Size.fromWidth(720),
      facing: CameraFacing.back,
      autoStart: true,
    );

    controller.start();

    // controller.buildCameraView();
  }

  void _toggleTorch() {
    setState(() {
      // Toggle the isTorchOn state
      isTorchOn = !isTorchOn;
      controller.toggleTorch();
    });
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    // unawaited(_subscription?.cancel());
    // _subscription = null;
    // Dispose the widget itself.
    controller.dispose();
    super.dispose();
    // Finally, dispose of the controller.
  }


  static const platform = MethodChannel('com.example.browser/open');

  Future<void> _openLink(String? url) async {
    try {
      await platform.invokeMethod('openBrowser', {'url': url});
    } on PlatformException catch (e) {
      print("Failed to open browser: '${e.message}'.");
    }
  }

  bool _isUrl(String? text) {
    final urlPattern = r'^(http|https):\/\/[^\s]+$';
    final regex = RegExp(urlPattern);
    return text != null && regex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: MobileScanner(
          controller: controller,
          onDetect: (BarcodeCapture barcode) {
            if (!bottomActive) {
              bool isUrl = _isUrl(barcode.barcodes[0].displayValue);
              showModalBottomSheet(context: context, builder: (BuildContext context) {
                return SizedBox(
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => isUrl ? _openLink(barcode.barcodes[0].displayValue) : null,
                        child: Text(
                          barcode.barcodes[0].displayValue ?? "No URL",
                          style: TextStyle(
                            color: isUrl ? Colors.blue : Colors.black,
                            decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).whenComplete(() {
                // Update the state when the bottom sheet is closed
                bottomActive = false;
                controller.start();
              });
              bottomActive = true;
            }
          },
        ),
      ),
    );
  }
}
