import 'package:authentication_with_firebase/authentication_with_firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _userController;
  TextEditingController _passController;

  String _user, _pass;

  @override
  void initState() {
    _userController = TextEditingController();
    _passController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Consumer<AuthenticationProvider>(
              builder: (_, provider, __) => provider.loading
                  ? CircularProgressIndicator()
                  : provider.user == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _userController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(8.0),
                                        labelText: "Email",
                                        hintText: "Email"),
                                    validator: (String value) {
                                      if (value == null || value.isEmpty)
                                        return "Debe ingresar un email valido";
                                      return null;
                                    },
                                    onSaved: (String v) {
                                      setState(() {
                                        _user = v;
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    height: 8.0,
                                  ),
                                  TextFormField(
                                    controller: _passController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(8.0),
                                        labelText: "Contraseña",
                                        hintText: "Contraseña"),
                                    obscureText: true,
                                    validator: (String value) {
                                      if (value == null || value.isEmpty)
                                        return "Debe ingresar una contraseña de al menos 8 caracteres";
                                      return null;
                                    },
                                    onSaved: (String v) {
                                      setState(() {
                                        _pass = v;
                                      });
                                    },
                                    onFieldSubmitted: (String v) =>
                                        _submit(provider),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 8.0,
                            ),
                            TextButton(
                              onPressed: () => _submit(provider),
                              child: Text(
                                "Iniciar sesión",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    .copyWith(color: Colors.white),
                              ),
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.indigo)),
                            )
                          ],
                        )
                      : Column(
                          children: [
                            Text("LOG IN"),
                            SizedBox(
                              height: 8.0,
                            ),
                            Text("User id: ${provider.user.uid}"),
                            Text("Nombre: ${provider.user.name ?? ""}"),
                            Text("User id: ${provider.user.email ?? ""}"),
                            Text("User id: ${provider.user.photo ?? ""}"),
                            Text("User id: ${provider.user.phone ?? ""}"),
                            Text(
                                "User id: ${provider.user.isAnonymous ? "Anonimo" : "No anonimo"}"),
                            Text(
                                "User id: ${provider.user.emailVerified ? "Verificado" : "No verificado"}"),
                          ],
                        )),
        ),
      ),
    );
  }

  _submit(AuthenticationProvider provider) {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      provider.login(LoginProvider.Email, _user, _pass);
    }
  }
}
