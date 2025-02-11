CREATE TYPE group_role AS ENUM (
  'admin',
  'member'
);

CREATE TABLE users (
  user_id  SERIAL NOT NULL PRIMARY KEY,
  email    TEXT   NOT NULL,
  username TEXT   NOT NULL,
  password TEXT,
  CONSTRAINT u_users_username UNIQUE (username)
);

CREATE TABLE group_members (
  group_id  INTEGER    NOT NULL PRIMARY KEY,
  member_id INTEGER    NOT NULL,
  role      group_role NOT NULL,
  CONSTRAINT u_group_members_group_member
    UNIQUE (group_id, member_id)
);

CREATE TABLE keys (
  key_id  SERIAL  NOT NULL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id),
  authkey TEXT    NOT NULL,
  expires BIGINT,
  CONSTRAINT u_keys_authkey UNIQUE (authkey)
);

CREATE TABLE org_invites (
  group_id  BIGINT     NOT NULL REFERENCES users(user_id),
  member_id BIGINT     NOT NULL REFERENCES users(user_id),
  role      group_role NOT NULL,
  expires   BIGINT     NOT NULL
);

CREATE TABLE password_reset (
  password_reset_id SERIAL NOT NULL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES users(user_id),
  key               TEXT   NOT NULL,
  expires           BIGINT NOT NULL,
  CONSTRAINT u_password_reset_key UNIQUE (key)
);

CREATE TABLE pkeys (
  pkey_id SERIAL NOT NULL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(user_id),
  prekey  TEXT   NOT NULL,
  expires BIGINT NOT NULL,
  CONSTRAINT u_pkeys_prekey UNIQUE (prekey)
);

CREATE TABLE user_meta (
  user_meta_id SERIAL NOT NULL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES users(user_id),
  key          TEXT   NOT NULL,
  value        TEXT   NOT NULL,
  CONSTRAINT u_user_meta_user_id_key UNIQUE (user_id, key)
);

CREATE TABLE stats (
  stat_id SERIAL NOT NULL PRIMARY KEY,
  name    TEXT   NOT NULL,
  version TEXT,
  dldate  DATE   NOT NULL,
  count   BIGINT NOT NULL,
  auth    TEXT   NOT NULL,
  CONSTRAINT u_stats_name_version_dldate_auth
    UNIQUE (name, version, dldate, auth)
);

CREATE TABLE dists (
  id      UUID      NOT NULL,
  dist    TEXT      NOT NULL,
  path    TEXT      NOT NULL,
  meta    JSONB     NOT NULL,
  deleted BOOLEAN   NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP 
);
