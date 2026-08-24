class Cliente {
  final int? id;
  final String nombreEmpresa;
  final String identificacion;
  final String telefono;
  final String direccion;

  Cliente({
    this.id,
    required this.nombreEmpresa,
    required this.identificacion,
    this.telefono = '',
    this.direccion = '',
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombreEmpresa: map['nombre_empresa'] ?? '',
      identificacion: map['identificacion'] ?? 'Consumidor Final',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre_empresa': nombreEmpresa,
      'identificacion': identificacion,
      'telefono': telefono,
      'direccion': direccion,
    };
  }
}