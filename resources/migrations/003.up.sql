DROP TABLE metas;
DROP TABLE test_db;
ALTER TABLE org_invites ADD COLUMN org_invite_id SERIAL PRIMARY KEY;
ALTER TABLE group_members ADD COLUMN group_members_id SERIAL PRIMARY KEY;
