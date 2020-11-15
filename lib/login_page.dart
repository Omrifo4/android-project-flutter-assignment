import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:hello_me/user_repository.dart';

class LoginPage extends StatelessWidget {
  final updateOnLogin;

  LoginPage(this.updateOnLogin);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
        ),
        body: LoginForm(updateOnLogin));
  }
}

class LoginForm extends StatefulWidget {
  final updateOnLogin;

  LoginForm(this.updateOnLogin);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _confirmKey = GlobalKey<FormState>();
  TextEditingController _email;
  TextEditingController _password;
  TextEditingController _passwordConfirm;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _passwordConfirm = TextEditingController(text: "");
  }

  void _onLoginAttemptStart() async {
    final user = Provider.of<UserRepository>(context, listen: false);
    if (!await user.signIn(_email.text, _password.text, widget.updateOnLogin)) {
      final loginFailedSnackBar =
          SnackBar(content: Text("There was an error logging into the app"));
      Scaffold.of(context).showSnackBar(loginFailedSnackBar);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, user, _) {
      return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Center(
                child: Text(
                    'Welcome to Startup Names Generator, please log in below',
                    style: const TextStyle(fontSize: 18))),
            Form(
              child: Column(children: [
                TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password')),
                (user.status == Status.Authenticating)
                    ? Center(child: LinearProgressIndicator())
                    : FlatButton(
                        onPressed: _onLoginAttemptStart,
                        child: Text('Log in'),
                        padding: const EdgeInsets.all(8),
                        color: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.red)),
                        textColor: Colors.white,
                        minWidth: double.maxFinite,
                      ),
                FlatButton(
                  onPressed: () async {
                    final userRepo =
                        Provider.of<UserRepository>(context, listen: false);
                    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) {
                      return Container(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                            child: Form(
                              key: _confirmKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Please confirm your password below:"),
                                  TextFormField(
                                      controller: _passwordConfirm,
                                      decoration: const InputDecoration(
                                          labelText: 'Password'),
                                      validator: (text) => (_passwordConfirm.text == _password.text) ? null : 'Passwords must match'),
                                  FlatButton(onPressed: () async {
                                    if (_confirmKey.currentState.validate()) {
                                      userRepo.registerUser(_email.text, _password.text);
                                      Navigator.of(context).pop();
                                      _onLoginAttemptStart();
                                    }
                                  }, child: Text("Confirm"), color: Colors.green),
                                ],
                              ),
                            ),
                          ));
                    });
                  },
                  child: Text('New user? Click to sign up'),
                  padding: const EdgeInsets.all(8),
                  color: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.green)),
                  textColor: Colors.white,
                  minWidth: double.maxFinite,
                )
              ]),
            ),
          ]));
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }
}
