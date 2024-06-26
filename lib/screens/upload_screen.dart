import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PostingScreen(),
    );
  }
}

class PostingScreen extends StatefulWidget {
  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitData() async {
    if (_image == null) return;

    final String name = _nameController.text;
    final String description = _descriptionController.text;
    final String location = _locationController.text;

    if (name.isNotEmpty && description.isNotEmpty && location.isNotEmpty) {
      String imageUrl = await _uploadImage(_image!);

      await FirebaseFirestore.instance.collection('posts').add({
        'name': name,
        'description': description,
        'location': location,
        'image_url': imageUrl,
      });

      _nameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      setState(() {
        _image = null;
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName = image.path.split('/').last;
    Reference storageReference =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    UploadTask uploadTask = storageReference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    return await taskSnapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo,
                        color: Colors.grey[700], size: 50),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Lokasi Toko',
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('POSTING'),
            ),
          ],
        ),
      ),
    );
  }
}
