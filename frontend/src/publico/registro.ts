// Registro con codigo de activacion (D1): empleados con su documento y clientes con el NIT de la empresa.
import { api } from '../comun/api';
import { boton, campoTexto, ejecutar, h, mostrarOk, vaciar, zonaDeAvisos } from '../comun/ui';
import { irA } from '../comun/enrutador';

type Tipo = 'empleado' | 'cliente';

export function vistaRegistro(contenedor: HTMLElement): void {
  const avisos = zonaDeAvisos();
  const formularioZona = h('div', { id: 'zona-registro' });
  const pestanas = h('div', { class: 'acciones', role: 'group', 'aria-label': 'Tipo de cuenta' });

  function pintar(tipo: Tipo): void {
    vaciar(formularioZona);
    vaciar(avisos);
    vaciar(pestanas);
    for (const t of ['empleado', 'cliente'] as Tipo[]) {
      pestanas.append(h('button', {
        id: `pestana-${t}`, 'data-prueba': `pestana-${t}`, type: 'button',
        class: t === tipo ? '' : 'secondary outline', 'aria-pressed': t === tipo ? 'true' : 'false',
        onclick: () => pintar(t),
      }, t === 'empleado' ? 'Soy empleado' : 'Soy cliente'));
    }
    const dato = tipo === 'empleado'
      ? campoTexto('documento', 'Número de documento', { required: true, autocomplete: 'off' })
      : campoTexto('nit', 'NIT de la empresa', { required: true, autocomplete: 'off' });
    const codigo = campoTexto('codigo', 'Código de activación', { required: true, autocomplete: 'off', placeholder: 'XXXX-XXXX-XXXX' });
    const usuario = campoTexto('usuario-nuevo', 'Nombre de usuario', { required: true, autocomplete: 'username', autocapitalize: 'none', minlength: 3, maxlength: 60 });
    const contrasena = campoTexto('contrasena-nueva', 'Contraseña', { type: 'password', required: true, autocomplete: 'new-password', minlength: 8, 'aria-describedby': 'reglas-contrasena' });
    const enviar = boton('registrar', 'Crear cuenta');
    const formulario = h('form', {
      id: 'formulario-registro',
      onsubmit: (ev: Event) => {
        ev.preventDefault();
        void ejecutar(enviar, avisos, async () => {
          const cuerpo = tipo === 'empleado'
            ? { documento: dato.control.value.trim(), codigo: codigo.control.value.trim(), usuario: usuario.control.value.trim(), contrasena: contrasena.control.value }
            : { nit: dato.control.value.trim(), codigo: codigo.control.value.trim(), usuario: usuario.control.value.trim(), contrasena: contrasena.control.value };
          const r = await api.post<{ usuario: string; rol: string }>(`/api/registro/${tipo}`, cuerpo);
          mostrarOk(avisos, `Cuenta creada para ${r.usuario} (rol ${r.rol.toLowerCase()}). Ya puede ingresar.`);
          setTimeout(() => irA('#/ingreso'), 1500);
        });
      },
    }, dato.contenedor, codigo.contenedor, usuario.contenedor, contrasena.contenedor,
    h('p', { id: 'reglas-contrasena', class: 'reglas' }, 'La contraseña debe tener al menos 8 caracteres, con una letra y un número. El nombre de usuario puede llevar letras, números, punto, guion y guion bajo (3 a 60 caracteres).'),
    enviar);
    formularioZona.append(formulario);
  }

  contenedor.append(
    h('h1', {}, 'Registrarse'),
    h('p', {}, 'Use el código de activación que le entregó el administrador. El rol de su cuenta lo define su cargo; no se elige.'),
    pestanas, formularioZona, avisos,
    h('p', {}, '¿Ya tiene cuenta? ', h('a', { href: '#/ingreso' }, 'Ingrese aquí'), '.'),
  );
  pintar('empleado');
}
