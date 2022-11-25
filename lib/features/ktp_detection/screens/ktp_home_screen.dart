import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr/features/invoice_detection/models/text_recognize_model.dart';
import 'package:ocr/features/ktp_detection/controlllers/ktp_controller.dart';
import 'package:ocr/features/ktp_detection/models/ktp_model.dart';
import 'package:ocr/helpers/ocr_helper/ocr_converter.dart';
import 'package:ocr/shared/constant.dart';
import 'package:ocr/utils/input.utils.dart';

class KtpHomeScreen extends StatefulWidget {
  const KtpHomeScreen({super.key});

  @override
  State<KtpHomeScreen> createState() => _KtpHomeScreenState();
}

class _KtpHomeScreenState extends State<KtpHomeScreen> {
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
  TextEditingController nikController = TextEditingController();
  TextEditingController ktpNameController = TextEditingController();
  TextEditingController ktpBirthDateController = TextEditingController();
  TextEditingController ktpGenderController = TextEditingController();
  List<CameraDescription> cameras = [];

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  KTPModel ktpData = KTPModel(nik: '', name: '', birthDate: '', gender: '');
  OCRConverter ocrConverter = OCRConverter();
  KTPController ktpcontroller = KTPController();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();
    imageFinalKTP = null;
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
      body: Stack(children: [
        ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Visibility(
                visible: imageFinalKTP != null,
                child: Container(
                  height: 300,
                  width: 400,
                  child: Image.file(
                    imageFinalKTP ?? File(''),
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
                      child: Text('Pilih Gambar KTP'),
                      onPressed: () => _getImage(ImageSource.gallery),
                    ),
                    ElevatedButton(
                      child: Text('Reset'),
                      onPressed: () {
                        setState(() {
                          imageFinalKTP = null;
                          nikController.clear();
                          ktpNameController.clear();
                          ktpBirthDateController.clear();
                          ktpGenderController.clear();
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
              textContainerWithLabel('NIK', '', nikController, 50.0, false),
              textContainerWithLabel(
                  'Nama', '', ktpNameController, 50.0, false),
              textContainerWithLabel(
                  'Tanggal Lahir', '', ktpBirthDateController, 50.0, false),
              textContainerWithLabel(
                  'Jenis Kelamin', '', ktpGenderController, 50.0, false),
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
      imageFinalKTP = image;
      extractedData = await ocrConverter.processPickedFile(image);
    } else {
      isLoading = false;
    }

    setState(() {
      nikController.text = ktpcontroller.getNIK(extractedData);
      ktpNameController.text = ktpcontroller.getKTPName(extractedData);
      ktpGenderController.text = ktpcontroller.getKTPGender(extractedData);
      ktpBirthDateController.text = ktpcontroller.getKTPBirthDate(
          nikController.text, ktpGenderController.text);
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
}
