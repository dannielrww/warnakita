import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HomeScreen());
}

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    const List<Widget> navbarItems = [
      NavigationDestination(icon: Icon(Icons.home), label: ''),
      NavigationDestination(icon: Icon(Icons.add_box), label: ''),
      NavigationDestination(icon: Icon(Icons.favorite), label: ''),
      NavigationDestination(icon: Icon(Icons.person_outline), label: ''),
    ];

    void onIndexChanged(int index) {
      setState(() {
        pageIndex = index;
      });
    }

    NavigationBar navBar = NavigationBar(
      destinations: navbarItems,
      onDestinationSelected: onIndexChanged,
      selectedIndex: pageIndex,
    );

    // Pages
    Widget page1 = HomePage();
    Widget page2 = PostingScreen();
    Widget page3 = HomePage();
    Widget page4 = ProfilePage();
    var pages = [page1, page2, page3, page4];

    Widget getActivePage() {
      return pages[pageIndex];
    }

    return Scaffold(
      body: getActivePage(),
      bottomNavigationBar: navBar,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade100,
        elevation: 0,
        toolbarHeight: 0, // Hides the AppBar
      ),
      backgroundColor: Colors.purple.shade100,
      body: SafeArea(
        child: Column(
          children: [
            SearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('posts').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final stores = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return StoreCard(
                        imagePath: store['image_url'],
                        storeName: store['name'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  final String imagePath;
  final String storeName;

  StoreCard({required this.imagePath, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.purple.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imagePath),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.shopping_cart_outlined),
                  Icon(Icons.favorite_border),
                ],
              ),
            ),
          ],
        ),
      ),
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

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Text('Profile Page'),
      ),
    );
  }
}
