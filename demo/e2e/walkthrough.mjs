// Recorrido del flujo principal (decision B2) y del caso de rechazo en la interfaz, con capturas.
// Lo lanza run.sh dentro de la imagen de Playwright; no usa mas que playwright-core.
import { chromium } from 'playwright-core';
import fs from 'node:fs';

const BASE = process.env.URL_APP ?? 'http://localhost:8080/';
const CLAVE = process.env.DEMO_PASSWORD;
const SALIDA = '/salida';
if (!CLAVE) {
  console.error('Falta DEMO_PASSWORD');
  process.exit(2);
}

const registro = [];
const guias = {};
let capturas = 0;

let capturasDelPaso = [];

async function paso(nombre, accion) {
  capturasDelPaso = [];
  try {
    await accion();
    registro.push({ ok: true, nombre, capturas: capturasDelPaso });
    console.log('OK    ' + nombre);
  } catch (e) {
    const motivo = String(e.message ?? e).split('\n')[0];
    registro.push({ ok: false, nombre, motivo, capturas: capturasDelPaso });
    console.log('FALLA ' + nombre + ': ' + motivo);
  }
}

function exigir(condicion, mensaje) {
  if (!condicion) {
    throw new Error(mensaje);
  }
}

async function captura(p, nombre, { completa = true } = {}) {
  await p.screenshot({ path: `${SALIDA}/${nombre}.png`, fullPage: completa });
  capturas++;
  capturasDelPaso.push(nombre + '.png');
}

const navegador = await chromium.launch();

async function sesion(nombre, opciones = {}) {
  const ctx = await navegador.newContext({ locale: 'es-CO', timezoneId: 'America/Bogota', viewport: { width: 1280, height: 800 }, ...opciones });
  const p = await ctx.newPage();
  p.on('dialog', (d) => d.accept());
  p.setDefaultTimeout(15000);
  p.nombre = nombre;
  return p;
}

const MOVIL = { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true };

async function ingresar(p, usuario) {
  await p.goto(BASE + '#/ingreso');
  await p.fill('#usuario', usuario);
  await p.fill('#contrasena', CLAVE);
  await p.click('#ingresar');
  await p.waitForSelector('[data-prueba=usuario-actual]');
}

// Cada accion de una pantalla con mensajes arranca recargando, para no confundir un mensaje viejo con el nuevo.
async function recargar(p, hash) {
  await p.goto(BASE + hash);
  await p.reload();
  await p.waitForSelector('#principal > *');
}

async function armarDespacho(centro, listaDeGuias, { capturarComo } = {}) {
  await recargar(centro, '#/operacion/despacho');
  for (const g of listaDeGuias) {
    await centro.waitForSelector('#sel-' + g);
    await centro.check('#sel-' + g);
  }
  await centro.selectOption('#mensajero', '7');
  await centro.waitForFunction(() => !document.querySelector('#vehiculo').disabled);
  await centro.click('#armar-despacho');
  await centro.waitForSelector('[data-prueba=id-despacho]');
  const id = await centro.innerText('[data-prueba=id-despacho]');
  if (capturarComo) {
    await captura(centro, capturarComo);
  }
  return id;
}

async function cerrarDespacho(centro, id) {
  await recargar(centro, '#/operacion/planilla/' + id);
  await centro.waitForSelector('#tabla-planilla');
  await centro.click('#cerrar-despacho');
  await centro.waitForFunction((n) => document.querySelector('.aviso-ok')?.textContent.includes('cerrado'), id);
}

const tarjeta = (p, guia) => p.locator(`[data-guia="${guia}"]`);

async function registrarNovedad(mensajero, guia, descripcion) {
  await recargar(mensajero, '#/mensajero/planilla');
  const t = tarjeta(mensajero, guia);
  await t.waitFor();
  await t.locator('summary', { hasText: 'Registrar novedad' }).click();
  await t.locator('input[id^=descripcion]').fill(descripcion);
  await t.locator('button[id^=confirmar-novedad]').click();
  await mensajero.waitForFunction((g) => document.querySelector('.aviso-ok')?.textContent.includes(g), guia);
}

