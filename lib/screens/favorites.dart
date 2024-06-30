import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warnakita/screens/detail_favorites.dart';

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade100,
        elevation: 0,
        toolbarHeight: 0, // Hides the AppBar
      ),
      backgroundColor: Colors.purple.shade100,
      body: Column(
        children: [
          Padding(
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
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('favorites')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var favoriteData = snapshot.data!.docs;
                var filteredData = favoriteData.where((favoriteItem) {
                  var storeName = favoriteItem['name'].toString().toLowerCase();
                  return storeName.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    var favoriteItem = filteredData[index];
                    var storeId = favoriteItem['storeId'];

                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(storeId)
                          .get(),
                      builder: (context, postSnapshot) {
                        if (!postSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!postSnapshot.data!.exists) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Post not found'),
                              ),
                            ),
                          );
                        }

                        var postItem = postSnapshot.data!;
                        bool isFavorite = favoriteData
                            .any((doc) => doc['storeId'] == storeId);

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: StoreCard(
                            storeId: storeId,
                            imagePath: postItem['image_url'],
                            storeName: postItem['name'],
                            isFavorite: isFavorite,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StoreCard extends StatefulWidget {
  final String storeId;
  final String imagePath;
  final String storeName;
  final bool isFavorite;

  StoreCard({
    required this.storeId,
    required this.imagePath,
    required this.storeName,
    required this.isFavorite,
  });

  @override
  _StoreCardState createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isFavorite = widget.isFavorite;
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      await FirebaseFirestore.instance.collection('favorites').add({
        'storeId': widget.storeId,
        'image_url': widget.imagePath,
        'name': widget.storeName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toko ditambahkan ke favorite')),
        );
      }
    } else {
      var snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toko dihapus dari favorite')),
        );
      }
    }
  }

  void _navigateToDetailFavorite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailFavoritesScreen(
          storeId: widget.storeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorite(context),
                ),
                GestureDetector(
                  onTap: () => _navigateToDetailFavorite(context),
                  child: Icon(Icons.comment, color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
