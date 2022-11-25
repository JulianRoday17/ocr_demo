import 'dart:io';

List itemData = [];
List finalItem = [];
File? imageFinalInvoice;
File? imageFinalKTP;
List<String> CompanyName = ["PT", "CV", "inc"];

Map convertBulan = {
  '01': 'Januari',
  '02': 'Februari',
  '03': 'Maret',
  '04': 'April',
  '05': 'Mei',
  '06': 'Juni',
  '07': 'Juli',
  '08': 'Agustus',
  '09': 'September',
  '10': 'OKtober',
  '11': 'November',
  '12': 'Desember',
};