// ---------------------------------------------------------------- publico
const publico = await sesion('publico');
await paso('01 rastreo publico de una guia de los datos fijos (sin cuenta)', async () => {
  await publico.goto(BASE + '#/rastreo/EE0000000000003');
  await publico.waitForSelector('[data-prueba=linea-tiempo]');
  const texto = await publico.innerText('#resultado-rastreo');
  exigir(texto.includes('Entregado') && texto.includes('Zona'), 'el rastreo no muestra estado y zona');
  await captura(publico, '01_rastreo_publico');
});

await paso('02 pantalla de ingreso con el usuario demo_mesa', async () => {
  await publico.goto(BASE + '#/ingreso');
  await publico.fill('#usuario', 'demo_mesa');
  await publico.fill('#contrasena', CLAVE);
  await captura(publico, '02_ingreso');
});

// ---------------------------------------------------------------- mesa
const mesa = await sesion('mesa');
let solicitud = '';
await paso('03 la mesa ingresa y registra la solicitud de recoleccion del cliente 3', async () => {
  await ingresar(mesa, 'demo_mesa');
  exigir(mesa.url().endsWith('#/mesa/solicitud'), 'la mesa no llego a su pantalla de inicio');
  await mesa.selectOption('#cliente', '3');
  await mesa.waitForFunction(() => !document.querySelector('#sede').disabled && document.querySelectorAll('#sede option').length >= 1 && document.querySelector('#sede').value !== '');
  await mesa.click('#registrar-solicitud');
  await mesa.waitForSelector('[data-prueba=id-solicitud]');
  solicitud = await mesa.innerText('[data-prueba=id-solicitud]');
  exigir(Number(solicitud) > 0, 'sin numero de solicitud');
  await captura(mesa, '03_mesa_solicitud');
});

async function registrarEnvio(documento, fragil, capturarComo) {
  await recargar(mesa, '#/mesa/envio');
  await mesa.fill('#id-solicitud', solicitud);
  await mesa.fill('#numero-documento', documento);
  await mesa.fill('#nombre-destinatario', 'Destinatario ' + documento);
  await mesa.fill('#telefono-destinatario', '3001112233');
  await mesa.selectOption('#zona', '1');
  await mesa.fill('#direccion-destino', 'Calle 72 # 10-34');
  await mesa.fill('#peso-declarado', '2.5');
  await mesa.fill('#contenido', fragil ? 'Equipo de laboratorio' : 'Ropa y accesorios');
  await mesa.fill('#valor-declarado', fragil ? '850000' : '120000');
  if (fragil) {
    await mesa.check('#fragil');
  }
  await mesa.click('#registrar-envio');
  await mesa.waitForSelector('[data-prueba=guia-registrada]');
  const guia = await mesa.innerText('[data-prueba=guia-registrada]');
  exigir(/^EE\d{13}$/.test(guia), 'guia con formato inesperado: ' + guia);
  if (capturarComo) {
    await captura(mesa, capturarComo);
  }
  return guia;
}

await paso('04 la mesa registra el envio fragil (la guia y la fecha de compromiso salen en pantalla)', async () => {
  guias.fragil = await registrarEnvio('DEMO-0001', true, '04_mesa_registro_envio');
});
await paso('04b la mesa registra el segundo envio', async () => {
  guias.normal = await registrarEnvio('DEMO-0002', false);
});

// ---------------------------------------------------------------- mensajero: recoleccion
const mensajero = await sesion('mensajero', MOVIL);
await paso('05 el mensajero ve la recoleccion pendiente y la recolecta', async () => {
  await ingresar(mensajero, 'demo_mensajero');
  await recargar(mensajero, '#/mensajero/recolecciones');
  await mensajero.waitForSelector('#recolectar-' + solicitud);
  await captura(mensajero, '05_mensajero_recolecciones_movil');
  await mensajero.click('#recolectar-' + solicitud);
  await mensajero.waitForFunction(() => document.querySelector('.aviso-ok')?.textContent.includes('2 envío'));
});

