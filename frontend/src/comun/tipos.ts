// Formas de las respuestas de la API (ver los controladores de backend/.../presentacion/api).

export type Rol = 'GERENCIA' | 'CENTRO' | 'MESA' | 'MENSAJERO' | 'CLIENTE';

export interface UsuarioSesion {
  usuario: string;
  rol: Rol;
  idEmpleado: number | null;
  idCliente: number | null;
}

export interface EventoRastreo {
  fechaHora: string;
  estado: string;
  zona: string;
}

export interface Rastreo {
  guia: string;
  estadoActual: string;
  eventos: EventoRastreo[];
}

export interface FilaSeguimiento {
  fechaHora: string;
  estado: string;
  observacion: string | null;
  responsable: string;
}

export interface ResumenCliente {
  idCliente: number;
  nit: string;
  razonSocial: string;
  tipoCliente: string;
  estado: string;
}

export interface SedeCliente {
  idSede: number;
  idCliente: number;
  idZona: number;
  nombre: string;
  direccion: string;
  contacto: string;
  telefono: string;
}

export interface Zona {
  idZona: number;
  idCentro: number;
  nombre: string;
  localidades: string;
}

export interface Modalidad {
  idModalidad: number;
  nombre: string;
  plazoDiasHabiles: number;
}

export interface EnvioRegistrado {
  numeroGuia: string;
  fechaCompromiso: string;
}

export interface Destinatario {
  idDestinatario: number | null;
  tipoDocumento: string;
  numeroDocumento: string;
  nombre: string;
  telefono: string;
  correo: string | null;
}

export interface DetalleEnvio {
  numeroGuia: string;
  idSolicitud: number;
  fechaRegistro: string;
  fechaCompromiso: string;
  estadoActual: string | null;
  direccionDestino: string;
  pesoDeclarado: number;
  pesoReal: number | null;
  contenido: string;
  valorDeclarado: number;
  fragil: boolean;
  altoValor: boolean;
  valorFlete: number | null;
  idZona: number;
  idModalidad: number;
  destinatario: Destinatario | null;
  recorrido: FilaSeguimiento[];
}

export interface FilaRecoleccion {
  idSolicitud: number;
  fechaProgramada: string;
  franjaHoraria: string;
  estado: string;
  sede: string;
  direccion: string;
  contacto: string;
  telefono: string;
  envios: number;
}

export interface FilaPlanilla {
  ordenVisita: number;
  numeroGuia: string;
  destinatario: string;
  telefono: string;
  direccion: string;
  resultado: 'PENDIENTE' | 'ENTREGADO' | 'NOVEDAD' | 'DEVUELTO';
  idAsignacion: number;
  numeroIntento: number;
  tipoDocumentoDestinatario: string;
  numeroDocumentoDestinatario: string;
  zona: string;
  fragil: boolean;
  altoValor: boolean;
  idDespacho: number;
  estadoDespacho: string;
}

export interface FilaEnvioEstado {
  numeroGuia: string;
  fechaRegistro: string;
  fechaCompromiso: string;
  razonSocial: string;
  zona: string;
  modalidad: string;
  estadoActual: string;
  fechaHoraEstado: string;
}

export interface FilaPorDespachar {
  numeroGuia: string;
  idCentro: number;
  idZona: number;
  zona: string;
  modalidad: string;
  fechaCompromiso: string;
  pesoKg: number;
  fragil: boolean;
  altoValor: boolean;
  estadoActual: string;
  intentosPrevios: number;
}

export interface ResumenMensajero {
  idEmpleado: number;
  nombres: string;
  apellidos: string;
  idZona: number | null;
  idTipoVehiculo: number;
  tipoVehiculo: string;
}

export interface ResumenVehiculo {
  idVehiculo: number;
  placa: string | null;
  marca: string;
  modelo: string;
}

export interface FilaCumplimiento {
  idCentro: number;
  idZona: number;
  zona: string;
  entregados: number;
  entregadosATiempo: number;
  porcentajeATiempo: number;
}

export interface FilaConteo {
  etiqueta: string;
  total: number;
}

export interface FilaReclamacion {
  idReclamacion: number;
  fechaRadicacion: string;
  idCliente: number;
  cliente: string;
  numeroGuia: string | null;
  tipo: string;
  descripcion: string;
  horasTranscurridas: number;
}

export interface FilaEnvioCliente {
  numeroGuia: string;
  estadoActual: string;
  fechaHora: string;
}

export interface FilaNovedadAbierta {
  idNovedad: number;
  numeroGuia: string;
  numeroIntento: number;
  horaVisita: string;
  tipoNovedad: string;
  descripcion: string;
  destinatario: string;
  telefonoDestinatario: string;
  idCliente: number;
  cliente: string;
  telefonoCliente: string;
}

export interface FilaReclamacionMesa {
  idReclamacion: number;
  fechaRadicacion: string;
  idCliente: number;
  cliente: string;
  numeroGuia: string | null;
  tipo: string;
  descripcion: string;
  estado: string;
  respuesta: string | null;
  fechaRespuesta: string | null;
  horas: number;
  superaMeta: boolean;
}

export interface Centro {
  idCentro: number;
  nombre: string;
  direccion: string;
  telefono: string | null;
  estado: 'ACTIVO' | 'INACTIVO';
}
