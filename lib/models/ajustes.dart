class Ajustes {
  final int id;
  final String nombreNegocio;
  final String nit;
  final String direccion;
  final double ivaPorcentaje;
  final String nequi;
  final String daviplata;
  final String cuentaAhorros;
  final int esPro;
  final int intentosClonacionRestantes;
  final int videoUsado;
  final String resolucionDian;
  final int consecutivoFactura;
  final String logoPath;
  final int pdfColorIndex;
  final int pdfEstiloTabla;
  final int vistoBienvenida;
  final String prefijoFactura;
  final int vistoTutorialFacturar;

  Ajustes({
    this.id = 1,
    this.nombreNegocio = 'Mi Negocio',
    this.nit = 'N/A',
    this.direccion = 'Sin dirección',
    this.ivaPorcentaje = 19.0,
    this.nequi = '',
    this.daviplata = '',
    this.cuentaAhorros = '',
    this.esPro = 0,
    this.intentosClonacionRestantes = 3,
    this.videoUsado = 0,
    this.resolucionDian = '',
    this.consecutivoFactura = 1,
    this.logoPath = '',
    this.pdfColorIndex = 0,
    this.pdfEstiloTabla = 0,
    this.vistoBienvenida = 0,
    this.prefijoFactura = 'FE',
    this.vistoTutorialFacturar = 0,
  });

  factory Ajustes.fromMap(Map<String, dynamic> map) {
    return Ajustes(
      id: map['id'] as int? ?? 1,
      nombreNegocio: map['nombre_negocio'] ?? 'Mi Negocio',
      nit: map['nit'] ?? 'N/A',
      direccion: map['direccion'] ?? 'Sin dirección',
      ivaPorcentaje: (map['iva_porcentaje'] as num?)?.toDouble() ?? 19.0,
      nequi: map['nequi'] ?? '',
      daviplata: map['daviplata'] ?? '',
      cuentaAhorros: map['cuenta_ahorros'] ?? '',
      esPro: map['es_pro'] as int? ?? 0,
      intentosClonacionRestantes: map['intentos_clonacion_restantes'] as int? ?? 3,
      videoUsado: map['video_usado'] as int? ?? 0,
      resolucionDian: map['resolucion_dian'] ?? '',
      consecutivoFactura: map['consecutivo_factura'] as int? ?? 1,
      logoPath: map['logo_path'] ?? '',
      pdfColorIndex: map['pdf_color_index'] as int? ?? 0,
      pdfEstiloTabla: map['pdf_estilo_tabla'] as int? ?? 0,
      vistoBienvenida: map['visto_bienvenida'] as int? ?? 0,
      prefijoFactura: map['prefijo_factura'] ?? 'FE',
      vistoTutorialFacturar: map['visto_tutorial_facturar'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_negocio': nombreNegocio,
      'nit': nit,
      'direccion': direccion,
      'iva_porcentaje': ivaPorcentaje,
      'nequi': nequi,
      'daviplata': daviplata,
      'cuenta_ahorros': cuentaAhorros,
      'es_pro': esPro,
      'intentos_clonacion_restantes': intentosClonacionRestantes,
      'video_usado': videoUsado,
      'resolucion_dian': resolucionDian,
      'consecutivo_factura': consecutivoFactura,
      'logo_path': logoPath,
      'pdf_color_index': pdfColorIndex,
      'pdf_estilo_tabla': pdfEstiloTabla,
      'visto_bienvenida': vistoBienvenida,
      'prefijo_factura': prefijoFactura,
      'visto_tutorial_facturar': vistoTutorialFacturar,
    };
  }
}