// ---------------------------------------------------------------- centro
const centro = await sesion('centro');
await paso('06 el centro recibe los dos envios con su peso real y su flete', async () => {
  await ingresar(centro, 'demo_centro');
  await recargar(centro, '#/operacion/recepcion');
  for (const g of [guias.fragil, guias.normal]) {
    await centro.fill('#peso-real-' + g, '2.6');
    await centro.fill('#flete-' + g, '9500');
  }
  await captura(centro, '06_centro_recepcion');
  for (const g of [guias.fragil, guias.normal]) {
    await centro.click('#recibir-' + g);
    await centro.waitForFunction((x) => !document.querySelector('#recibir-' + x), g);
  }
});

let despacho1 = '';
await paso('07 el centro arma el despacho 1 con mensajero y vehiculo disponible', async () => {
  despacho1 = await armarDespacho(centro, [guias.fragil, guias.normal], { capturarComo: '07_centro_despacho_armado' });
});
await paso('08 planilla del despacho 1 en el centro', async () => {
  await recargar(centro, '#/operacion/planilla/' + despacho1);
  await centro.waitForSelector('#tabla-planilla');
  exigir((await centro.locator('#tabla-planilla tbody tr').count()) === 2, 'la planilla no tiene 2 envios');
  await captura(centro, '08_centro_planilla');
});

// ---------------------------------------------------------------- mensajero: entrega, rechazo RN06 y novedad
await paso('09 el mensajero ve su planilla con el envio fragil resaltado', async () => {
  await recargar(mensajero, '#/mensajero/planilla');
  const t = tarjeta(mensajero, guias.fragil);
  await t.waitFor();
  exigir((await t.getAttribute('class')).includes('especial'), 'el envio fragil no esta resaltado');
  await captura(mensajero, '09_mensajero_planilla_movil');
});

await paso('10 rechazo RN06: entrega del fragil con el documento de otra persona', async () => {
  const t = tarjeta(mensajero, guias.fragil);
  await t.locator('summary', { hasText: 'Entregar' }).click();
  await t.locator('input[id^=nombre-receptor]').fill('Persona que no es el destinatario');
  await t.locator('input[id^=documento-receptor]').fill('99999999');
  await t.locator('button[id^=confirmar-entrega]').click();
  await t.locator('.aviso-error').waitFor();
  const texto = await t.locator('.aviso-error').innerText();
  exigir(texto.startsWith('RN06:'), 'el mensaje no empieza por RN06: ' + texto);
  await t.scrollIntoViewIfNeeded();
  await captura(mensajero, '10_rechazo_rn06_movil');
});

await paso('11 entrega del fragil con el documento del destinatario y novedad en el otro envio', async () => {
  const t = tarjeta(mensajero, guias.fragil);
  await t.locator('input[id^=documento-receptor]').fill('DEMO-0001');
  await t.locator('input[id^=nombre-receptor]').fill('Destinatario DEMO-0001');
  await t.locator('button[id^=confirmar-entrega]').click();
  await mensajero.waitForFunction((g) => document.querySelector('.aviso-ok')?.textContent.includes(g), guias.fragil);
  await registrarNovedad(mensajero, guias.normal, 'Nadie atendio en la direccion');
  // la planilla se vuelve a pintar despues del mensaje de exito
  await mensajero.waitForFunction((g) => document.querySelector('[data-guia="' + g + '"]')?.innerText.includes('Novedad'), guias.normal);
  await captura(mensajero, '11_mensajero_entrega_y_novedad_movil');
});

// ---------------------------------------------------------------- seguimiento
await paso('12 rastreo publico del envio entregado', async () => {
  await publico.goto(BASE + '#/rastreo/' + guias.fragil);
  await publico.waitForSelector('[data-prueba=linea-tiempo]');
  exigir((await publico.innerText('#resultado-rastreo')).includes('Entregado'), 'el rastreo no muestra Entregado');
  await captura(publico, '12_rastreo_publico_entregado');
});
await paso('13 rastreo publico del envio con novedad', async () => {
  await publico.goto(BASE + '#/rastreo/' + guias.normal);
  await publico.waitForFunction((g) => document.querySelector('#resultado-rastreo')?.innerText.includes(g), guias.normal);
  exigir((await publico.innerText('#resultado-rastreo')).includes('Con novedad'), 'el rastreo no muestra Con novedad');
  await captura(publico, '13_rastreo_publico_novedad');
});

