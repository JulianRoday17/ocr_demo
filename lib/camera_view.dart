import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr/constant.dart';
import 'package:ocr/model/invoice_model.dart';
import 'package:ocr/model/text_recognize.dart';
import 'package:ocr/ocr_painter.dart';

import '../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
      required this.title,
      required this.customPaint,
      this.text,
      required this.onImage,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  int _cameraIndex = -1;
  List tempList = [];
  Map finalList = {};
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  final bool _allowPicker = true;
  bool _changingCameraLens = false;
  TextEditingController tempController = TextEditingController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  InvoiceModel invoiceData = InvoiceModel(
      companyName: '', invoiceAmount: '', invoiceDate: '', invoiceNumber: '');

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
    );
  }

  Widget _body() {
    Widget body;

    body = _galleryBody();

    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? Center(
                      child: const Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          )
        ],
      ),
    );
  }

  Widget inputContainer(String title, String hintText,
          TextEditingController controller, height, enable) =>
      Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                title,
              ),
            ),
            SizedBox(height: 2),
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: height,
              constraints: BoxConstraints(minHeight: 50),
              padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: TextField(
                style: TextStyle(color: Colors.grey.shade700),
                enabled: true,
                controller: controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                  contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                ),
              ),
            ),
          ]));

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: Text('From Gallery'),
              onPressed: () => _getImage(ImageSource.gallery),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: Text('Take a picture'),
              onPressed: () => _getImage(ImageSource.camera),
            ),
          ),
          inputContainer('Nama Outlet', invoiceData.companyName, tempController,
              50.0, false),
          inputContainer('Nomor Kwitansi', invoiceData.invoiceNumber,
              tempController, 50.0, false),
          inputContainer('Tanggal Kwitansi', invoiceData.invoiceDate,
              tempController, 50.0, false),
          inputContainer('Total Nilai Kwitansi', invoiceData.invoiceAmount,
              tempController, 50.0, false),
        ]),
      ),
      if (_image != null)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              '${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}'),
        ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile == null) return;
    File? image = File(pickedFile.path);
    image = await _cropImage(imageFile: image);
    if (image != null) {
      _processPickedFile(image);
    }
    setState(() {});
  }

  Future<File?> _cropImage({required File imageFile}) async {
    var croppedImage = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
    );

    if (croppedImage == null) return null;
    return File(croppedImage.path);
  }

  Future _processPickedFile(File pickedFile) async {
    final path = pickedFile.path;
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    processImage(inputImage);
    widget.onImage(inputImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    _isBusy = false;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = TextRecognizerPainter(
          recognizedText,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      // _text = 'Recognized text:\n\n${recognizedText.text}';
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }

    itemData.clear();
    finalItem.clear();
    // var textRecognize = TextKnown(textKnown: textKnown, TopPosition: TopPosition, LeftPosition: LeftPosition)
    //     TextKnown(LeftPosition: 0, TopPosition: 0, textKnown: "");
    final List<TextKnown> textKnowns = [];
    textKnowns.clear();
    for (TextBlock block in recognizedText.blocks) {
      final String text = block.text;
      final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock\
        // textRecognize.textKnown = line.text;
        // textRecognize.TopPosition = line.boundingBox.top;
        // textRecognize.LeftPosition = line.boundingBox.left;
        textKnowns.add(TextKnown(
            textKnown: line.text,
            TopPosition: line.boundingBox.top,
            LeftPosition: line.boundingBox.left));
        //     TextKnown(LeftPosition);
        // itemData.add(line);
      }
    }
    try {
      textKnowns.sort(((a, b) => a.TopPosition.compareTo(b.TopPosition)));
    } catch (ex) {
      print(ex.toString());
    }
    String invoiceNumber = "Not Found";
    String invoiceDate = "Not Found";
    String invoiceAmount = "Not Found";
    //company name
    final companyName = textKnowns
        .where((element) =>
            element.textKnown.contains("PT") ||
            element.textKnown.contains("CV") ||
            element.textKnown.contains("corp"))
        .first
        .textKnown;
// Invoice Number

    //find invoice
    // String invoiceStart =
    // _text = 'Recognized text:\n\n${textKnowns[8].textKnown}';
    // if (itemData.length == 31) {
    //   counter = 1;
    // }
    // itemData.removeRange(0, 11);
    // finalItem.add(itemData[8].text);

    _isBusy = false;
    if (mounted) {
      setState(() {
        invoiceData = InvoiceModel(
            companyName: companyName,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            invoiceAmount: invoiceAmount);
      });
    }
  }

  String checkString(String value) {
    String finalString = '';

    List tempData = value.trim().split(' ');

    for (var data in tempData) {
      if (data != ':' && data.toString().toUpperCase() == data) {
        finalString += data;
        finalString += '';
      }
    }

    return finalString.trim().toString().replaceAll(':', '');
  }
}
