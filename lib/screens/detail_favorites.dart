import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailFavoritesScreen extends StatefulWidget {
  final String storeId;

  DetailFavoritesScreen({required this.storeId});

  @override
  _DetailFavoritesScreenState createState() => _DetailFavoritesScreenState();
}

class _DetailFavoritesScreenState extends State<DetailFavoritesScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<DocumentSnapshot?> _fetchStoreDetails() async {
    var doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.storeId)
        .get();
    return doc.exists ? doc : null;
  }

  Future<void> _addComment(String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('comments')
          .add({
        'text': comment,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  Future<String> _fetchUserName(String userId) async {
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['name'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store Details'),
      ),
      body: Container(
        color: Colors.purple.shade100,
        child: FutureBuilder<DocumentSnapshot?>(
          future: _fetchStoreDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('Store not found'));
            }

            var storeData = snapshot.data!.data() as Map<String, dynamic>?;
            if (storeData == null) {
              return Center(child: Text('Store data is missing'));
            }

            return Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 200,
                  child: Image.network(
                    storeData['image_url'] ?? 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                  ),
                ),
                Text(storeData['name'] ?? 'N/A',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(storeData['location'] ?? 'N/A'),
                Text(storeData['description'] ?? 'N/A'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('stores')
                        .doc(widget.storeId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var comments = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var comment =
                              comments[index].data() as Map<String, dynamic>;
                          var userId = comment['userId'] as String?;
                          if (userId == null) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text(comment['text'] ?? 'No text'),
                                  subtitle: Text('Unknown User'),
                                ),
                              ),
                            );
                          }
                          return FutureBuilder<String>(
                            future: _fetchUserName(userId),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8.0),
                                    child: ListTile(
                                      title: Text(comment['text'] ?? 'No text'),
                                      subtitle: Text('Loading...'),
                                    ),
                                  ),
                                );
                              }
                              if (!userSnapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8.0),
                                    child: ListTile(
                                      title: Text(comment['text'] ?? 'No text'),
                                      subtitle: Text('Unknown User'),
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text(comment['text'] ?? 'No text'),
                                    subtitle: Text(
                                        userSnapshot.data ?? 'Unknown User'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration:
                              InputDecoration(hintText: 'Enter your comment'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            _addComment(_commentController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
