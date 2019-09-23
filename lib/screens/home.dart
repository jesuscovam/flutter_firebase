import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../services/auth.dart';
import '../models/todo.dart';


class Home extends StatefulWidget {
  Home({Key key, this.auth, this.onSignedOut, this.userId}) : super(key: key);
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Todo> _todoList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;
  
  Query _todoQuery;

  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerification();

    _todoList = List();
    _todoQuery = _database
      .reference()
      .child("todo")
      .orderByChild("userId")
      .equalTo(widget.userId);

    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription = _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified){
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail(){
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Verificar su cuenta'),
          content: Text('Por favor verificar su cuenta con el link enviado a su correo'),
          actions: <Widget>[
            FlatButton(
              child: Text('Reenviar link'),
              onPressed: (){
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            FlatButton(
              child: Text('Regresar'),
              onPressed: (){
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }

  void _showVerifyEmailSentDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Verificar cuenta'),
          content: Text('Link para verificar cuenta enviado a tu correo'),
          actions: <Widget>[
            FlatButton(
              child: Text('Regresar'),
              onPressed: (){
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();

  }

  _onEntryChanged(Event event){
    var oldEntry = _todoList.singleWhere((entry){
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event){
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async{
    try{
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch(e){
      print(e);
    }
  }

  _addNewTodo(String todoItem){
    if (todoItem.length > 0){
      Todo todo = Todo(todoItem.toString(), widget.userId,false);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  _updateTodo(Todo todo){
    todo.completed = !todo.completed;
    if (todo != null){
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteTodo(String todoId, int index){
    _database.reference().child("todo").child(todoId).remove().then((_){
      print("$todoId eliminado");
      setState((){
        _todoList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async{
    _textEditingController.clear();
    await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Agregar todo'
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text('Cancelar'),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: const Text('Guardar'),
              onPressed: (){
                _addNewTodo(_textEditingController.text.toString());
                Navigator.pop(context);
              },
            )
          ],
        );
      }
    );
  }


  Widget _showTodoList(){
    if(_todoList.isNotEmpty){
      return ListView.builder(
        shrinkWrap: true,
        itemCount: _todoList.length,
        itemBuilder: (BuildContext context, int index){
          String todoId = _todoList[index].key;
          String subject = _todoList[index].subject;
          bool completed = _todoList[index].completed;
          String userId = _todoList[index].userId;
          return Dismissible(
            key: Key(todoId),
            background: Container(color: Colors.red,),
            onDismissed: (direction) async{
              _deleteTodo(todoId, index);
            },
            child: ListTile(
              title: Text(
                subject,
                style: TextStyle(fontSize: 20.0),
              ),
              trailing: IconButton(
                icon: (completed)
                  ? Icon(
                    Icons.done_outline,
                    color: Colors.green,
                    size: 20.0,
                    )
                  : Icon(
                    Icons.done,
                    color: Colors.grey,
                    size: 20.0,
                  ),
                onPressed: (){
                  _updateTodo(_todoList[index]);
                }),
            ),
          );
        });
    } else {
      return Center(
        child: Text(
          'Bienvenido, tu lista esta vacia',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 17.0,
                color: Colors.white
              )),
              onPressed: _signOut,
          )
        ],
      ),
      body: _showTodoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _showDialog(context);
        },
        tooltip: 'Incrementar',
        child: Icon(Icons.add),
      ),
    );
  }
}