const cliente = await sesion('cliente');
await paso('14 el cliente ve la lista de sus envios', async () => {
  await ingresar(cliente, 'demo_cliente');
  await cliente.waitForSelector('#tabla-mis-envios');
  const texto = await cliente.innerText('#tabla-mis-envios');
  exigir(texto.includes(guias.fragil) && texto.includes(guias.normal), 'el cliente no ve sus dos envios');
  await captura(cliente, '14_cliente_mis_envios', { completa: false });
});
await paso('15 el cliente ve el recorrido del envio entregado', async () => {
  await cliente.click(`[data-prueba="ver-${guias.fragil}"]`);
  await cliente.waitForSelector('[data-prueba=linea-tiempo]');
  exigir((await cliente.locator('[data-prueba=linea-tiempo] li').count()) === 6, 'el recorrido no tiene 6 eventos');
  await captura(cliente, '15_cliente_recorrido');
});

const gerencia = await sesion('gerencia');
await paso('16 la gerencia ve el tablero (cumplimiento, estados y reclamaciones)', async () => {
  await ingresar(gerencia, 'demo_gerencia');
  await gerencia.waitForSelector('#grafico-cumplimiento');
  await gerencia.waitForSelector('#tabla-reclamaciones');
  exigir((await gerencia.locator('canvas').count()) === 2, 'el tablero no tiene dos graficos');
  await gerencia.waitForTimeout(1500);
  await captura(gerencia, '16_tablero');
});

// ---------------------------------------------------------------- caso de rechazo: tres intentos y devolucion
await paso('17 el centro cierra el despacho 1; el envio con novedad vuelve a estar por despachar (1 intento previo)', async () => {
  await cerrarDespacho(centro, despacho1);
  await recargar(centro, '#/operacion/despacho');
  await centro.waitForSelector('#sel-' + guias.normal);
  const fila = await centro.locator('tr', { has: centro.locator('#sel-' + guias.normal) }).innerText();
  exigir(fila.includes('1'), 'no se ve el intento previo');
  await captura(centro, '17_centro_reenvio_por_despachar');
});

let despacho2 = '';
await paso('18 segundo intento: nuevo despacho y segunda novedad', async () => {
  despacho2 = await armarDespacho(centro, [guias.normal]);
  await recargar(mensajero, '#/mensajero/planilla');
  exigir((await tarjeta(mensajero, guias.normal).innerText()).includes('Intento 2'), 'no esta en el intento 2');
  await registrarNovedad(mensajero, guias.normal, 'Direccion cerrada, sin quien reciba');
  await cerrarDespacho(centro, despacho2);
});

let despacho3 = '';
await paso('19 tercer intento: solo se puede devolver (no hay boton de entrega)', async () => {
  despacho3 = await armarDespacho(centro, [guias.normal]);
  await recargar(mensajero, '#/mensajero/planilla');
  const t = tarjeta(mensajero, guias.normal);
  await t.waitFor();
  const texto = await t.innerText();
  exigir(texto.includes('Intento 3') && texto.includes('Tercer intento'), 'no esta en el intento 3');
  exigir((await t.locator('summary', { hasText: 'Entregar' }).count()) === 0, 'el tercer intento ofrece entregar');
  await t.scrollIntoViewIfNeeded();
  await captura(mensajero, '18_mensajero_tercer_intento_movil');
});

