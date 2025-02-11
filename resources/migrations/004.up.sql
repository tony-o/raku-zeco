ALTER TABLE dists ADD COLUMN del TIMESTAMP;
UPDATE dists SET del = now() WHERE deleted = true;
ALTER TABLE dists DROP COLUMN deleted;
ALTER TABLE dists RENAME COLUMN del TO deleted;
