import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:warnakita/screens/profile_screen.dart';
import 'package:warnakita/screens/sign_in_screen.dart';
import 'package:warnakita/screens/sign_up_screen.dart';
import 'package:warnakita/screens/upload_screen.dart';
import 'package:warnakita/screens/favorites.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    Widget page3 = Favorites();
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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

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
            SearchBar(
              onChanged: updateSearchQuery,
            ),
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
                  final filteredStores = stores.where((store) {
                    return store['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredStores.length,
                    itemBuilder: (context, index) {
                      final store = filteredStores[index];
                      return StoreCard(
                        storeId: store.id,
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
  final ValueChanged<String> onChanged;

  SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: onChanged,
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

class StoreCard extends StatefulWidget {
  final String storeId;
  final String imagePath;
  final String storeName;

  StoreCard({
    required this.storeId,
    required this.imagePath,
    required this.storeName,
  });

  @override
  _StoreCardState createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('storeId', isEqualTo: widget.storeId)
        .get();
    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        isFavorite = true;
      });
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      // Save favorite data to Firestore
      await FirebaseFirestore.instance.collection('favorites').add({
        'storeId': widget.storeId,
        'image_url': widget.imagePath,
        'name': widget.storeName,
      });

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toko ditambahkan ke favorite')),
      );
    } else {
      // Remove favorite data from Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toko dihapus dari favorite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.purple.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.imagePath),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null),
                    onPressed: () => _toggleFavorite(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
