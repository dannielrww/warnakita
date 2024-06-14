import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:warnakita/my_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warnakita/services/database_service.dart';

class UploadScreen extends StatefulWidget
{
  @override
  State<StatefulWidget> createState() {
    return UploadScreenState(); 
  }
}

class UploadScreenState extends State<UploadScreen>
{
  XFile? _imageFile;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _kodeWarnaController = TextEditingController();
  final TextEditingController _ukuranController = TextEditingController();


  Future<void> _postToFirestore(String? imageUrl) async {
    // Trim seluruh text dari controller
    String nama = _namaController.text.trim();
    String brand = _brandController.text.trim();
    String kodeWarna = _kodeWarnaController.text.trim();
    String ukuran = _ukuranController.text.trim();

    // Cek apakah text field terisi atau tidak
    if (nama.isEmpty ||
        brand.isEmpty ||
        kodeWarna.isEmpty ||
        ukuran.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Semua bagian harus diisi sebelum upload!')),
      );
      return;
    } else {
      try {
        await FirebaseFirestore.instance.collection(DatabaseService.collectionName).add({
          DatabaseService.KEY_NAMA: nama,
          DatabaseService.KEY_BRAND: brand,
          DatabaseService.KEY_KODE_WARNA: kodeWarna,
          DatabaseService.KEY_UKURAN: ukuran,

          DatabaseService.KEY_IMAGE_URL: imageUrl,
          DatabaseService.KEY_TIMESTAMP: FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil upload!')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Gagal post, coba lagi beberapa saat!')),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: 250,
                  child: _imageFile != null
                      ? Image.network(
                          _imageFile!.path,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.black,
                            ),
                          ),
                          child: const Center(child: Text('No Image')),
                        )),
              
              
              const SizedBox(height: 18.0),
              
              TextButton(
                onPressed: _pickImage,
                child: const Text("Pick Image"),
              ),
              
              const SizedBox(height: 18.0),
              //
              //
              MyTextField(
                  controller: _namaController,
                  hintText: 'Nama',
                  obscureText: false),
              MyTextField(
                  controller: _brandController,
                  hintText: 'Brand',
                  obscureText: false),
              MyTextField(
                  controller: _kodeWarnaController,
                  hintText: 'Kode Warna',
                  obscureText: false),
              MyTextField(
                  controller: _ukuranController,
                  hintText: 'Ukuran',
                  obscureText: false),
              //
              const SizedBox(height: 64.0),
              
              
              ElevatedButton(
                onPressed: () async {
                  String? imageUrl;
                  if (_imageFile != null) {
                    imageUrl = await DatabaseService.uploadImage(_imageFile!);
                  } else {
                    imageUrl = '';
                  }
                  _postToFirestore(imageUrl);
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}