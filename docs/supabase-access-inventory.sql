-- Ejecutar con un rol administrador en el proyecto correcto.
-- Solo lectura: no concede permisos, no modifica políticas ni devuelve filas de negocio.
BEGIN TRANSACTION READ ONLY;
SELECT current_database(), current_user, current_setting('search_path') AS search_path;
SELECT r.rolname, r.rolbypassrls,
       n.nspname AS schema_name, c.relname AS relation_name, c.relkind,
       c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced,
       pg_get_userbyid(c.relowner) AS owner,
       has_schema_privilege(r.oid, n.oid, 'USAGE') AS schema_usage,
       has_table_privilege(r.oid, c.oid, 'SELECT') AS can_select,
       has_table_privilege(r.oid, c.oid, 'INSERT') AS can_insert,
       has_table_privilege(r.oid, c.oid, 'UPDATE') AS can_update,
       has_table_privilege(r.oid, c.oid, 'DELETE') AS can_delete,
       c.reloptions
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN pg_roles r
WHERE n.nspname='public'
  AND c.relkind IN ('r','p','v','m','f')
  AND r.rolname IN ('anon','authenticated','service_role')
ORDER BY c.relname, r.rolname;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE schemaname='public'
ORDER BY tablename, policyname;
SELECT schemaname, viewname, viewowner, definition
FROM pg_views WHERE schemaname='public'
ORDER BY viewname;
SELECT pg_get_userbyid(d.defaclrole) AS creator,
       COALESCE(n.nspname,'GLOBAL') AS schema_name,
       d.defaclobjtype, d.defaclacl
FROM pg_default_acl d LEFT JOIN pg_namespace n ON n.oid=d.defaclnamespace
WHERE d.defaclnamespace=0 OR n.nspname='public';
SELECT c.relname AS sequence_name, r.rolname,
       has_sequence_privilege(r.oid,c.oid,'USAGE') AS can_use
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN pg_roles r
WHERE c.relkind='S' AND n.nspname='public'
  AND r.rolname IN ('anon','authenticated','service_role')
ORDER BY c.relname,r.rolname;
COMMIT;
-- La configuración de esquemas expuestos de Data API se revisa en el Dashboard.
-- Tener GRANT no demuestra que RLS permita una operación.
-- No interpretar la ausencia de GRANT como una autorización para concederlo.