await paso('20 devolucion registrada en el intento 3', async () => {
  const t = tarjeta(mensajero, guias.normal);
  await t.locator('summary', { hasText: 'Registrar devolución' }).click();
  await t.locator('input[id^=nombre-receptor]').fill('Recepcion TiendaOnline');
  await t.locator('input[id^=documento-receptor]').fill('900345678');
  await t.locator('button[id^=confirmar-devolucion]').click();
  await mensajero.waitForFunction((g) => document.querySelector('.aviso-ok')?.textContent.includes(g), guias.normal);
  exigir((await mensajero.innerText('.aviso-ok')).includes('Devuelto'), 'el envio no quedo Devuelto');
  await captura(mensajero, '19_devolucion_registrada_movil');
  await cerrarDespacho(centro, despacho3);
});

await paso('21 el cliente ve el recorrido completo del envio devuelto', async () => {
  await cliente.goto(BASE + '#/seguimiento/' + guias.normal);
  await cliente.reload();
  await cliente.waitForSelector('[data-prueba=linea-tiempo]');
  exigir((await cliente.innerText('[data-prueba=linea-tiempo]')).includes('Devuelto'), 'el recorrido no termina en Devuelto');
  await captura(cliente, '20_cliente_recorrido_devuelto');
});

await paso('22 rechazo RN12: la mesa intenta anular un envio ya entregado', async () => {
  await recargar(mesa, '#/mesa/consulta/' + guias.fragil);
  await mesa.waitForSelector('#anular-envio');
  await mesa.click('#anular-envio');
  await mesa.waitForSelector('.aviso-error');
  const texto = await mesa.innerText('.aviso-error');
  exigir(texto.startsWith('RN12:'), 'el mensaje no empieza por RN12: ' + texto);
  await captura(mesa, '21_rechazo_rn12_anular_entregado');
});


// ---------------------------------------------------------------- gestion de la mesa y del centro (CU21, CU22, CU23, CU13)
await paso('23 la mesa gestiona y cierra la novedad del envio devuelto (CU21)', async () => {
  await recargar(mesa, '#/mesa/novedades');
  const formulario = mesa.locator('form.gestion-novedad', { hasText: guias.normal }).first();
  await formulario.waitFor();
  await formulario.locator('select[id^=accion]').selectOption('REINTENTO');
  await formulario.locator('input[id^=solucion]').fill('Se acordo un nuevo horario con el destinatario');
  await formulario.locator('button[id^=gestionar]').click();
  await mesa.waitForFunction(() => document.querySelector('.aviso-ok')?.textContent.includes('gestionada'));
  await captura(mesa, '22_mesa_novedad_gestionada');
});

await paso('24 la mesa radica una reclamacion con guia propia, la responde y ve la meta de 4 horas (CU22 y CU23)', async () => {
  await recargar(mesa, '#/mesa/reclamaciones');
  await mesa.selectOption('#reclamacion-cliente', '3');
  await mesa.fill('#reclamacion-guia', guias.fragil);
  await mesa.selectOption('#reclamacion-tipo', 'ENTREGA');
  await mesa.fill('#reclamacion-descripcion', 'El destinatario pide constancia de la entrega');
  await mesa.click('#registrar-reclamacion');
  await mesa.waitForSelector('[data-prueba=id-reclamacion]');
  const id = await mesa.innerText('[data-prueba=id-reclamacion]');
  await mesa.waitForSelector('#respuesta-' + id);
  exigir((await mesa.innerText(`form[data-reclamacion="${id}"]`)).includes('dentro de la meta'), 'la reclamacion nueva debe estar dentro de la meta');
  exigir(await mesa.locator('#reclamaciones-pendientes').innerText().then((t) => t.includes('supera la meta de 4 h')), 'los datos fijos traen reclamaciones fuera de la meta');
  await mesa.fill('#respuesta-' + id, 'Se envio la constancia de entrega al correo del cliente');
  await mesa.click('#responder-' + id);
  await mesa.waitForSelector('#cerrar-' + id);
  // captura de una ventana alta que empieza en el mensaje de exito: se ven las pendientes con la meta de 4 horas
  await mesa.setViewportSize({ width: 1280, height: 1100 });
  await mesa.evaluate(() => document.querySelector('#avisos').scrollIntoView());
  await captura(mesa, '23_mesa_reclamacion_respondida', { completa: false });
  await mesa.setViewportSize({ width: 1280, height: 800 });
  await mesa.click('#cerrar-' + id);
  await mesa.waitForFunction(() => document.querySelector('.aviso-ok')?.textContent.includes('cerrada'));
});

