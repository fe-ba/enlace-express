# Copias de referencia del documento

Copias de los capítulos del documento del proyecto (Avance 14) que usa el
repositorio. No son el documento oficial, que se compila aparte con sus
figuras.

- `04-diseno-logico.tex`: reglas RN01 a RN16, conversión y vistas. El
  diccionario de datos completo no está aquí porque es igual al DDL de
  `docs/datamodeler/` (tipos, NOT NULL, DEFAULT y COMMENT de cada columna).
- `05-diseno-fisico.tex`: completo.
- `06-desarrollo-proyecto.tex`: completo (consultas C1 a C10,
  transacciones, informes y arquitectura). `database/tests/compare-queries.sh`
  lo usa para comprobar que las consultas de `database/queries/` son
  idénticas a las del documento.
- `03-alcances-extracto.tex`: el párrafo que corrige la decisión A1.

Estos archivos no se editan. Lo que se escribe para el documento va en
`docs/report/`.
