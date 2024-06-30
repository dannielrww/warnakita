import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:warnakita/screens/sign_in_screen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  File? _image;
  String? _imageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  late BuildContext scaffoldContext; // Variable to store context

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData =
            await _firestore.collection('Users').doc(user.uid).get();
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _genderController.text = userData['gender'] ?? '';
          _statusController.text = userData['status'] ?? '';
          _imageUrl = userData['imageUrl'] ?? '';
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _uploadImage();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      final fileName = basename(_image!.path);
      final destination = 'profile_pics/$fileName';

      // Upload image to Firebase Storage
      TaskSnapshot taskSnapshot =
          await FirebaseStorage.instance.ref(destination).putFile(_image!);
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });

      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'imageUrl': downloadUrl,
        });
      }

      // Show success message using ScaffoldMessenger
      _showSnackbar('Image uploaded successfully');
    } catch (e) {
      print('Error occurred while uploading image: $e');
      // Show error message using ScaffoldMessenger
      _showSnackbar('Failed to upload image');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(_scaffoldMessengerKey.currentContext!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('Users').doc(user.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'gender': _genderController.text,
          'status': _statusController.text,
          'imageUrl': _imageUrl,
        });
        _showSnackbar('User data saved successfully');
      } catch (e) {
        print('Error saving user data: $e');
        _showSnackbar('Failed to save user data');
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(scaffoldContext).pushReplacement(
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context; // Store context during build
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple.shade100,
          title: Text('Profile'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: Colors.purple.shade100,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : _imageUrl != null
                              ? NetworkImage(_imageUrl!)
                              : AssetImage('assets/google_icon.png')
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: _genderController,
                  decoration: InputDecoration(labelText: 'Gender'),
                ),
                SizedBox(height: 20),
                Text('Status:', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                TextField(
                  controller: _statusController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveUserData,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProfilePage(),
  ));
}
