#!/bin/bash

# Create a new Flutter project
flutter create tsw_tracker_app

cd tsw_tracker_app || exit

# Remove the default lib directory
rm -rf lib

# Recreate the lib directory and subdirectories
mkdir -p lib/{models,providers,screens/{auth,meal,outbreak,allergic_reaction,sleep,mood},services,widgets,localization,themes}

# Create pubspec.yaml with updated dependencies
cat > pubspec.yaml <<EOL
name: tsw_tracker_app
description: A new Flutter project.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ">=2.18.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  firebase_core: ^2.14.0
  cloud_firestore: ^4.7.1
  firebase_auth: ^4.6.5
  firebase_storage: ^11.2.2
  intl: ^0.18.1
  fl_chart: ^0.62.0
  flutter_local_notifications: ^13.1.0
  image_picker: ^1.0.0
  uuid: ^3.0.7
  connectivity_plus: ^4.0.2
  share_plus: ^6.3.0
  flutter_localizations:
    sdk: flutter
  speech_to_text: ^5.8.0
  health: ^5.1.4
  firebase_messaging: ^14.6.7
  flutter_screenutil: ^5.8.4

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true

EOL

# Create main.dart
cat > lib/main.dart <<EOL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';
import 'localization/app_localizations_delegate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => MealProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider(lightTheme)),
        // Add other providers
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TSW Tracker App',
            theme: themeProvider.themeData,
            home: AuthWrapper(),
            supportedLocales: [
              Locale('en', ''),
              Locale('es', ''),
              // Add other locales
            ],
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.user != null) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
EOL

# Create Theme Files
cat > lib/themes/light_theme.dart <<EOL
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData.light().copyWith(
  primaryColor: Colors.blue,
  // Customize other theme properties
);
EOL

cat > lib/themes/dark_theme.dart <<EOL
import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.blueGrey,
  // Customize other theme properties
);
EOL

# Create ThemeProvider
cat > lib/providers/theme_provider.dart <<EOL
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  ThemeProvider(this._themeData);

  ThemeData get themeData => _themeData;

  void toggleTheme() {
    if (_themeData.brightness == Brightness.light) {
      _themeData = ThemeData.dark();
    } else {
      _themeData = ThemeData.light();
    }
    notifyListeners();
  }
}
EOL

# Create AuthProvider
cat > lib/providers/auth_provider.dart <<EOL
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;
  String? get userId => user?.uid;

  Future<void> signup(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}
EOL

# Create Meal Model
cat > lib/models/meal.dart <<EOL
class Meal {
  final String id;
  final DateTime dateTime;
  final String description;
  final List<String> triggerFoods;
  final String? photoUrl;

  Meal({
    required this.id,
    required this.dateTime,
    required this.description,
    required this.triggerFoods,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
      'triggerFoods': triggerFoods,
      'photoUrl': photoUrl,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> data) {
    return Meal(
      id: data['id'],
      dateTime: DateTime.parse(data['dateTime']),
      description: data['description'],
      triggerFoods: List<String>.from(data['triggerFoods']),
      photoUrl: data['photoUrl'],
    );
  }
}
EOL

# Create MealProvider
cat > lib/providers/meal_provider.dart <<EOL
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal.dart';

class MealProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<Meal>>? mealStream;

  void listenToMeals(String userId) {
    mealStream = _firestore
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
    notifyListeners();
  }

  Future<void> addMeal(Meal meal, String userId) async {
    await _firestore.collection('meals').add({
      ...meal.toMap(),
      'userId': userId,
    });
    notifyListeners();
  }
}
EOL

# Create AddMealScreen
mkdir -p lib/screens/meal
cat > lib/screens/meal/add_meal_screen.dart <<EOL
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/meal.dart';
import '../../providers/meal_provider.dart';
import '../../providers/auth_provider.dart';

