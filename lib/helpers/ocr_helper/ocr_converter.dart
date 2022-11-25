import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr/features/invoice_detection/models/text_recognize_model.dart';
import 'package:ocr/helpers/ocr_helper/ocr_painter.dart';
import 'package:ocr/shared/constant.dart';

class OCRConverter {
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  ImagePicker imagePicker = ImagePicker();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  File? _image;
  String? _path;

  Future<List<TextKnown>> processPickedFile(File pickedFile) async {
    final path = pickedFile.path;
    _image = File(path);

    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    List<TextKnown> finalData = await processImage(inputImage);
    return finalData;
  }

  Future<List<TextKnown>> processImage(InputImage inputImage) async {
    final recognizedText = await textRecognizer.processImage(inputImage);
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
        // listExtractedTexts.add({
        //   'text': line.text,

        // });
        textKnowns.add(TextKnown(
            textKnown: line.text,
            topPosition: line.boundingBox.top,
            leftPosition: line.boundingBox.left,
            isDate: false));
      }
    }
    try {
      textKnowns.sort(((a, b) => a.topPosition.compareTo(b.topPosition)));
    } catch (ex) {
      print(ex.toString());
    }

    _isBusy = false;

    return textKnowns;
  }
}
