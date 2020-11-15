import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hello_me/saved_user_data_repository.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Status get status => _status;
  User get user => _user;

  Future registerUser(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<bool> signIn(String email, String password, updateOnLogin) async {
    try {
      // Mark status as currently in authentication process.
      _status = Status.Authenticating;
      notifyListeners();

      // Try to log in the user using his credentials.
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // If this code is executed, the user is successfully logged in.

      // Add a document to DB if this is a new user.
      await SavedUserDataRepository.instance().addNewUserDocuments(user);

      // Update information according to user state.
      await updateOnLogin();
      // Return true as the log in was successful.
      // Note: status is changed using 'onAuthStateChanged' callback function.
      return true;
    } catch (e) {
      // Mark the user as unauthenticated, as log in failed.
      _status = Status.Unauthenticated;
      notifyListeners();

      // Return false as log in failed.
      return false;
    }
  }

  Future signOut() async {
    await _auth.signOut();

    _status = Status.Unauthenticated;
    notifyListeners();
    _user = null;

    // A workaround for a 'void returning async function'?
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User user) async {
    if (user == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = user;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}