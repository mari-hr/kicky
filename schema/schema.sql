SET CLIENT_ENCODING TO 'UTF8';

DROP TABLE IF EXISTS mail_templates CASCADE;

DROP SEQUENCE IF EXISTS "id_seq";

CREATE SEQUENCE "id_seq";

CREATE TABLE mail_templates (
    id integer not null primary key default nextval(('id_seq'::text)::regclass),
    name text not null,
    title text null,
    subject jsonb not null default '{}',
    content jsonb not null default '{}'
);
CREATE UNIQUE INDEX mail_templates_1 ON mail_templates(name);


