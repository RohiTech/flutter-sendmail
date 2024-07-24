import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart'; // Importar la librería YAML
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD with SQLite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter CRUD with SQLite'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  // Controladores para el diálogo de actualización
  final _updateFormKey = GlobalKey<FormState>();
  final _updateNameController = TextEditingController();
  final _updateAgeController = TextEditingController();

  List<Map<String, dynamic>> _users = [];

  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'users.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER)');
      },
    );
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final data = await _database.query('users');
    setState(() {
      _users = data;
    });
  }

  Future<void> _insertUser() async {
    if (_formKey.currentState!.validate()) {
      await _database.insert(
        'users',
        {
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
        },
      );
      _loadUsers();
      _nameController.clear();
      _ageController.clear();
    }
  }

  Future<void> _updateUser(int id) async {
    if (_updateFormKey.currentState!.validate()) {
      await _database.update(
        'users',
        {
          'name': _updateNameController.text,
          'age': int.parse(_updateAgeController.text),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _loadUsers();
      _updateNameController.clear();
      _updateAgeController.clear();
    }
  }

  Future<void> _deleteUser(int id) async {
    await _database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadUsers();
  }

  // Función para enviar correo electrónico
  Future<void> _sendEmail(String name, int age) async {
    String username = 'jfrodriguez.flutter@gmail.com'; //Your Email
    String password = '****************'; // 16 Digits App Password Generated From Google Account

    final smtpServer = gmail(username, password);
    // Use the SmtpServer class to configure an SMTP server:
    // final smtpServer = SmtpServer('smtp.domain.com');
    // See the named arguments of SmtpServer for further configuration
    // options.

    // Crea un mensaje de correo electrónico
    final message = Message()
      ..from = Address(username, 'Jose Francisco')
      ..recipients.add('jfrancisco.fullstackdev@gmail.com') // Reemplaza con la dirección del destinatario
      ..subject = 'Información de Usuario'
      ..text = 'Nombre: $name\nEdad: $age';

    // Envía el correo electrónico
    try {
      final sendReport = await send(message, smtpServer);
      print('Mensaje enviado: ${sendReport.toString()}');
    } catch (e) {
      print('Error al enviar correo electrónico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _insertUser,
                    child: const Text('Add User'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    title: Text(user['name']),
                    subtitle: Text('Age: ${user['age']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            _sendEmail(user['name'], user['age']);
                          },
                          icon: const Icon(Icons.email),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _updateNameController.text = user['name'];
                              _updateAgeController.text = user['age'].toString();
                            });
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Update User'),
                                  content: Form(
                                    key: _updateFormKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: _updateNameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Name',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _updateAgeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Age',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter an age';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Please enter a valid number';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 32),
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateUser(user['id']);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Delete User'),
                                  content: const Text('Are you sure you want to delete this user?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteUser(user['id']);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _updateNameController.dispose();
    _updateAgeController.dispose();
    super.dispose();
  }
}