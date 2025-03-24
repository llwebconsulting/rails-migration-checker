# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release
- Rake tasks for managing migrations:
  - `migrations:fix_missing_down` - Adds safe down methods to migrations
  - `migrations:fix_missing_timestamps` - Adds timestamps to tables
  - `migrations:fix_missing_foreign_keys` - Adds foreign key constraints
  - `migrations:analyze_dependencies` - Analyzes migration dependencies
  - `migrations:backup_plan` - Creates backups of migrations
  - `migrations:check_data_loss` - Checks for potential data loss
  - `migrations:fix_version_gaps` - Fixes gaps in migration versions
- CLI interface for running validations
- GitHub Actions workflow for CI
- RuboCop configuration for code style
- Test suite using Minitest 