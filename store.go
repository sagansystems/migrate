package migrate

import (
	"database/sql"
)

type Store interface {
	Open() error
	Close() error
	Exec(string, ...interface{}) (sql.Result, error)

	// CreateMetaversionIfNotExists and report the current version.
	CreateMetaVersionIfNotExists(schemaVersion int) (int, error)
	CreateMetaIfNotExists() error
	CreateMetaCheckpointsIfNotExists() error

	GetMigrations() ([]Migration, error)
	InsertMigration(filename, content, checksum string) error
	UpsertMigration(filename, content, checksum string) error

	GetMetaCheckpoints(string) ([]string, error)
	InsertMetaCheckpoint(filename, content, checksum string, idx int) error
	DeleteMetaCheckpoints() error

	UpgradeToV1([]Migration) error
}
