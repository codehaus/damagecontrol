CREATE TABLE projects(
  id INTEGER PRIMARY KEY,
  name TEXT,
  home_page TEXT,
  start_time TIMESTAMP,
  relative_build_path TEXT,
  quiet_period INTEGER,
  build_command TEXT,
  scm TEXT,
  publishers TEXT,
  scm_web TEXT,
  tracker TEXT
);

CREATE TABLE projects_projects(
  id INTEGER PRIMARY KEY,
  depending_id INTEGER,
  dependant_id INTEGER
);

CREATE TABLE revisions(
  id INTEGER PRIMARY KEY, 
  identifier TEXT, 
  developer TEXT, 
  message TEXT, 
  timepoint TIMESTAMP, 
  project_id INTEGER,
  UNIQUE(project_id, identifier)
);

CREATE TABLE revision_files(
  id INTEGER PRIMARY KEY, 
  status TEXT, 
  path TEXT, 
  previous_native_revision_identifier TEXT, 
  native_revision_identifier TEXT, 
  timepoint TIMESTAMP, 
  revision_id INTEGER
);

CREATE TABLE builds(
  id INTEGER PRIMARY KEY,
  position INTEGER,
  state TEXT, 
  pid INTEGER, 
  exitstatus INTEGER, 
  reason TEXT,
  env TEXT,
  command TEXT,
  create_time TIMESTAMP,
  begin_time TIMESTAMP,
  end_time TIMESTAMP,
  stdout_id INTEGER,
  stderr_id INTEGER,
  revision_id INTEGER,
  triggering_build_id INTEGER
);

CREATE TABLE build_logs(
  id INTEGER PRIMARY KEY,
  data TEXT
);

CREATE TABLE artifacts(
  id INTEGER PRIMARY KEY,
  relative_path TEXT,
  build_id INTEGER
);
