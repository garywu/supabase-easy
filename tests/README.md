# Supabase Easy - Testing Suite

This directory contains the official testing suite for Supabase Easy to validate zero-shot deployment functionality.

## Available Tests

### 1. Regression Test (`regression-test.sh`)

**Full end-to-end zero-shot deployment validation**

### 2. Unit Test (`unit-test.sh`)

**Individual component and configuration validation**

---

## Regression Test

The official regression test validates complete zero-shot deployment from scratch.

#### What it tests:
- ✅ **Zero-shot deployment** - No manual intervention required
- ✅ **All 13 services start** - Database, Studio, Auth, Storage, Realtime, REST API, Analytics, Kong, Edge Functions, Vector, Pooler, Meta, ImgProxy
- ✅ **Service health checks** - All services reach healthy state
- ✅ **Key endpoints respond** - Analytics, Kong gateway, Dashboard access
- ✅ **100% success rate** - Perfect deployment every time

#### Usage:

```bash
# Basic usage (from repository root)
./tests/regression-test.sh

# Skip cleanup prompt (useful for CI/CD)
./tests/regression-test.sh --no-cleanup

# Show help
./tests/regression-test.sh --help
```

#### Test Process:

1. **Environment Cleanup** - Stops and removes all Docker containers/volumes
2. **Fresh Clone** - Downloads latest repository to clean temp directory
3. **Zero-shot Setup** - Runs `./setup.sh` with no manual intervention
4. **Service Validation** - Waits for all 13 services to start and stabilize
5. **Endpoint Testing** - Validates key API endpoints respond correctly
6. **Success Verification** - Confirms 100% deployment success rate

#### Expected Results:

```
🎯 SUCCESS RATE: 13/13 = 100%
✅ REGRESSION TEST PASSED!

🎉 Zero-shot deployment successful!
   - All 13 services are running
   - Analytics endpoint responding  
   - Kong gateway accessible
   - Dashboard available at http://localhost:8000
```

#### Test Duration:
- **Total time**: ~5-7 minutes
- **Download**: ~30 seconds
- **Setup**: ~3-4 minutes  
- **Stabilization**: ~30 seconds
- **Validation**: ~10 seconds

---

## Unit Test

Fast validation of individual components without full deployment.

#### What it tests:
- ✅ **Configuration files** - .env.example has all required variables
- ✅ **Vault key format** - VAULT_ENC_KEY is exactly 32 alphanumeric characters
- ✅ **Environment variables** - JWT tokens and keys have proper format
- ✅ **Docker Compose config** - All 13 services defined with valid syntax

#### Usage:

```bash
# Run all unit tests (from repository root)
./tests/unit-test.sh

# Test specific components
./tests/unit-test.sh config
./tests/unit-test.sh vault-key
./tests/unit-test.sh env-vars
./tests/unit-test.sh docker-compose

# Show help
./tests/unit-test.sh --help
```

#### Expected Results:

```
📊 Test Results:
  Passed: 4/4
✅ ALL UNIT TESTS PASSED!
```

#### Test Duration:
- **Total time**: ~10-15 seconds
- **Fast feedback** for development and CI/CD

## Requirements

### System Requirements:
- **Docker** - Latest version with Docker Compose
- **Git** - For repository cloning
- **curl** - For endpoint testing
- **bash** - Unix shell environment

### Resource Requirements:
- **RAM**: 4GB+ available for Docker containers
- **Disk**: 2GB+ free space for images and volumes
- **Network**: Internet access for image downloads

### Port Requirements:
The test uses these ports (must be available):
- `4000` - Analytics (Logflare)
- `5432` - Database (PostgreSQL) 
- `6543` - Connection Pooler
- `8000` - Kong Gateway / Dashboard
- `8443` - Kong Gateway (HTTPS)

## Continuous Integration

### GitHub Actions Example:

```yaml
name: Regression Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Regression Test
        run: ./tests/regression-test.sh --no-cleanup
```

### Local Development:

```bash
# Before making changes
./tests/regression-test.sh

# After making changes  
./tests/regression-test.sh

# Compare results to ensure no regression
```

## Troubleshooting Tests

### Common Issues:

1. **Port conflicts**:
   ```bash
   # Check for conflicting services
   sudo lsof -i :8000 -i :4000 -i :5432
   ```

2. **Docker out of space**:
   ```bash
   docker system prune -a
   ```

3. **Test hanging**:
   - Check Docker daemon is running
   - Ensure sufficient RAM available
   - Kill test and retry: `ctrl+c` then `./tests/regression-test.sh`

### Debug Mode:

To debug test failures, preserve the test environment:

```bash
# Run without cleanup
./tests/regression-test.sh --no-cleanup

# Then investigate
cd /tmp/supabase-easy-test-XXXXXXX
docker-compose logs [service-name]
docker-compose ps
```

### Expected Service Status:

All services should show as "Up" with most showing "(healthy)":

```
DATABASE                             STATUS
realtime-dev.supabase-realtime       Up X minutes (healthy)
supabase-analytics                   Up X minutes (healthy)  
supabase-auth                        Up X minutes (healthy)
supabase-db                          Up X minutes (healthy)
supabase-edge-functions              Up X minutes (healthy)
supabase-imgproxy                    Up X minutes (healthy)
supabase-kong                        Up X minutes (healthy)
supabase-meta                        Up X minutes (healthy)
supabase-pooler                      Up X minutes (healthy)
supabase-rest                        Up X minutes (healthy)
supabase-storage                     Up X minutes (healthy)
supabase-studio                      Up X minutes (healthy)
supabase-vector                      Up X minutes (healthy)
```

## Adding New Tests

To add new tests to the suite:

1. Create test script in `/tests/` directory
2. Make it executable: `chmod +x tests/your-test.sh`
3. Follow naming convention: `[test-type]-test.sh`
4. Include help option and proper error handling
5. Update this README with test documentation

### Test Script Template:

```bash
#!/bin/bash
set -e

echo "🧪 YOUR TEST NAME"
echo "=================="

# Your test logic here

if [ "$SUCCESS" = true ]; then
    echo "✅ TEST PASSED!"
    exit 0
else
    echo "❌ TEST FAILED!"
    exit 1
fi
```

---

## Contributing

When contributing to Supabase Easy, always run the regression test:

1. **Before changes**: Establish baseline
2. **After changes**: Verify no regression  
3. **For PRs**: Include test results in PR description

The regression test is the gold standard for validating Supabase Easy functionality.