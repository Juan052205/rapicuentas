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

    return await openDatabase(
      path,
      version: 15,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE ajustes_globales ADD COLUMN iva_porcentaje REAL DEFAULT 19.0');
    }
    if (oldVersion < 13) {
      await db.execute('ALTER TABLE ventas ADD COLUMN tipo_documento TEXT DEFAULT "COMPROBANTE DE VENTA"');
    }
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE ajustes_globales ADD COLUMN es_pro INTEGER DEFAULT 0');
    }
    if (oldVersion < 15) {
      await db.execute('ALTER TABLE ajustes_globales ADD COLUMN intentos_clonacion_restantes INTEGER DEFAULT 3');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE clientes (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_empresa TEXT, identificacion TEXT)');
    await db.execute('CREATE TABLE productos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre_producto TEXT, precio_unitario REAL)');
    await db.execute('''
      CREATE TABLE ajustes_globales (
        id INTEGER PRIMARY KEY, 
        nequi TEXT, daviplata TEXT, cuenta_ahorros TEXT, 
        nombre_negocio TEXT, nit TEXT, direccion TEXT, iva_porcentaje REAL,
        es_pro INTEGER DEFAULT 0,
        intentos_clonacion_restantes INTEGER DEFAULT 3
      )
    ''');
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        cliente_id INTEGER, total REAL, fecha TEXT, 
        productos_detalle TEXT, metodo_pago TEXT, tipo_documento TEXT
      )
    ''');
    await db.insert('ajustes_globales', {
      'id': 1, 'nombre_negocio': 'Mi Negocio', 'nit': 'N/A', 'direccion': 'Sin dirección',
      'iva_porcentaje': 19.0, 'nequi': '', 'daviplata': '', 'cuenta_ahorros': '', 'es_pro': 0, 'intentos_clonacion_restantes': 3
    });
  }

  Future<Map<String, dynamic>> obtenerDatosPago() async {
    final db = await database;
    final res = await db.query('ajustes_globales', where: 'id = 1');
    return res.isNotEmpty ? res.first : {'nombre_negocio': 'Mi Negocio', 'iva_porcentaje': 19.0, 'es_pro': 0, 'intentos_clonacion_restantes': 3};
  }

  Future<void> actualizarConfiguracion(String n, String nit, String dir, double iva) async {
    final db = await database;
    await db.update('ajustes_globales', {
      'nombre_negocio': n, 'nit': nit, 'direccion': dir, 'iva_porcentaje': iva
    }, where: 'id = 1');
  }

  Future<void> actualizarDatosPago(String n, String d, String a) async {
    final db = await database;
    await db.update('ajustes_globales', {'nequi': n, 'daviplata': d, 'cuenta_ahorros': a}, where: 'id = 1');
  }

  Future<void> actualizarEstadoPro(int esPro) async {
    final db = await database;
    await db.update('ajustes_globales', {'es_pro': esPro}, where: 'id = 1');
  }

  Future<int> obtenerIntentosClonacion() async {
    final db = await database;
    final res = await db.query('ajustes_globales', columns: ['intentos_clonacion_restantes', 'es_pro'], where: 'id = 1');
    if (res.isNotEmpty) {
      if (res.first['es_pro'] == 1) return 999;
      return res.first['intentos_clonacion_restantes'] as int? ?? 3;
    }
    return 3;
  }

  Future<bool> intentarConsumirClonacion() async {
    final db = await database;
    final datos = await obtenerDatosPago();
    int esPro = datos['es_pro'] ?? 0;

    if (esPro == 1) return true;

    int intentosRestantes = datos['intentos_clonacion_restantes'] ?? 3;
    if (intentosRestantes > 0) {
      await db.update(
          'ajustes_globales',
          {'intentos_clonacion_restantes': intentosRestantes - 1},
          where: 'id = 1'
      );
      return true;
    }

    return false;
  }

  Future<void> recargarIntentosClonacion(int cantidad) async {
    final db = await database;
    final datos = await obtenerDatosPago();
    int actuales = datos['intentos_clonacion_restantes'] ?? 0;
    await db.update(
        'ajustes_globales',
        {'intentos_clonacion_restantes': actuales + cantidad},
        where: 'id = 1'
    );
  }

  // Corregido: apuntas a 'ajustes_globales' en lugar de 'ajustes'
  Future<void> otorgarIntentosExtraPorAd() async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ajustes_globales 
      SET intentos_clonacion_restantes = intentos_clonacion_restantes + 1
      WHERE id = 1
    ''');
  }

  Future<int> insertarVenta(Map<String, dynamic> row) async => await (await database).insert('ventas', row);

  Future<int> eliminarVenta(int id) async {
    final db = await database;
    return await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialVentas() async {
    final db = await database;
    return await db.rawQuery('SELECT v.*, c.nombre_empresa FROM ventas v JOIN clientes c ON v.cliente_id = c.id ORDER BY v.fecha DESC');
  }

  Future<int> insertarCliente(Map<String, dynamic> row) async => await (await database).insert('clientes', row);
  Future<List<Map<String, dynamic>>> obtenerClientes() async => await (await database).query('clientes');
  Future<int> insertarProducto(Map<String, dynamic> row) async => await (await database).insert('productos', row);
  Future<List<Map<String, dynamic>>> obtenerProductosActivos() async => await (await database).query('productos');
}