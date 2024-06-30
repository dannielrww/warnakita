import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:warnakita/screens/home_screen.dart';
import 'package:warnakita/screens/sign_up_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  ValueNotifier userCredential = ValueNotifier('');

  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: [
          'email',
        ],
        clientId:
            '206492858709-ik1k7ip0g0olmm4d06f95ue3nkh7j9ob.apps.googleusercontent.com', // WEB CLIENT ID
      ).signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on Exception catch (e) {
      // TODO
      print('exception->$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC58BF2),
      appBar: AppBar(
        title: const Text('LOGIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                'assets/Warna_Kita.png', // Ganti dengan path logo Anda
                width: 200.0,
                height: 200.0,
              ),
              const SizedBox(height: 32.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(elevation: 5),
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
// Validasi email
                  if (email.isEmpty || !isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid email')),
                    );
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } on FirebaseAuthException catch (error) {
                    print('Error code: ${error.code}');
                    if (error.code == 'user-not-found') {
                      // Jika email tidak terdaftar, tampilkan pesan kesalahan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No user found with that email')),
                      );
                    } else if (error.code == 'wrong-password') {
                      // Jika password salah, tampilkan pesan kesalahan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Wrong password. Please try again.')),
                      );
                    } else {
                      // Jika terjadi kesalahan lain, tampilkan pesan kesalahan umum
                      setState(() {
                        _errorMessage = error.message ?? 'An error occurred';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_errorMessage),
                        ),
                      );
                    }
                  } catch (error) {
                    // Tangani kesalahan lain yang tidak terkait dengan otentikasi

                    setState(() {
                      _errorMessage = error.toString();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_errorMessage),
                      ),
                    );
                  }
                },
                child: const Text(' LOGIN'),
              ),
              const SizedBox(height: 32.0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
              const SizedBox(height: 32.0),
              const Text(
                "--- Or Sign In With ---",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32.0),
              ValueListenableBuilder(
                valueListenable: userCredential,
                builder: (context, value, child) {
                  return Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 5),
                      onPressed: () async {
                        userCredential.value = await signInWithGoogle();
                        if (userCredential.value != null)
                          print(userCredential.value.user!.email);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_icon.png',
                          ),
                          const Text('Sign in with Google')
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk memeriksa validitas email
  bool isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
    RegExp regex = RegExp(emailRegex);
    return regex.hasMatch(email);
  }
}