await paso('25 rechazo: la mesa intenta radicar una reclamacion con la guia de otro cliente', async () => {
  await recargar(mesa, '#/mesa/reclamaciones');
  await mesa.selectOption('#reclamacion-cliente', '1');
  await mesa.fill('#reclamacion-guia', guias.fragil);
  await mesa.fill('#reclamacion-descripcion', 'Reclamacion con una guia que no es del cliente');
  await mesa.click('#registrar-reclamacion');
  await mesa.waitForSelector('.aviso-error');
  const texto = await mesa.innerText('.aviso-error');
  exigir(texto.includes('no es de un envío de ese cliente'), 'mensaje inesperado: ' + texto);
  await captura(mesa, '24_rechazo_reclamacion_guia_ajena');
});

await paso('26 el centro crea un centro y una zona, y luego inactiva el centro sin borrarlo (CU13)', async () => {
  const sufijo = Date.now().toString(36);
  const nombre = 'Centro Demo ' + sufijo;
  await recargar(centro, '#/operacion/centros');
  await centro.fill('#centro-nuevo-nombre', nombre);
  await centro.fill('#centro-nuevo-direccion', 'Calle 100 # 15-20, Bogotá');
  await centro.fill('#centro-nuevo-telefono', '6012000099');
  await centro.click('#crear-centro');
  await centro.waitForSelector('[data-prueba=centro-creado]');
  const tarjeta = centro.locator('article[data-centro]', { hasText: nombre });
  await tarjeta.waitFor();
  const id = await tarjeta.getAttribute('data-centro');
  await centro.selectOption('#zona-nueva-centro', id);
  await centro.fill('#zona-nueva-nombre', 'Zona Demo ' + sufijo);
  await centro.fill('#zona-nueva-localidades', 'Teusaquillo, Chapinero');
  await centro.click('#crear-zona');
  await centro.waitForFunction(() => document.querySelector('.aviso-ok')?.textContent.includes('creada'));
  await centro.click('#estado-centro-' + id);
  await centro.waitForFunction(() => document.querySelector('.aviso-ok')?.textContent.includes('Inactivo'));
  // la lista se vuelve a pintar despues del mensaje de exito
  await centro.locator('article[data-centro]', { hasText: nombre }).filter({ hasText: 'Inactivo' }).waitFor();
  await tarjeta.scrollIntoViewIfNeeded();
  await captura(centro, '25_centro_centros_y_zonas');
});

await navegador.close();

// ---------------------------------------------------------------- resumen
const fallas = registro.filter((r) => !r.ok).length;
const lineas = [
  'Prueba de punta a punta de la demostracion (Playwright, Chromium sin cabeza)',
  'Fecha: ' + new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota' }) + ' (America/Bogota)',
  'Aplicacion: ' + BASE,
  '',
  ...registro.map((r) => (r.ok ? 'OK     ' : 'FALLA  ') + r.nombre + (r.ok ? '' : ' -> ' + r.motivo) + (r.capturas.length ? '  [' + r.capturas.join(', ') + ']' : '')),
  '',
  'Solicitud de recoleccion: ' + solicitud,
  'Envio fragil (entregado con el documento del destinatario): ' + (guias.fragil ?? ''),
  'Envio con novedad, segunda novedad y devolucion en el intento 3: ' + (guias.normal ?? ''),
  'Despachos: ' + [despacho1, despacho2, despacho3].join(', '),
  'Capturas guardadas: ' + capturas,
  '',
  `Pasos: ${registro.length}. OK: ${registro.length - fallas}. FALLA: ${fallas}.`,
];
fs.writeFileSync(`${SALIDA}/resumen.txt`, lineas.join('\n') + '\n', 'utf8');
console.log('\n' + lineas.slice(-8).join('\n'));
process.exit(fallas === 0 ? 0 : 1);
