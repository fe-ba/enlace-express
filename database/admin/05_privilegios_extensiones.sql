-- Privilegios del propietario que exigen las extensiones (database/extensions).
-- E1 genera los codigos de activacion con DBMS_CRYPTO.RANDOMBYTES (aleatorio
-- criptografico); el paquete no esta concedido a PUBLIC en la imagen y SYSTEM no
-- puede concederlo (ORA-00942), asi que el script se conecta como SYS. Requiere la
-- variable de sustitucion pwd_sistema (la define database/install.sh).
WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF

CONNECT sys/"&&pwd_sistema"@//localhost/FREEPDB1 AS SYSDBA
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO bd_enlace_express;
