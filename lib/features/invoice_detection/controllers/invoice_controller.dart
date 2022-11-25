import 'package:intl/intl.dart';
import 'package:ocr/features/invoice_detection/models/text_recognize_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class InvoiceController {
  String getCompanyName(List<TextKnown> dataInvoice) {
    String tempCompanyName = '';
    try {
      // find company name based on keys
      final companyName = dataInvoice
          .where((element) =>
              element.textKnown.contains("PT") ||
              element.textKnown.contains("CV") ||
              element.textKnown.contains("corp"))
          .first;

      tempCompanyName = companyName.textKnown;
    } catch (e) {
      tempCompanyName = '';
    }
    return tempCompanyName;
  }

  String getInvoiceNumber(List<TextKnown> dataInvoice) {
    String tempNumber = '';
    // find invoice number based on pattern and coordinate
    try {
      final invoiceNumber = dataInvoice
          .where(
              (element) => element.textKnown.toLowerCase().contains("invoice"))
          .first;

      if (invoiceNumber.textKnown.length == 'invoice'.length) {
        for (var data in dataInvoice) {
          if ((data.leftPosition - invoiceNumber.leftPosition).abs() < 41 &&
              data.leftPosition > invoiceNumber.leftPosition &&
              (data.topPosition - invoiceNumber.topPosition).abs() < 10 &&
              data.textKnown != invoiceNumber.textKnown) {
            tempNumber = data.textKnown
                .toLowerCase()
                .replaceAll(RegExp("invoice|no.|no|:|#"), '')
                .trim();
            break;
          }
        }

        if (tempNumber == '') {
          for (var data in dataInvoice) {
            if ((data.topPosition - invoiceNumber.topPosition).abs() < 41 &&
                data.topPosition > invoiceNumber.topPosition &&
                data.textKnown != invoiceNumber.textKnown) {
              tempNumber = data.textKnown
                  .toLowerCase()
                  .replaceAll(RegExp("invoice|no.|no|:\#"), '')
                  .trim();
              break;
            }
          }
        }
      } else {
        tempNumber = invoiceNumber.textKnown
            .toLowerCase()
            .replaceAll(RegExp("invoice|no.|no|:|#"), '')
            .trim();
      }
    } catch (e) {
      tempNumber = '';
    }
    return tempNumber;
  }

  String getInvoiceDate(List<TextKnown> dataInvoice) {
    String tempDate = '';
    try {
      final invoiceNumber = dataInvoice
          .where((element) =>
              element.textKnown.toLowerCase().contains("tanggal") ||
              element.textKnown.toLowerCase().contains("tgl"))
          .first;

      if (!checkStringContainDate(invoiceNumber.textKnown)) {
        for (var data in dataInvoice) {
          if (data.leftPosition > invoiceNumber.leftPosition &&
              (data.topPosition - invoiceNumber.topPosition).abs() < 10 &&
              data.textKnown != invoiceNumber.textKnown) {
            tempDate = data.textKnown
                .toLowerCase()
                .replaceAll(RegExp("tanggal|tgl|:"), '')
                .trim();
            break;
          }
        }
      } else {
        tempDate = invoiceNumber.textKnown
            .toLowerCase()
            .replaceAll(RegExp("tanggal|tgl|:"), '')
            .trim();
      }
    } catch (e) {
      tempDate = '';
    }

    return tempDate;
  }

  String getInvoiceTotal(List<TextKnown> dataInvoice) {
    String tempInvoice = '';
    try {
      final invoiceNumber = dataInvoice
          .where((element) => element.textKnown.toLowerCase().contains("total"))
          .last;

      if (!checkStringContainDate(invoiceNumber.textKnown)) {
        for (var data in dataInvoice) {
          if (data.leftPosition > invoiceNumber.leftPosition &&
              (data.topPosition - invoiceNumber.topPosition).abs() < 10 &&
              data.textKnown != invoiceNumber.textKnown) {
            tempInvoice = data.textKnown
                .toLowerCase()
                .replaceAll(RegExp("total|grand|:|rp"), '')
                .trim();
            break;
          }
        }
      } else {
        tempInvoice = invoiceNumber.textKnown
            .toLowerCase()
            .replaceAll(RegExp("total|grand|:|rp"), '')
            .trim();
      }
    } catch (e) {
      tempInvoice = '';
    }

    return tempInvoice;
  }

  bool checkStringContainDate(data) {
    int counter = 0;
    for (var i = 0; i < data.length; i++) {
      if (data[i].contains(new RegExp(r'[0-9]'))) {
        counter++;
      }
    }

    if (counter > 3) {
      return true;
    } else {
      return false;
    }
  }

  bool isDate(String str) {
    try {
      var dateString = str;
      DateFormat format = new DateFormat("MMMM dd, yyyy", "id_ID");
      var formattedDate = format.parse(dateString);
      // DateFormat('dd MMMM yyyy', "id_ID").format(DateTime.parse(str));
      //                   .toString();
      // DateTime.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
