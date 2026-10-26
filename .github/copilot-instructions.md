# Copilot Instructions for Orphan Project

## Overview

This project is a cross-platform Flutter app for managing orphan records, with a minimal Node.js/Express backend and a PostgreSQL database. The architecture is split into:

- **Flutter app** (`lib/`): UI, local models, and service classes for children, documents, and sponsors.
- **Backend** (`server/`): REST API for CRUD operations, connects to PostgreSQL.
- **Database** (`db/`): SQL DDL and migration scripts for schema setup and data import.

## Key Workflows

- **Flutter Build/Run**: Use standard Flutter commands (`flutter run`, `flutter build`).
- **Backend Setup**:
  1. Copy `.env.example` to `.env` and set `DATABASE_URL`.
  2. Run `npm install` in `server/`.
  3. Start with `npm run dev`.
- **Database Init/Migration**:
  1. Create DB in pgAdmin, run `init_orphan_db.sql`.
  2. (Optional) Create role `orphan_user`.
  3. Migrate local JSON: `python .\db\migrate_json_to_pg.py --dir "C:\Path\To\orphan_data\children" --dsn "postgres://orphan_user:yourpw@localhost:5432/orphan_db"`

## Project-Specific Patterns

- **Models**: Dart models in `lib/models/` mirror backend DB tables. Use `toJson()`/`fromJson()` for serialization.
- **Services**: API calls in `lib/services/api_service.dart`, local storage in `sqlite_service.dart`, file handling in `storage_service.dart`.
- **REST Endpoints**: See `server/README.md` for supported routes. Documents are metadata only; binary files are managed separately.
- **Data Migration**: Migration script only moves metadata, not binary files. Manual file copy may be needed.

## Integration Points

- **Flutter ↔ Backend**: Communicate via REST (JSON). No file upload in backend; files should be stored locally or in cloud, with metadata sent to API.
- **Backend ↔ DB**: Node.js connects to PostgreSQL using connection string in `.env`.

## Conventions & Tips

- **No auth/HTTPS in dev**: Add security for production.
- **Local dev only**: Backend is scaffolded for local use; adapt for production as needed.
- **File paths**: On Windows, app data is under `getApplicationDocumentsDirectory()`.
- **Extend migration**: To move files, adapt `migrate_json_to_pg.py`.

## References

- `lib/models/child.dart`, `lib/services/api_service.dart`, `server/index.js`, `db/init_orphan_db.sql`, `db/migrate_json_to_pg.py`
- See `server/README.md` and `db/README.md` for backend and DB details.

---

For questions or unclear areas, review the referenced files or ask for clarification.
