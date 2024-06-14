import 'package:cloud_firestore/cloud_firestore.dart';

class Paint {
  String? id;
  final String nama;
  final String brand;
  final String ukuran;
  final String kodeWarna;
  String? imageUrl;
  Timestamp? timestamp;

  Paint(
      {this.id,
      required this.nama,
      required this.brand,
      required this.kodeWarna,
      required this.ukuran,
      this.imageUrl,
      this.timestamp});
}
