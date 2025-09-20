# Supabase Easy 🚀

**The missing setup tool that makes self-hosting Supabase actually work.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/garywu/supabase-easy)](https://github.com/garywu/supabase-easy/stargazers)
[![Issues](https://img.shields.io/github/issues/garywu/supabase-easy)](https://github.com/garywu/supabase-easy/issues)

## Why This Exists

Supabase's official self-hosting instructions are broken. After hours of debugging, we discovered:

- ❌ Their setup fails with "container supabase-analytics is unhealthy"
- ❌ Missing critical database creation scripts
- ❌ Vector configuration created as directory instead of file
- ❌ Missing POSTGRES_USER environment variable
- ❌ Invalid Logflare tokens that don't work
- ❌ Wrong service startup order causing cascading failures
- ❌ Database user password mismatches
- ❌ Missing analytics schema creation
- ❌ Forces you to download 350MB when only 100KB is needed

**This tool fixes ALL of these issues automatically.**

## Features

- ✅ **Downloads only what's needed** - 100KB instead of 350MB
- ✅ **Fixes all 8 critical issues** automatically
- ✅ **Cached downloads** - Download once, install multiple times
- ✅ **Works first time** - No debugging required
- ✅ **Comprehensive logging** - Know exactly what's happening
- ✅ **Multiple projects** - Run many instances simultaneously

## Quick Start

```bash
# Clone this repository
git clone https://github.com/garywu/supabase-easy.git
cd supabase-easy

# Install Supabase (fully automated)
make install

# Or install with custom project name
make install PROJECT=my-app
```

That's it! Supabase will be running at http://localhost:8000

**Default Credentials:**
- Username: `supabase`
- Password: `this_password_is_insecure_and_should_be_updated`

## What This Tool Does

### 1. Downloads Only Required Files (~100KB)

Instead of downloading the entire 350MB repository, we fetch only:
- Core configuration files (docker-compose.yml, .env)
- Database initialization scripts (13 SQL files)
- Service configurations (kong.yml, vector.yml, pooler.exs)

### 2. Automatically Fixes All Known Issues

| Issue | Official Setup | Supabase Easy |
|-------|---------------|---------------|
| Missing _supabase database | ❌ Crashes | ✅ Auto-created |
| Vector.yml as directory | ❌ Fails | ✅ Created as file |
| Missing POSTGRES_USER | ❌ Not set | ✅ Auto-added |
| Invalid Logflare tokens | ❌ Placeholders | ✅ Generates real tokens |
| Wrong startup order | ❌ Random | ✅ Correct sequence |

### 3. Proper Service Startup Order

```mermaid
graph LR
    A[Database] --> B[Vector/Imgproxy]
    B --> C[Analytics]
    C --> D[All Other Services]
```

## Installation

### Prerequisites

- Docker Desktop installed and running
- Docker Compose (`brew install docker-compose` on macOS)
- Make (`brew install make` on macOS)
- 4GB RAM available
- Ports 8000 and 5432 free

### Basic Installation

```bash
make install
```

This will:
1. Download required files from Supabase
2. Apply all critical fixes
3. Start services in correct order
4. Verify everything is working

### Advanced Usage

```bash
# Install with custom name
make install PROJECT=myapp

# Download files only (no install)
make download

# Clean everything
make clean

# Stop services
make stop

# View logs
make logs

# Restart services
make restart

# Complete uninstall
make uninstall
```

## Project Structure

```
supabase-easy/
├── Makefile              # Automated setup commands
├── README.md             # This file
├── scripts/
│   ├── download.sh       # Downloads only required files
│   ├── fix-issues.sh     # Applies all fixes
│   └── verify.sh         # Verifies installation
├── fixes/
│   ├── vector.yml        # Correct vector configuration
│   └── patches.sh        # Environment patches
├── cache/                # Downloaded files (gitignored)
└── projects/             # Your Supabase instances (gitignored)
```

## What We Discovered

After extensive debugging of Supabase's Docker setup, we found:

### 1. The 350MB Download is Unnecessary

Supabase makes you download their entire repository (350MB+) when you only need ~100KB of files:

| What You Download | What You Need | Waste |
|-------------------|---------------|-------|
| 350MB+ | 100KB | 99.97% |

### 2. Critical Files Missing from Documentation

The file `volumes/db/_supabase.sql` is absolutely critical - it creates the `_supabase` database that analytics requires. This isn't mentioned anywhere in their docs.

### 3. Analytics Service is Deeply Coupled

Almost every service has `analytics` as a dependency:
- studio → analytics
- kong → analytics
- auth → analytics
- rest → analytics
- realtime → analytics
- storage → analytics
- functions → analytics

If analytics fails (which it often does), everything cascades into failure.

### 4. Common Errors and Their Causes

| Error | Root Cause |
|-------|-----------|
| "container supabase-analytics is unhealthy" | Missing _supabase database |
| "Is a directory (os error 21)" | vector.yml created as directory |
| "role 'postgres' does not exist" | POSTGRES_USER not set |
| "LOGFLARE_PUBLIC_ACCESS_TOKEN is required" | Placeholder tokens |
| "relation 'sources' does not exist" | Missing analytics schema |
| "password authentication failed for user" | Database user password mismatches |
| "dependency failed to start" | Service dependency issues |
| Services won't start | Wrong startup order |

### 5. These Issues Have Been Reported for Years

We found GitHub issues and discussions dating back to 2022 with these exact problems. They remain unfixed in the official setup.

## Troubleshooting

### Port 8000 Already in Use

```bash
# Check what's using port 8000
lsof -i :8000

# Use different port
make install PORT=8001
```

### Analytics Still Failing

If you don't need analytics:

```bash
# Install without analytics
make install-minimal
```

### Complete Reset

```bash
make clean
make uninstall
make install
```

### View Service Status

```bash
make status
```

### Check Logs

```bash
# All logs
make logs

# Specific service
make logs SERVICE=analytics
```

## Why Supabase Official Setup Fails

Based on our research, we believe:

1. **They want you to use their cloud service** - Self-hosting issues drive paid subscriptions
2. **Docker setup is community-maintained** - Not a priority for the core team
3. **They focus on their CLI tool** - Which works better but is local-only
4. **Testing gap** - Works in their CI/CD but not in real environments

## Contributing

Found an issue? Have an improvement? PRs welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

MIT License - See [LICENSE](LICENSE) file

## Acknowledgments

- Thanks to everyone who reported these issues on GitHub
- The Supabase team for creating an amazing product (even if self-hosting is tricky)
- The community for finding workarounds

## Related Projects

- [Supabase](https://github.com/supabase/supabase) - The original project
- [Supabase CLI](https://github.com/supabase/cli) - Official CLI (local dev only)

---

**⭐ If this saved you hours of debugging, please star the repository!**

**🐛 Found a bug? [Open an issue](https://github.com/garywu/supabase-easy/issues)**

**💬 Questions? [Start a discussion](https://github.com/garywu/supabase-easy/discussions)**