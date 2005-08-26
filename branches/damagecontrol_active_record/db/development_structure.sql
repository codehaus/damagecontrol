CREATE TABLE artifacts (id INTEGER PRIMARY KEY NOT NULL, relative_path varchar(255), is_primary integer, build_id integer, position integer);
CREATE TABLE build_logs (id INTEGER PRIMARY KEY NOT NULL, data text);
CREATE TABLE builds (id INTEGER PRIMARY KEY NOT NULL, position integer, state text, pid integer, exitstatus integer, reason text, env text, command text, create_time datetime, begin_time datetime, end_time datetime, stdout_id integer, stderr_id integer, revision_id integer, triggering_build_id integer);
CREATE TABLE projects (id INTEGER PRIMARY KEY NOT NULL, name text, home_page text, start_time datetime, relative_build_path text, quiet_period integer, build_command text, scm text, publishers text, scm_web text, tracker text);
CREATE TABLE projects_projects (id INTEGER PRIMARY KEY NOT NULL, depending_id integer, dependant_id integer);
CREATE TABLE revision_files (id INTEGER PRIMARY KEY NOT NULL, status text, path text, previous_native_revision_identifier text, native_revision_identifier text, timepoint datetime, revision_id integer);
CREATE TABLE revisions (id INTEGER PRIMARY KEY NOT NULL, identifier text, developer text, message text, timepoint datetime, project_id integer);
CREATE TABLE schema_info (version integer);
