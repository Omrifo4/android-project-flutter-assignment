import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

import 'package:hello_me/login_page.dart';
import 'package:hello_me/user_repository.dart';
import 'package:hello_me/saved_user_data_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => UserRepository.instance(),
        child: Consumer<UserRepository>(builder: (context, userRepo, _) {
          return MaterialApp(
            title: 'Welcome to Flutter',
            theme: ThemeData(
              primaryColor: Colors.red,
            ),
            home: RandomWords(),
          );
        }));
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  Set<WordPair> _saved = Set<WordPair>();
  final _biggerFont = const TextStyle(fontSize: 18);
  var _sheetController = SnappingSheetController();
  double _moveAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRepo, _) {
      return Scaffold(
        appBar: AppBar(title: Text('Startup Name Generator'), actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          (userRepo.status == Status.Authenticated)
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () async {
                    final user =
                        Provider.of<UserRepository>(context, listen: false);
                    updateSuggestionsOnLogout();
                    await user.signOut();
                  })
              : IconButton(
                  icon: Icon(Icons.login),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (context) =>
                              LoginPage(updateSuggestionsOnLogin))))
        ]),
          body: Builder(builder: (context) {
            if (userRepo.status == Status.Authenticated) {
              return SnappingSheet(
                  snappingSheetController: _sheetController,
                  grabbingHeight: MediaQuery.of(context).padding.bottom + 50,
                  grabbing: Material(
                    child: InkWell(
                      child: Container(
                          color: Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Welcome back, ${userRepo.user.email}",
                                style: TextStyle(fontSize: 18),
                              ),
                              Icon(Icons.keyboard_arrow_up),
                            ],
                          )),
                      onTap: () {
                        setState(() {
                          if (_sheetController.snapPositions.last !=
                              _sheetController.currentSnapPosition) {
                            _sheetController.snapToPosition(
                                _sheetController.snapPositions.last);
                          } else {
                            _sheetController.snapToPosition(
                                _sheetController.snapPositions.first);
                          }
                        });
                      },
                    ),
                  ),
                  onMove: (moveAmount) {
                    setState(() {
                      _moveAmount = moveAmount;
                    });
                  },
                  sheetBelow:
                  SnappingSheetContent(child: Builder(builder: (context) {
                    return Container(
                      height: (_moveAmount > 0) ? _moveAmount : 0,
                      color: Colors.white,
                      alignment: Alignment.topCenter,
                      child: Material(
                        child: ListView(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 1.0),
                            children: [
                              ListTile(
                                  leading: (userRepo.status == Status.Authenticated) ? StreamBuilder<String>(
                                      stream:
                                      SavedUserDataRepository.instance()
                                          .getUserProfilePictureName(
                                          userRepo.user),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data.isNotEmpty) {
                                          var imageName = snapshot.data;
                                          return FutureBuilder(
                                              future: SavedUserDataRepository
                                                  .instance()
                                                  .fetchUserProfilePictureUrl(
                                                  userRepo.user,
                                                  imageName),
                                              builder: (context, snapshot) {
                                                return (snapshot.hasData) ? CircleAvatar(
                                                    backgroundImage: NetworkImage(snapshot.data)) : CircleAvatar(backgroundColor: Colors.white,);
                                              });
                                        } else {
                                          return CircleAvatar(backgroundColor: Colors.white,);
                                        }
                                      }) : CircleAvatar(backgroundColor: Colors.white,),
                                  title: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userRepo.user.email,
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Builder(
                                          builder: (context) => FlatButton(
                                            color: Colors.green,
                                            child: Text(
                                              'Update avatar',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            onPressed: () async {
                                              final userRepo = Provider.of<UserRepository>(context, listen: false);
                                              FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.image);

                                              if (result != null) {
                                                File file = File(result.files.single.path);
                                                setState(() {});
                                                SavedUserDataRepository.instance().updateUserProfilePicture(userRepo.user, file);
                                              } else {
                                                Scaffold.of(context).showSnackBar(SnackBar(content: Text('No image selected')));
                                              }
                                            },
                                          ),
                                        ),
                                      ])),
                            ]),
                      ),
                    );
                  })),
                  snapPositions: const [
                    SnapPosition(positionPixel: 0.0),
                    SnapPosition(positionFactor: 0.15),
                  ],
                  child: _buildSuggestions());
            } else {
              return _buildSuggestions();
            }
          }
      ));
    });
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final pageBody = StatefulBuilder(builder: (context, setInnerState) {
            var userRepo = Provider.of<UserRepository>(context);
            if (userRepo.status != Status.Authenticated) {
              // Build a list tile for each saved name.
              final tiles = _saved.map(
                (WordPair pair) {
                  return ListTile(
                    title: Text(
                      pair.asPascalCase,
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setInnerState(() {
                            _saved.remove(pair);
                            setState(() {});
                          });
                        }),
                  );
                },
              ).toList();

              // Create a divided list from the tiles created earlier.
              final divided = ListTile.divideTiles(
                context: context,
                tiles: tiles,
              ).toList();

              // Return a view for the divided list.
              return ListView(children: divided);
            } else {
              return StreamBuilder<List<WordPair>>(
                  stream: SavedUserDataRepository.instance()
                      .getUserSavedSuggestions(userRepo.user),
                  builder: (context, snapshot) {
                    Set<WordPair> totalPairs;
                    if (snapshot.hasData) {
                      totalPairs = (snapshot.data + _saved.toList()).toSet();
                      // update _saved if needed.
                      _saved = totalPairs;
                    } else {
                      totalPairs = _saved;
                    }

                    // Build a list tile for each saved name.
                    final tiles = totalPairs.map(
                      (WordPair pair) {
                        return ListTile(
                          title: Text(
                            pair.asPascalCase,
                            style: const TextStyle(fontSize: 18),
                          ),
                          trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                setState(() {
                                  _saved.remove(pair);
                                });
                                await SavedUserDataRepository.instance()
                                    .deleteWordPair(userRepo.user, pair);
                              }),
                        );
                      },
                    ).toList();

                    // Create a divided list from the tiles created earlier.
                    final divided = ListTile.divideTiles(
                      context: context,
                      tiles: tiles,
                    ).toList();

                    // Return a view for the divided list.
                    return ListView(children: divided);
                  });
            }
          });
          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: pageBody,
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),

        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () async {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
        final userRepo = Provider.of<UserRepository>(context, listen: false);
        if (userRepo.status == Status.Authenticated) {
          if (alreadySaved) {
            await SavedUserDataRepository.instance()
                .deleteWordPair(userRepo.user, pair);
          } else {
            await SavedUserDataRepository.instance()
                .addWordPair(userRepo.user, pair);
          }
        }
      },
    );
  }

  Future updateSuggestionsOnLogin() async {
    final userRepo = Provider.of<UserRepository>(context, listen: false);
    final updatedSaved = await SavedUserDataRepository.instance()
        .updateUserSavedSuggestions(userRepo.user, _saved);

    setState(() {
      _saved = updatedSaved.toSet();
    });

    return Future.delayed(Duration.zero);
  }

  void updateSuggestionsOnLogout() {
    _saved.clear();
  }
}
