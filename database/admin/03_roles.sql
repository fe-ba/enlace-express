-- Cinco roles sin DELETE (RN16). Se crean vacios; el propietario les
-- otorga los privilegios sobre objetos en grants.
WHENEVER SQLERROR EXIT FAILURE

CREATE ROLE rol_gerencia;
CREATE ROLE rol_centro;
CREATE ROLE rol_mesa;
CREATE ROLE rol_mensajero;
CREATE ROLE rol_cliente;
