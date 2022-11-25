import 'package:ocr/features/invoice_detection/models/text_recognize_model.dart';
import 'package:ocr/shared/constant.dart';

class KTPController {
  String getNIK(List<TextKnown> ktpData) {
    String nik = '';

    try {
      final filteredData =
          ktpData.where((element) => filterData(14, element.textKnown)).first;

      if (filteredData.textKnown.trim().length != 16) {
        nik = filteredData.textKnown
            .toLowerCase()
            .replaceAll(RegExp("nik|:|#"), '')
            .trim();
      } else {
        nik = filteredData.textKnown;
      }
    } catch (e) {
      nik = '';
    }
    return nik;
  }

  String getKTPName(List<TextKnown> ktpData) {
    String ktpName = '';
    try {
      final filteredData = ktpData
          .where((element) => element.textKnown.toLowerCase().contains("nama"))
          .first;

      for (var data in ktpData) {
        if (data.leftPosition > filteredData.leftPosition &&
            (data.topPosition - filteredData.topPosition).abs() < 20 &&
            data.textKnown != filteredData.textKnown) {
          ktpName =
              data.textKnown.toLowerCase().replaceAll(RegExp(":"), '').trim();
          break;
        }
      }
    } catch (e) {
      ktpName = '';
    }
    return ktpName;
  }

  String getKTPBirthDate(String nik, String gender) {
    String birthDate = '';
    String tanggalLahir = nik.substring(6, 8);
    if (gender == 'perempuan') {
      var temp = int.parse(tanggalLahir) - 40;
      tanggalLahir = temp.toString();
    }
    String bulanLahir = nik.substring(8, 10);
    bulanLahir = convertBulan[bulanLahir];
    String tahunLahir = nik.substring(10, 12);
    var tahun = DateTime(DateTime.now().year);
    var limitYear = int.parse(tahun.year.toString().substring(2, 4)) - 17;
    if (int.parse(nik.substring(10, 12)) > limitYear) {
      tahunLahir = '19' + tahunLahir;
    } else {
      tahunLahir = '20' + tahunLahir;
    }
    return '$tanggalLahir $bulanLahir $tahunLahir';
  }

  String getKTPGender(List<TextKnown> ktpData) {
    String gender = '';
    try {
      final filteredData = ktpData
          .where((element) => element.textKnown.toLowerCase().contains("laki"))
          .first;

      gender = 'laki-laki';
    } catch (e) {
      gender = 'perempuan';
    }
    return gender;
  }

  bool filterData(counterData, data) {
    int counter = 0;
    for (var i = 0; i < data.length; i++) {
      if (data[i].contains(RegExp(r'[0-9]'))) {
        counter++;
      }
    }

    if (counter > counterData) {
      return true;
    } else {
      return false;
    }
  }
}
