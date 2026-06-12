import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  DatabaseHelper._privateConstructor();

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory docs = await getApplicationDocumentsDirectory();
    return await openDatabase(join(docs.path, "RapicuentasDB.db"), version: 3, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE ajustes_globales (id INTEGER PRIMARY KEY, nequi TEXT, daviplata TEXT, cuenta_ahorros TEXT)');
    await db.execute('CREATE TABLE clientes (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_empresa TEXT, identificacion TEXT)');
    await db.execute('CREATE TABLE productos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_producto TEXT, precio_unitario REAL)');
    await db.insert('ajustes_globales', {'id': 1, 'nequi': '', 'daviplata': '', 'cuenta_ahorros': ''});
  }

  Future<void> actualizarDatosPago(String n, String d, String a) async {
    await (await database).update('ajustes_globales', {'nequi': n, 'daviplata': d, 'cuenta_ahorros': a}, where: 'id = 1');
  }

  Future<Map<String, dynamic>> obtenerDatosPago() async {
    final res = await (await database).query('ajustes_globales', where: 'id = 1');
    return res.isNotEmpty ? res.first : {'nequi': '', 'daviplata': '', 'cuenta_ahorros': ''};
  }

  Future<List<Map<String, dynamic>>> obtenerProductosActivos() async => await (await database).query('productos');
  Future<int> insertarProducto(Map<String, dynamic> row) async => await (await database).insert('productos', row);
}