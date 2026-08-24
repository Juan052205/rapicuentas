class Producto {
  final int? id;
  final String nombreProducto;
  final double precioUnitario;

  Producto({
    this.id,
    required this.nombreProducto,
    required this.precioUnitario,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombreProducto: map['nombre_producto'] ?? '',
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre_producto': nombreProducto,
      'precio_unitario': precioUnitario,
    };
  }
}