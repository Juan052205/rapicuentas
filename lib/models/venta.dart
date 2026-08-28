class Venta {
  final int? id;
  final int clienteId;
  final double total;
  final String fecha;
  final String productosDetalle;
  final String metodoPago;
  final String tipoDocumento;
  final String observaciones;
  final String? nombreEmpresa;
  final int aplicarIva;
  final double ivaPorcentaje;
  final String retencionTipo;
  final double retencionPorcentaje;
  final String numeroFactura;

  Venta({
    this.id,
    required this.clienteId,
    required this.total,
    required this.fecha,
    required this.productosDetalle,
    this.metodoPago = 'Efectivo',
    this.tipoDocumento = 'COMPROBANTE DE VENTA',
    this.observaciones = '',
    this.nombreEmpresa,
    this.aplicarIva = 0,
    this.ivaPorcentaje = 0.0,
    this.retencionTipo = 'Ninguna',
    this.retencionPorcentaje = 0.0,
    this.numeroFactura = '',
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      fecha: map['fecha'] ?? '',
      productosDetalle: map['productos_detalle'] ?? '[]',
      metodoPago: map['metodo_pago'] ?? 'Efectivo',
      tipoDocumento: map['tipo_documento'] ?? 'COMPROBANTE DE VENTA',
      observaciones: map['observaciones'] ?? '',
      nombreEmpresa: map['nombre_empresa'] as String?,
      aplicarIva: (map['aplicar_iva'] as num?)?.toInt() ?? 0,
      ivaPorcentaje: (map['iva_porcentaje'] as num?)?.toDouble() ?? 0.0,
      retencionTipo: map['retencion_tipo'] ?? 'Ninguna',
      retencionPorcentaje: (map['retencion_porcentaje'] as num?)?.toDouble() ?? 0.0,
      numeroFactura: map['numero_factura'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'total': total,
      'fecha': fecha,
      'productos_detalle': productosDetalle,
      'metodo_pago': metodoPago,
      'tipo_documento': tipoDocumento,
      'observaciones': observaciones,
      'aplicar_iva': aplicarIva,
      'iva_porcentaje': ivaPorcentaje,
      'retencion_tipo': retencionTipo,
      'retencion_porcentaje': retencionPorcentaje,
      'numero_factura': numeroFactura,
    };
  }
}