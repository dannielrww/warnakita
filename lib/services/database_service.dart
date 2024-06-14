import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:warnakita/models/item_cat.dart';

class DatabaseService {

   static const String collectionName = "paints";

   static const String KEY_NAMA = "name";
   static const String KEY_BRAND = "brand";
   static const String KEY_UKURAN = "ukuran";
   static const String KEY_KODE_WARNA = "kodeWarna";

   static const String KEY_IMAGE_URL = "imageUrl";
   static const String KEY_TIMESTAMP = "timestamp";

  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _paintCollection =
      _database.collection(collectionName);
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(XFile file) async {
    try {
      String fileName = path.basename(file.path);
      Reference ref = _storage.ref().child('images').child('/$fileName');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        uploadTask = ref.putFile(io.File(file.path));
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  static Stream<List<Paint>> getPaintList() {
    return _paintCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Paint(
          nama: data[KEY_NAMA],
          brand: data[KEY_BRAND],
          kodeWarna: data[KEY_KODE_WARNA],
          ukuran: data[KEY_UKURAN],
          imageUrl: data[KEY_IMAGE_URL],
          timestamp: data[KEY_TIMESTAMP],
        );
      }).toList();
    });
  }
}
