import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:warnakita/screens/sign_in_screen.dart';
import 'package:warnakita/screens/sign_up_screen.dart';

void main() {
  runApp(HomeScreen());
}

class HomeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState()
    => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
{
    int pageIndex = 0;

    @override
    Widget build(BuildContext context) {

     const List<Widget> navbarItems = [
        NavigationDestination(icon: Icon(Icons.home), label: ''),
        NavigationDestination(icon: Icon(Icons.add_box), label: ''),
        NavigationDestination(icon: Icon(Icons.favorite), label: ''),
        NavigationDestination(icon: Icon(Icons.person_outline), label: ''),
      ];

    void onIndexChanged(int index)
    {
      setState(() {
        pageIndex = index;
      });
    }

      NavigationBar navBar = new NavigationBar(destinations: navbarItems, onDestinationSelected: onIndexChanged, selectedIndex: pageIndex);

      // TODO: Replace with real page
      Widget page1 = HomePage();
      Widget page2 = SignInScreen();
      Widget page3 = HomePage();
      Widget page4 = SignUpScreen();
      var pages = [page1,page2,page3,page4];
  
    Widget getActivePage()
    {
      return pages[pageIndex];
    }

    return Scaffold(
      body: getActivePage(),
      bottomNavigationBar: navBar,
    );
  }
}

class HomePage extends StatelessWidget {
  
  var homeScreenBody = SafeArea(
        child: Column(
          children: [
            SearchBar(),
            Expanded(
              child: ListView(
                children: [
                  StoreCard(
                    imagePath: 'assets/Toko_Cat_warna_abadi.png',
                    storeName: 'Toko Cat Warna Abadi',
                  ),
                  StoreCard(
                    imagePath: 'assets/Toko_Cat_Mutiara_Indah.png',
                    storeName: 'Toko Cat Mutiara Indah',
                  ),
                ],
              ),
            ),
          ],
        ),
      );


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade100,
        elevation: 0,
        toolbarHeight: 0, // Hides the AppBar
      ),
      backgroundColor: Colors.purple.shade100,
      body: homeScreenBody,
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
            Image.asset(imagePath),
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