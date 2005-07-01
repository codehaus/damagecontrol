CREATE TABLE projects(
  id INTEGER PRIMARY KEY, 
  name TEXT, 
  home_page TEXT, 
  start_time TIMESTAMP, 
  relative_build_path TEXT, 
  quiet_period INTEGER, 
  build_command TEXT, 
  scm TEXT
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
  project_id INTEGER
);

CREATE TABLE publishers(
  id INTEGER PRIMARY KEY, 
  delegate TEXT, 
  enabled BOOLEAN, 
  project_id INTEGER
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
  status TEXT, 
  stdout TEXT, 
  stderr TEXT, 
  pid INTEGER, 
  exitstatus INTEGER, 
  reason TEXT,
  env TEXT,
  command TEXT,
  timepoint TIMESTAMP, 
  revision_id INTEGER
);