class AddMealScreen extends StatefulWidget {
  static const routeName = '/add-meal';

  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _triggerFoodsController = TextEditingController();
  List<String> _triggerFoods = [];
  XFile? _imageFile;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  void _addTriggerFood() {
    if (_triggerFoodsController.text.isNotEmpty) {
      setState(() {
        _triggerFoods.add(_triggerFoodsController.text);
        _triggerFoodsController.clear();
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final newMeal = Meal(
      id: Uuid().v4(),
      dateTime: DateTime.now(),
      description: _descriptionController.text,
      triggerFoods: _triggerFoods,
      // photoUrl: Implement photo upload and get URL
    );

    await Provider.of<MealProvider>(context, listen: false)
        .addMeal(newMeal, userId!);

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _triggerFoodsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Meal'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Meal Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                ),
                // Trigger Foods Field
                TextFormField(
                  controller: _triggerFoodsController,
                  decoration: InputDecoration(
                    labelText: 'Add Trigger Food',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addTriggerFood,
                    ),
                  ),
                ),
                // Display List of Trigger Foods
                Wrap(
                  spacing: 8.0,
                  children: _triggerFoods
                      .map((food) => Chip(
                            label: Text(food),
                            onDeleted: () {
                              setState(() {
                                _triggerFoods.remove(food);
                              });
                            },
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),
                // Photo Picker
                _imageFile == null
                    ? TextButton(
                        onPressed: _pickImage,
                        child: Text('Add Photo'),
                      )
                    : Image.file(File(_imageFile!.path)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOL

# Create MealListScreen
cat > lib/screens/meal/meal_list_screen.dart <<EOL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/meal.dart';
import 'add_meal_screen.dart';

class MealListScreen extends StatefulWidget {
  static const routeName = '/meals';

  @override
  _MealListScreenState createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    Provider.of<MealProvider>(context, listen: false).listenToMeals(userId!);
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Meals'),
      ),
      body: StreamBuilder<List<Meal>>(
        stream: mealProvider.mealStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final meals = snapshot.data!;
            return ListView.builder(
              itemCount: meals.length,
              itemBuilder: (ctx, i) {
                final meal = meals[i];
                return ListTile(
                  title: Text(meal.description),
                  subtitle: Text(
                      'Date: \${meal.dateTime.toLocal().toString().split(' ')[0]}'),
                  onTap: () {
                    // Navigate to meal details if needed
                  },
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddMealScreen.routeName);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
EOL

# Create LoginScreen
mkdir -p lib/screens/auth
cat > lib/screens/auth/login_screen.dart <<EOL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_email, _password);
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (error) {
      // Handle errors
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TSW Tracker Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Field
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  _email = value!;
                },
              ),
              // Password Field
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              // Login Button
              ElevatedButton(
                onPressed: _submit,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create HomeScreen
cat > lib/screens/home_screen.dart <<EOL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'meal/meal_list_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TSW Tracker Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to TSW Tracker App!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(MealListScreen.routeName);
              },
              child: Text('Go to Meals'),
            ),
          ],
        ),
      ),
    );
  }
}
EOL

# Create AppLocalizationsDelegate
mkdir -p lib/localization
cat > lib/localization/app_localizations_delegate.dart <<EOL
import 'package:flutter/material.dart';
import 'dart:async';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static Future<AppLocalizations> load(Locale locale) {
    // Load language files and return AppLocalizations instance
    return Future(() => AppLocalizations(locale));
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Add localized strings here
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
EOL

# Create placeholder for localization files
touch lib/localization/intl_en.arb
touch lib/localization/intl_es.arb

# Create VoiceInputWidget
mkdir -p lib/widgets
cat > lib/widgets/voice_input_widget.dart <<EOL
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onResult;
  VoiceInputWidget({required this.onResult});

  @override
  _VoiceInputWidgetState createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          widget.onResult(val.recognizedWords);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
      onPressed: _listen,
    );
  }
}
EOL

# Create NotificationService
mkdir -p lib/services
cat > lib/services/notification_service.dart <<EOL
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleDailyReminder(
      int id, String title, String body, Time time) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', 'Daily Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(Time time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }
    return scheduledDate;
  }
}
EOL

# Initialize Flutter packages
flutter pub get

echo "Setup complete! Your Flutter project is ready."