CREATE TABLE metas (
  id SERIAL NOT NULL PRIMARY KEY,
  dist TEXT NOT NULL,
  data JSONB NOT NULL,
  api INTEGER DEFAULT 0,
  deleted_dt bigint
);

CREATE UNIQUE INDEX metas_dist_uniq ON metas (dist);
