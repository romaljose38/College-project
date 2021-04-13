import 'package:flutter/material.dart';

class RegisterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Foo Register"),
      ),
      body: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> registerData = {
    'firstName': null,
    'lastName': null,
    'username': null,
    'email': null,
    'uprn': null,
    'password': null,
    'token': null,
  };

  // We need some focus nodes to move to the next textfield when hitting enter on the keyboard
  final focusLastName = FocusNode();
  final focusUsername = FocusNode();
  final focusEmail = FocusNode();
  final focusUprn = FocusNode();
  final focusPassword = FocusNode();
  final focusSubmit = FocusNode();

  void _submitHandle() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Processing Data')));
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FormCheck(
                  registerData: registerData,
                )),
      );
    }
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      onSaved: (String value) {
        registerData['firstName'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(
            focusLastName); // To focus on LastName field when hit enter on the keyboard
      },
      decoration: const InputDecoration(
        //icon: ,
        labelText: "First name",
      ),
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      focusNode: focusLastName,
      onSaved: (String value) {
        registerData['lastName'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusUsername);
      },
      decoration: const InputDecoration(
        //icon: ,
        labelText: "Last name",
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      focusNode: focusUsername,
      onSaved: (String value) {
        registerData['username'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusEmail);
      },
      decoration: const InputDecoration(
        icon: Icon(Icons.person),
        labelText: "Username",
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      focusNode: focusEmail,
      onSaved: (String value) {
        registerData['email'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusUprn);
      },
      decoration: const InputDecoration(
        icon: Icon(Icons.mail),
        labelText: "Email ID",
      ),
    );
  }

  Widget _buildUprnField() {
    return TextFormField(
      focusNode: focusUprn,
      onSaved: (String value) {
        registerData['uprn'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusPassword);
      },
      // validator
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Enter your UPRN";
        else if (num.tryParse(value) == null)
          return "Your UPRN should only contain numbers";
        return null;
      },
      decoration: const InputDecoration(
        icon: Icon(Icons.book),
        labelText: "UPRN",
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      focusNode: focusPassword,
      onSaved: (String value) {
        registerData['password'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusSubmit);
      },
      // validator
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter a password";
        }
        return null;
      },
      obscureText: true,
      decoration: const InputDecoration(
        icon: Icon(Icons.lock),
        labelText: "Password",
      ),
    );
  }

  Widget _buildSubmitField() {
    return ElevatedButton(
        focusNode: focusSubmit,
        onPressed: _submitHandle,
        child: Text("Submit"));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  //First Name
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildFirstNameField(),
                  ),
                ),
                Expanded(
                  //Second Name
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildLastNameField(),
                  ),
                ),
              ],
            ),
            Padding(
              //Username
              padding: const EdgeInsets.all(8.0),
              child: _buildUsernameField(),
            ),
            Padding(
              //Email
              padding: const EdgeInsets.all(8.0),
              child: _buildEmailField(),
            ),
            Padding(
                //UPRN
                padding: const EdgeInsets.all(8.0),
                child: _buildUprnField()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildPasswordField(),
            ),
            _buildSubmitField(),
          ]),
    );
  }
}

class FormCheck extends StatelessWidget {
  final Map<String, dynamic> registerData;
  FormCheck({Key key, @required this.registerData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foo Register'),
      ),
      body: Column(
        children: [
          Text("${registerData["firstName"]}"),
          Text("${registerData["lastName"]}"),
          Text("${registerData["username"]}"),
          Text("${registerData["email"]}"),
          Text("${registerData["uprn"]}"),
          Text("${registerData["password"]}"),
        ],
      ),
    );
  }
}
