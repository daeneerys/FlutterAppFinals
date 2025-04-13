import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Sign In
  Future<User?> signIn(String email, String password) async {
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password
      );
      return result.user;
    } catch (e) {
      print("Login Failed: $e");
      return null;
    }
  }

  //Register
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password
      );

      User? user = result.user;

      if (user != null) {
        await DatabaseService().saveUserData(user.uid);
      }

      return user;
    } catch (e) {
      print("Registration Failed: $e");
      return null;
    }
  }

  //Sign Out
  Future<void> signOut() async{
    await _auth.signOut();
  }

  //Get Current User
  User? getCurrentUser(){
    return _auth.currentUser;
  }
}