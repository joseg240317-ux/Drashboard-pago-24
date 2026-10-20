# Auditoría Supabase — 20/10/2026

## Alcance y resultado
Revisión estática de los dos repositorios accesibles, en sus ramas main:
- joseg240317-ux/Drashboard-pago-24, commit 0741b72a62c4682c570ac83aa1ec5b64ca6b96f6: un archivo index.html; usa Data API de Supabase.
- joseg240317-ux/RecordatoriosContextuales, commit b08962b7558d6cfac0536e724f3598659cc0147f: 15 archivos, aplicación Compose con SampleData. Sin dependencia Supabase, cliente Data API ni migraciones SQL. No requiere cambios por este aviso.

Se inventariaron también los paquetes ZIP/SQL disponibles y se leyeron directamente MIGRACION_FINAL_SUPABASE.sql, LIMPIAR_REPORTES_ANTES_DE_RECARGAR.sql, postgresql_schema.sql y la guía de Control de Cuentas. La descarga de los ZIP no pudo realizarse: el servicio de transferencia devolvió HTTP 403. Su contenido NO se considera auditado. No se accedió a bases, ajustes Data API ni credenciales de ejecución. Esto no certifica todos los sistemas ni permisos de producción.

## Pago24: operaciones y roles
index.html consulta GET /rest/v1/v_cases_open, v_cases_resolved y v_employee_performance; las primeras dos tienen fallback a conversations. Se requieren únicamente privilegios SELECT para el rol efectivo, no INSERT/UPDATE/DELETE en este dashboard.
La clave se introduce en pantalla y se utiliza tanto en apikey como en Authorization Bearer. No hay flujo de Supabase Auth en este repositorio. Una clave JWT anon implica rol anon; una clave service_role implica un rol privilegiado que nunca debe introducirse en el navegador. No se inspeccionó ninguna clave real ni se determinó el rol de producción.
No hay SQL ni creación de tablas en este repositorio: las migraciones del backend faltan. Si las tablas actuales conservan sus grants, las consultas continúan funcionando el 30/10. Si se recrean sin grants, podrían fallar casos abiertos/resueltos, métricas e informes. Revisar también definición de vistas, sus grants y security_invoker; RLS en tablas base no garantiza por sí sola el filtrado de una vista que ejecute con privilegios del propietario.

Se corrige la ocultación de errores HTTP 401/403 o SQLSTATE 42501: ahora llegan al indicador de error y no se convierten en listas vacías ni en un falso “Conectado”. Se mantienen los fallbacks existentes para otros errores. Esto mejora el diagnóstico, no concede permisos ni repara la base.

## Control de Cuentas: prioridad de revisión
La guía confirma Supabase, login y una migración migrations/20260707_premium_control_operativo.sql que agrega tablas para acciones, tareas, plantillas, alertas y resolución de fuera de padrón. Su SQL no pudo abrirse dentro del ZIP: riesgo pendiente, no ausencia de GRANT confirmada.
En una reconstrucción sin grants podrían fallar dashboard, importaciones, movimientos y módulos operativos.
MIGRACION_FINAL_SUPABASE.sql solo usa ALTER TABLE, índices, comentarios y políticas; no crea tablas. No necesita GRANT nuevos por este cambio cuando se aplica a las tablas existentes. Activa RLS para importaciones y movimientos y añade políticas FOR ALL TO authenticated USING(true) WITH CHECK(true). Esas políticas no distinguen administrador, supervisor, operador ni solo lectura: deben revisarse contra la autorización real antes de conceder operaciones adicionales. No se amplían aquí.
LIMPIAR_REPORTES_ANTES_DE_RECARGAR.sql usa TRUNCATE, no DROP/CREATE: conserva los objetos y sus grants. No se ejecutó.

## Otros proyectos y límites
postgresql_schema.sql es un esquema objetivo PostgreSQL 16+ con diez CREATE TABLE sin GRANT ni RLS y nombres sin esquema explícito. No se pudo asociar de forma verificable a un despliegue ni confirmar uso Data API. Incluye users con password_hash/password_salt y audit_log: no concederles acceso anon/authenticated. Si su backend usa conexión PostgreSQL directa, el cambio no requiere modificaciones. Si se migra a Data API, primero definir roles, políticas y tablas expuestas.
Farmastel V3, Rápido, BroCode, Aguas Las Lajitas, Power Club y el Site Las Higueras Lodge se localizaron como candidatos, pero sus fuentes completas no pudieron descargarse; no se certifican como afectados o libres de impacto.

## Ajustes propuestos, sin ampliar acceso
1. Recuperar las migraciones que crean las tablas y mapear cada llamada API a tabla/vista, operación y rol real.
2. En cada migración de creación, añadir solo el GRANT necesario junto con RLS y las políticas de autorización verificadas. Para el dashboard, solo SELECT en las relaciones necesarias para el rol aprobado. No proponer anon para conversaciones ni rendimiento del personal sin un diseño explícito de publicación.
3. Conceder service_role solo a relaciones/operaciones usadas desde servidor; BYPASSRLS no sustituye los privilegios SQL de tabla. No añadirlo por defecto.
4. Para INSERT que invoque nextval de una secuencia, conceder USAGE en esa secuencia concreta al rol que inserta, si es necesario. Revisar vistas y RPC por separado.
5. Añadir una migración complementaria para instalaciones existentes si falta algún permiso verificado; incluir los grants en la ruta de creación para que un reset funcione. No modificar grants existentes indiscriminadamente ni restaurar privilegios por defecto globales.
6. Probar en un entorno desechable, con defaults sin grants: migración desde cero/reset y actualización incremental; SELECT/INSERT/UPDATE/DELETE permitidos, denegación de operaciones no autorizadas y aislamiento entre usuarios/roles. No ejecutar db reset en producción.

## Validación realizada
Lectura completa de los archivos de los dos repositorios y de los tres SQL independientes. Sintaxis JavaScript y cinco escenarios simulados del dashboard: éxito, 403, 401, 42501 con HTTP no estándar y fallback por relación no encontrada. No hubo pruebas contra Supabase ni cambios en producción.

## Fuentes
- Correo oficial del 20/10/2026, mensaje 1a15983f9227a19b, leído en Gmail.
- https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically
- Guía guia_puesta_en_marcha_supabase_netlify.pdf y SQL mencionados, leídos en los archivos disponibles.

Las tablas existentes conservan sus grants; las nuevas en public requieren grants explícitos desde el 30/10/2026 para proyectos existentes. RLS sigue siendo una capa distinta. Conexiones PostgreSQL directas no se ven afectadas por este cambio de defaults.
