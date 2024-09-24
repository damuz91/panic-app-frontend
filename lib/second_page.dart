import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Importa el paquete de ads

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  List<Map<String, dynamic>> contactos = [];
  final DatabaseHelper dbHelper = DatabaseHelper();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _isSubscribed = false;
  String _nombreUsuario = '';
  String _planUsuario = 'Gratuito';
  String SUBSCRIPTION_ID = 'base';
  BannerAd? _bannerAd; // Declaración del banner ad
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _cargarContactos();
    _checkSubscription();
    _loadBannerAd(); // Cargar el banner de publicidad
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('user_name') ?? ''; // Valor por defecto si no existe
    });
  }

  Future<void> _saveUserName(String nombre) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nombre);
  }

  Future<void> _checkSubscription() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({SUBSCRIPTION_ID});
      setState(() {
        _isSubscribed = response.productDetails.any((product) {
          return product.id == SUBSCRIPTION_ID;
        });
        if(_isSubscribed){
          _planUsuario = 'Premium';
        }else{
          _planUsuario = 'Gratuito';
        }
      });
    }else{
      print("No se pudo obtener la disponibilidad de inAppPurchase");
    }
  }

  // Cargar contactos desde la base de datos
  void _cargarContactos() async {
    final datos = await dbHelper.getContactos();
    setState(() {
      contactos = datos;
    });
  }

  // Cargar el banner de publicidad
  void _loadBannerAd() {
    String adUnitId;
    if (kReleaseMode) {
      // IDs reales en modo release
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-3155383334923688/7174913553'; // ID de AdMob real para Android
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-3155383334923688/5195617478'; // ID de AdMob real para iOS
      } else {
        throw UnsupportedError("Plataforma no soportada");
      }
    } else {
      // IDs de prueba en modo desarrollo
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba para Android
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-3940256099942544/2934735716'; // ID de prueba para iOS
      } else {
        throw UnsupportedError("Plataforma no soportada");
      }
    }
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('Error al cargar el banner: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // Función para mostrar el formulario modal
  void _mostrarFormularioContacto() {
    if (contactos.isNotEmpty && !_isSubscribed) {
      _mostrarSuscripcionDialog();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: FormularioContacto(
              onAgregarContacto: (Map<String, String> nuevoContacto) async {
                await dbHelper.insertContacto(nuevoContacto);
                _cargarContactos();
                Navigator.pop(context);
              },
            ),
          );
        },
      );
    }
  }

  void _mostrarSuscripcionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suscripción Requerida'),
          content: const Text('Para agregar más de un contacto, necesitas una suscripción. ¿Deseas suscribirte ahora?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Suscribirse'),
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarSuscripcionPage();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarSuscripcionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionPage()),
    );
  }

  // Función para eliminar un contacto
  void _eliminarContacto(int id) async {
    await dbHelper.deleteContacto(id);
    _cargarContactos();
  }

  // Función para editar el nombre del usuario
  void _editarNombreUsuario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String nuevoNombre = _nombreUsuario;
        return AlertDialog(
          title: const Text('Editar Nombre'),
          content: TextField(
            onChanged: (value) {
              nuevoNombre = value;
            },
            decoration: const InputDecoration(hintText: "Nombre"),
            controller: TextEditingController(text: _nombreUsuario),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nuevoNombre.isNotEmpty) {
                  setState(() {
                    _nombreUsuario = nuevoNombre;
                  });
                  _saveUserName(nuevoNombre);  // Guardar el nuevo nombre
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingresa un nombre válido.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Datos'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Sección con los datos del usuario
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nombre: $_nombreUsuario', style: TextStyle(fontSize: 18)),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: _editarNombreUsuario,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Plan: $_planUsuario', style: TextStyle(fontSize: 18)),
                    ElevatedButton(
                      onPressed: _isSubscribed ? null : _mostrarSuscripcionPage,
                      child: Text(_isSubscribed ? 'Suscrito' : 'Suscribirse'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text('Mis Contactos', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: contactos.isEmpty
                      ? Center(child: Text('Aún no has agregado contactos de emergencia, agrega uno ahora.'))
                      : SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                        3: FixedColumnWidth(80),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[300]),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Nombre',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Teléfono',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Eliminar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        ...contactos.map((contacto) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(contacto["name"]),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(contacto["email"]),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(contacto["phone"]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarContacto(contacto["id"]),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Banner en la parte inferior
          if (_isBannerAdLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioContacto,
        tooltip: 'Agregar Contacto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget del formulario de contacto
class FormularioContacto extends StatefulWidget {
  final Function(Map<String, String>) onAgregarContacto;

  FormularioContacto({required this.onAgregarContacto});

  @override
  _FormularioContactoState createState() => _FormularioContactoState();
}

class _FormularioContactoState extends State<FormularioContacto> {
  final _formKey = GlobalKey<FormState>();
  String? nombre;
  String? email;
  String? telefono;
  String paisCodigo = '+57'; // Código de país predeterminado (Colombia)

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Agregar Contacto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa un nombre';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    nombre = value;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa un email';
                    }
                    final RegExp emailRegExp = RegExp(
                      r'^[^@]+@[^@]+\.[^@]+$',
                      caseSensitive: false,
                    );
                    if (!emailRegExp.hasMatch(value)) {
                      return 'Por favor, ingresa un email válido';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value;
                  },
                ),
                const SizedBox(height: 10),

                // Campo con el selector de países y número de teléfono
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'CO', // Selección predeterminada: Colombia
                  onChanged: (phone) {
                    telefono = phone.completeNumber;
                    paisCodigo = phone.countryCode;
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Por favor, ingresa un número de teléfono';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onAgregarContacto({
                  'name': nombre!,
                  'email': email!,
                  'phone': telefono!
                });
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
