import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr/features/invoice_detection/controllers/invoice_controller.dart';
import 'package:ocr/features/invoice_detection/models/invoice_model.dart';
import 'package:ocr/features/invoice_detection/models/text_recognize_model.dart';
import 'package:ocr/helpers/ocr_helper/ocr_converter.dart';
import 'package:ocr/shared/constant.dart';
import 'package:ocr/utils/input.utils.dart';

import '../../../../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  const CameraView({super.key});

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
  TextEditingController companyNameController = TextEditingController();
  TextEditingController invoiceNumberController = TextEditingController();
  TextEditingController invoiceDateController = TextEditingController();
  TextEditingController invoiceAmountController = TextEditingController();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  InvoiceModel invoiceData = InvoiceModel(
      companyName: '', invoiceAmount: '', invoiceDate: '', invoiceNumber: '');
  OCRConverter ocrConverter = OCRConverter();
  InvoiceController invoiceController = InvoiceController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();
    imageFinalInvoice = null;
    if (cameras.any(
      (element) =>
          element.lensDirection == CameraLensDirection.back &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == CameraLensDirection.back &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == CameraLensDirection.back) {
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
      backgroundColor: Colors.white,
      body: Stack(children: [
        ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Visibility(
                visible: imageFinalInvoice != null,
                child: Container(
                  height: 300,
                  width: 400,
                  child: Image.file(
                    imageFinalInvoice ?? File(''),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      child: Text('Pilih Gambar Invoice'),
                      onPressed: () => _getImage(ImageSource.gallery),
                    ),
                    ElevatedButton(
                      child: Text('Reset'),
                      onPressed: () {
                        setState(() {
                          imageFinalInvoice = null;
                          companyNameController.clear();
                          invoiceNumberController.clear();
                          invoiceDateController.clear();
                          invoiceAmountController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 16),
              //   child: ElevatedButton(
              //     child: Text('Take a picture'),
              //     onPressed: () => _getImage(ImageSource.camera),
              //   ),
              // ),
              textContainerWithLabel(
                  'Nama Outlet', '', companyNameController, 50.0, false),
              textContainerWithLabel(
                  'Nomor Kwitansi', '', invoiceNumberController, 50.0, false),
              textContainerWithLabel(
                  'Tanggal Kwitansi', '', invoiceDateController, 50.0, false),
              textContainerWithLabel('Total Nilai Kwitansi', '',
                  invoiceAmountController, 50.0, false),
            ]),
          ),
        ]),
        Visibility(
          visible: isLoading,
          child: Container(
              height: double.infinity,
              width: double.infinity,
              color: Colors.grey.withOpacity(0.8),
              child: Center(child: CircularProgressIndicator())),
        ),
      ]),
    );
  }

  Future _getImage(ImageSource source) async {
    List<TextKnown> extractedData = [];
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile == null) return;
    File? image = File(pickedFile.path);
    image = await _cropImage(imageFile: image);
    setState(() {
      isLoading = true;
    });

    if (image != null) {
      imageFinalInvoice = image;
      extractedData = await ocrConverter.processPickedFile(image);
    } else {
      isLoading = false;
    }

    setState(() {
      companyNameController.text =
          invoiceController.getCompanyName(extractedData);
      invoiceNumberController.text =
          invoiceController.getInvoiceNumber(extractedData);
      invoiceDateController.text =
          invoiceController.getInvoiceDate(extractedData);
      invoiceAmountController.text =
          invoiceController.getInvoiceTotal(extractedData);
    });
    isLoading = false;
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

  bool isDate(String str) {
    try {
      // DateFormat('EEEE, MMM d, yyyy', "id_ID").format(DateTime.parse(str))
      //                   .toString();
      DateTime.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
