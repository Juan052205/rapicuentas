import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async => _database ??= await _initDB('rapicuentas.db');

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, filePath), version: 3, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE clientes (id INTEGER PRIMARY KEY, nombre_empresa TEXT, identificacion TEXT)');
    await db.execute('CREATE TABLE productos (id INTEGER PRIMARY KEY, nombre_producto TEXT, precio_unitario REAL)');
    await db.execute('CREATE TABLE cuentas (id INTEGER PRIMARY KEY, numero_documento TEXT, cliente_id INTEGER)');
    await db.execute('CREATE TABLE detalles_cuenta (id INTEGER PRIMARY KEY, cuenta_id INTEGER, producto TEXT, cantidad INTEGER, subtotal REAL)');
    await db.execute('CREATE TABLE configuracion_pago (id INTEGER PRIMARY KEY, nombre_banco TEXT, numero_cuenta TEXT, tipo_cuenta TEXT)');
  }

  Future<void> insertarCliente(Map<String, dynamic> row) async => (await database).insert('clientes', row);
  Future<void> insertarProducto(Map<String, dynamic> row) async => (await database).insert('productos', row);
  Future<List<Map<String, dynamic>>> obtenerHistorialCuentas() async => (await database).query('cuentas');
  Future<List<Map<String, dynamic>>> obtenerDetallesCuenta(int cuentaId) async => (await database).query('detalles_cuenta', where: 'cuenta_id = ?', whereArgs: [cuentaId]);
  Future<Map<String, dynamic>?> obtenerDatosPago() async {
    final res = await (await database).query('configuracion_pago', limit: 1);
    return res.isNotEmpty ? res.first : null;
  }
}