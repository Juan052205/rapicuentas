import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rapicuentas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    // IMPORTANTE: Al cambiar la estructura, debes desinstalar la app para que esto se ejecute.
    return await openDatabase(path, version: 6, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // 1. Crear tablas base
    await db.execute('CREATE TABLE clientes (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_empresa TEXT, identificacion TEXT)');
    await db.execute('CREATE TABLE productos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_producto TEXT, precio_unitario REAL)');

    // 2. Crear tabla ajustes con TODOS los campos necesarios
    await db.execute('''
      CREATE TABLE ajustes_globales (
        id INTEGER PRIMARY KEY, 
        nequi TEXT, 
        daviplata TEXT, 
        cuenta_ahorros TEXT, 
        nombre_negocio TEXT
      )
    ''');

    // 3. Insertar configuración inicial
    await db.insert('ajustes_globales', {
      'id': 1,
      'nequi': '',
      'daviplata': '',
      'cuenta_ahorros': '',
      'nombre_negocio': 'Mi Negocio'
    });

    // 4. Tabla ventas
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        cliente_id INTEGER, 
        total REAL, 
        fecha TEXT, 
        productos_detalle TEXT,
        metodo_pago TEXT
      )
    ''');
  }

  // --- GESTIÓN DE AJUSTES (Nombre y Pagos) ---

  Future<Map<String, dynamic>> obtenerDatosPago() async {
    final db = await database;
    final res = await db.query('ajustes_globales', where: 'id = 1');
    return res.isNotEmpty ? res.first : {'nequi': '', 'daviplata': '', 'cuenta_ahorros': '', 'nombre_negocio': 'Mi Negocio'};
  }

  Future<void> actualizarDatosPago(String n, String d, String a) async {
    final db = await database;
    await db.update('ajustes_globales', {'nequi': n, 'daviplata': d, 'cuenta_ahorros': a}, where: 'id = 1');
  }

  Future<void> actualizarNombreNegocio(String nombre) async {
    final db = await database;
    // Asegúrate de que la tabla sea 'ajustes_globales' y la columna 'nombre_negocio'
    await db.update('ajustes_globales', {'nombre_negocio': nombre}, where: 'id = 1');
  }

  // --- CLIENTES ---
  Future<int> insertarCliente(Map<String, dynamic> row) async => await (await database).insert('clientes', row);
  Future<List<Map<String, dynamic>>> obtenerClientes() async => await (await database).query('clientes');

  // --- PRODUCTOS ---
  Future<int> insertarProducto(Map<String, dynamic> row) async => await (await database).insert('productos', row);
  Future<List<Map<String, dynamic>>> obtenerProductosActivos() async => await (await database).query('productos');

  // --- VENTAS ---
  Future<int> insertarVenta(Map<String, dynamic> row) async {
    return await (await database).insert('ventas', row);
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialVentas() async {
    return await (await database).rawQuery('''
      SELECT v.*, c.nombre_empresa 
      FROM ventas v 
      JOIN clientes c ON v.cliente_id = c.id 
      ORDER BY v.fecha DESC
    ''');
  }
}