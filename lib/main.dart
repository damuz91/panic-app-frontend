import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'second_page.dart';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botón de Pánico',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SOSHomePage(),
    );
  }
}

class SOSHomePage extends StatefulWidget {
  @override
  _SOSHomePageState createState() => _SOSHomePageState();
}

class _SOSHomePageState extends State<SOSHomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String apiKey = '';
  String backendUrl = '';

  @override
  void initState() {
    super.initState();
    _loadTextFiles();
    _initializeLocation();
  }

  Future<void> _loadTextFiles() async {
    try {
      final apiKeyString = await rootBundle.loadString('assets/api_key.txt');
      apiKey = apiKeyString.trim();
      print("La api key leida es: $apiKey");
      final backendUrlString = await rootBundle.loadString('assets/backend_url.txt');
      backendUrl = backendUrlString.trim();
      print("La url del backend es: $backendUrl");
    } catch(e){
      print("Error al leer el archivo de api key: $e");
    }
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.id ?? 'unknown';
    }

    return 'unknown';
  }

  Future<String> _getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? '';
  }

  Future<List<Map<String, dynamic>>> _getContactos() async {
    return await dbHelper.getContactos();
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String message, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isProfileComplete() async {
    String userName = await _getUserName();
    List<Map<String, dynamic>> contactos = await _getContactos();

    return userName.isNotEmpty && contactos.isNotEmpty;
  }

  Future<void> _showIncompleteProfileWarning(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Perfil Incompleto'),
          content: const Text(
              'Aún no has terminado de configurar tu perfil, por favor configúralo para poder enviar mensajes de alerta'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendPostRequest(String url) async {
    bool isProfileComplete = await _isProfileComplete();
    if (!isProfileComplete) {
      _showIncompleteProfileWarning(context);
      return;
    }

    String os = Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android';
    String userId = await getDeviceId();
    String userName = await _getUserName();
    List<Map<String, dynamic>> contactos = await _getContactos();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');

    final body = jsonEncode({
      "os": os,
      "user_id": userId,
      "user_name": userName,
      "contacts": contactos,
      "lat": latitude,
      "lng": longitude,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": apiKey
        },
        body: body,
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      // if (response.statusCode == 200) { }
      _showAlert(context, '${responseData['message']}');
    } catch (e) {
      _showAlert(context, 'Ha ocurrido un error al enviar la solicitud: $e');
    }
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Respuesta'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botón de Pánico'),
        backgroundColor: Colors.purple[100],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 200.0,
              height: 200.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    spreadRadius: 10,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  _showConfirmationDialog(
                    context,
                    "Estás a punto de enviar un mensaje de auxilio real, ¿estás seguro de querer continuar?",
                        () => _sendPostRequest("$backendUrl/send_sos"),
                  );
                },
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showConfirmationDialog(
                  context,
                  "Estás a punto de realizar una prueba, ¿estás seguro de querer continuar?",
                      () => _sendPostRequest("$backendUrl/send_test"),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Hacer Prueba',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.purple[50],
    );
  }
}
