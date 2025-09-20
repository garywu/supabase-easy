# Changelog

All notable changes to Supabase Easy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-20

### Added
- Initial release of Supabase Easy
- Automated download of only required files (~100KB instead of 350MB)
- Automatic fixes for all 5 critical Supabase self-hosting issues:
  - Missing `_supabase` database creation
  - Vector.yml created as directory instead of file
  - Missing POSTGRES_USER environment variable
  - Invalid Logflare placeholder tokens
  - Wrong service startup order
- Makefile-based automation for easy installation
- Support for multiple concurrent projects
- Cached downloads for faster subsequent installations
- Comprehensive verification script
- Minimal installation option (without analytics)
- Detailed documentation of all discovered issues
- Scripts for downloading, fixing, and verifying installation

### Fixed
- "container supabase-analytics is unhealthy" error
- "Is a directory (os error 21)" vector configuration error
- "role 'postgres' does not exist" database error
- "LOGFLARE_PUBLIC_ACCESS_TOKEN is required" token error
- Service startup order causing cascading failures

### Documentation
- Comprehensive README with all discovered issues
- Troubleshooting guide for common problems
- Contributing guidelines
- MIT License

## [Unreleased]

### Planned
- Automatic port detection if 8000 is in use
- Support for custom environment variables
- Backup and restore functionality
- Docker Compose v2 support
- GitHub Actions for automated testing
- Pre-built Docker image option
- Web-based installer UI

## Issue Discovery Timeline

### 2022-2024
- Multiple GitHub issues reported same problems
- No official fixes provided by Supabase team
- Community workarounds scattered across issues

### 2024-12-20
- Systematic analysis of all issues
- Root cause identification
- Automated solution development
- Supabase Easy created to solve all issues

---

## Why This Tool Exists

After extensive debugging, we discovered that Supabase's official self-hosting setup has been broken for years with the same recurring issues. This tool was created to:

1. Save developers hours of debugging time
2. Provide a reliable, repeatable installation process
3. Document all issues and their solutions
4. Reduce the 350MB download to only what's needed (~100KB)

For more details on the issues we discovered, see the [README](README.md).