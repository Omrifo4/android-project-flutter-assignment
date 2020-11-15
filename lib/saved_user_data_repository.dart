import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SavedUserDataRepository {
  FirebaseFirestore _store;
  FirebaseStorage _storage;
  final _suggestionsCollectionPath = 'savedSuggestions';
  final _profilePicsCollectionPath = 'profilePicsPaths';
  final _profilePicsPath = 'profilePics';

  SavedUserDataRepository.instance()
      : _store = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  Stream<List<WordPair>> getUserSavedSuggestions(User user) {
    return _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .snapshots()
        .map((doc) => _convertArrayToWordPairs(doc['saved']));
  }

  Stream<String> getUserProfilePictureName(User user) {
    return _store
        .collection(_profilePicsCollectionPath)
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc['profilePic'] is String &&
          (doc['profilePic'] as String).isNotEmpty) {
        return doc['profilePic'];
      } else {
        return '';
      }
    });
  }

  Future<String> fetchUserProfilePictureUrl(User user, String picName) async {
    return _storage.ref(_profilePicsPath).child(picName).getDownloadURL();
  }

  Future addNewUserDocuments(User user) async {
    return _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .get()
        .then((docSnapshot) {
      if (!docSnapshot.exists) {
        _store
            .collection(_suggestionsCollectionPath)
            .doc(user.uid)
            .set({'saved': []});

        _store
            .collection(_profilePicsCollectionPath)
            .doc(user.uid)
            .set({'profilePic': ''});
      }
    });
  }

  Future addWordPair(User user, WordPair pair) async {
    var savedArray = await _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .get()
        .then((doc) => doc['saved']);

    List<WordPair> userWordPairs = _convertArrayToWordPairs(savedArray);

    if (!userWordPairs.contains(pair)) {
      userWordPairs.add(pair);
      await _store
          .collection(_suggestionsCollectionPath)
          .doc(user.uid)
          .set({'saved': _convertWordPairsToArray(userWordPairs)});
    }

    return Future.delayed(Duration.zero);
  }

  Future deleteWordPair(User user, WordPair pair) async {
    var savedArray = await _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .get()
        .then((doc) => doc['saved']);

    List<WordPair> userWordPairs = _convertArrayToWordPairs(savedArray);

    if (userWordPairs.contains(pair)) {
      userWordPairs.remove(pair);
      await _store
          .collection(_suggestionsCollectionPath)
          .doc(user.uid)
          .set({'saved': _convertWordPairsToArray(userWordPairs)});
    }

    return Future.delayed(Duration.zero);
  }

  Future<List<WordPair>> updateUserSavedSuggestions(
      User user, Set<WordPair> localPairs) async {
    var savedArray = await _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .get()
        .then((doc) => doc['saved']);

    List<WordPair> userWordPairs = _convertArrayToWordPairs(savedArray);
    userWordPairs.addAll(localPairs);
    // remove duplications but keep the order.
    final seen = Set<WordPair>();
    final uniquePairs = userWordPairs.where((pair) => seen.add(pair)).toList();
    await _store
        .collection(_suggestionsCollectionPath)
        .doc(user.uid)
        .set({'saved': _convertWordPairsToArray(uniquePairs)});

    return uniquePairs;
  }

  Future<String> _updateUserProfilePictureUrl(
      User user, String filename) async {
    await _store
        .collection(_profilePicsCollectionPath)
        .doc(user.uid)
        .set({'profilePic': filename});

    return filename;
  }

  Future _removeUserProfilePic(User user) async {
    var prevName = await _store
        .collection(_profilePicsCollectionPath)
        .doc(user.uid)
        .get()
        .then((doc) => doc['profilePic']);

    if (prevName.isEmpty) {
      return Future.delayed(Duration.zero);
    } else {
      return _storage.ref(_profilePicsPath).child(prevName).delete();
    }
  }

  Future<String> updateUserProfilePicture(User user, File file) async {
    // Delete the former picture.
    await _removeUserProfilePic(user);

    final filename = '${user.uid}-${DateTime.now().millisecondsSinceEpoch}';

    await _storage.ref(_profilePicsPath).child(filename).putFile(file);

    return _updateUserProfilePictureUrl(user, filename);
  }

  List<WordPair> _convertArrayToWordPairs(List<dynamic> userArray) {
    // Each item is a '<FIRST_WORD>,<SECOND_WORD>' WordPair string.
    // Map each item to it's actual pair.
    return userArray.map((item) {
      final splitPair = (item as String).split(',');
      return WordPair(splitPair[0], splitPair[1]);
    }).toList();
  }

  List<String> _convertWordPairsToArray(List<WordPair> wordPairs) {
    // Map each item to '<FIRST_WORD>,<SECOND_WORD>' string.
    return wordPairs.map((pair) => ('${pair.first},${pair.second}')).toList();
  }
}
