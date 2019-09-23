import 'package:flutter/material.dart';
import '../services/auth.dart';

enum FormMode {LOGIN, SIGNUP}

class Login extends StatefulWidget {
  Login({Key key, this.auth, this.onSignedIn}) : super(key: key);
  
  final BaseAuth auth;
  final VoidCallback onSignedIn;

  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = new GlobalKey<FormState>();
  String _email;
  String _password;
  String _errorMessage;
  
  FormMode _formMode =FormMode.LOGIN;
  bool _isLoading;

  bool _validateAndSave(){
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();
      return true;
    } else {
      return false;
    }
  }

  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (_validateAndSave()){
      String userId = "";
      try{
        if (_formMode == FormMode.LOGIN){
          userId = await widget.auth.signIn(_email, _password);
          print('Iniciar: $userId');
        } else {
          userId = await widget.auth.signUp(_email, _password);
          widget.auth.sendEmailVerification();
          _showVerifyEmailSentDialog();
          print('Inicio como $userId');
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId !=null && _formMode == FormMode.LOGIN){
          widget.onSignedIn();
        }
      } catch(e){
        print('Error $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  @override
  void initState() { 
    _errorMessage ="";
    _isLoading = false;
    super.initState();
    
  }
  Widget _showCircularProgress(){
    if(_isLoading){
      return Center(child: CircularProgressIndicator());
    } return Container(height: 0.0, width: 0.0,);
  }

  void _showVerifyEmailSentDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Verificar cuenta'),
          content: Text('Link para verificar cuenta enviado a su correo'),
          actions: <Widget>[
            FlatButton(
              child: Text('Regresar'),
              onPressed: (){
                Navigator.of(context).pop();
              },
            )
          ],
        )
      }
    )
  }

  Widget _showLogo(){
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: FlutterLogo(
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _showEmailInput(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 60.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Correo',
          icon: Icon(
            Icons.mail,
            color: Colors.grey,
          )
        ),
        validator: (value)=> value.isEmpty ? 'Es necesario un correo' : null,
        onSaved: (value)=> _email = value.trim(),
      ),
    );
  }

  Widget _showPasswordInput(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Contraseña',
          icon: Icon(
            Icons.lock,
            color: Colors.grey,
          )
        ),
        validator: (value) => value.isEmpty ? "Es necesaria una contraseña" : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }
  
  Widget _showPrimaryButton(){
    return RaisedButton(
      textColor: Colors.white,
      padding: EdgeInsets.all(0.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
                  Color(0xFF0D47A1),
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
            ],
          )
        ),
        padding: EdgeInsets.all(10.0),
        child: _formMode == FormMode.LOGIN
          ? Text(
            'Iniciar',
            style: TextStyle(
              fontSize: 20
            ))
          : Text(
            'Crear Cuenta',
            style: TextStyle(
              fontSize: 20
            ),
          )
      ),
      onPressed: _validateAndSubmit,
    );

    // return Padding(
    //   padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
    //   child: MaterialButton(
    //     elevation: 5.0,
    //     minWidth: 200.0,
    //     height: 42,
    //     color: Colors.blue,
    //     child: _formMode == FormMode.LOGIN
    //       ? Text(
    //         'Iniciar',
    //         style: TextStyle(
    //           fontSize: 20.0,
    //           color: Colors.white
    //         ))
    //       : Text(
    //         'Crear Cuenta',
    //         style: TextStyle(
    //           fontSize: 20.0,
    //           color: Colors.white
    //         ),
    //       ),
    //       onPressed: (){},
    //   ),
    // );
  }

  Widget _showSecondaryButton(){
    return RaisedButton(
      textColor: Colors.black54,
      child:  Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        child: _formMode == FormMode.LOGIN
        ? Text(
          'Crear una cuenta',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ))
        : Text(
          'Tienes una cuenta? Iniciar',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold
          ),
        ),
    ),
    onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin

    );
  }
 
  void _changeFormToSignUp(){
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin(){
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  Widget _showErrorMessage(){
    if (_errorMessage.length > 0 && _errorMessage != null){
      return Text(
        _errorMessage,
        style: TextStyle(
          fontSize: 13.0,
          color: Colors.red,
          height: 1.0,
          fontWeight: FontWeight.w300
        ),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

 
  Widget _showBody(){
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            _showLogo(),
            _showEmailInput(),
            _showPasswordInput(),
            SizedBox(height: 30,),
            _showPrimaryButton(),
            SizedBox(height: 8,),
            _showSecondaryButton(),
            _showErrorMessage()
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Stack(
        children: <Widget>[
          _showBody(),
          _showCircularProgress()
        ],
      ),
    );
  }
}

