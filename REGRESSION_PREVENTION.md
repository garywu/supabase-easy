# Regression Prevention Guide

## Critical Configuration Requirements

### 1. VAULT_ENC_KEY - MUST BE EXACTLY 32 CHARACTERS
- **Requirement**: The VAULT_ENC_KEY must be exactly 32 characters long
- **Current Value**: `abcdefghijklmnopqrstuvwxyz123456`
- **Common Mistake**: Using base64-encoded strings (44 chars) causes pooler to fail
- **Error if Wrong**: `Unknown cipher or invalid key size`

### 2. Never Change These Without Testing
- **VAULT_ENC_KEY**: Must remain consistent for encryption/decryption
- **Init Container Pattern**: Required for Kong, Vector, Pooler, Edge Functions
- **Named Volumes**: Prevents Docker mount directory issues

## Regression Test Checklist

Before any commit that changes configuration:

1. **Run Full Regression Test**
   ```bash
   ./regression-test.sh
   ```

2. **Verify All 13 Services**
   - Database (PostgreSQL)
   - Studio (Dashboard)  
   - Auth (GoTrue)
   - Storage (File Storage)
   - Realtime (WebSockets)
   - REST API (PostgREST)
   - Analytics (Logflare)
   - Kong (API Gateway)
   - Edge Functions
   - Vector (Log Aggregation)
   - Pooler/Supavisor (Connection Pooling)
   - Meta (Database Metadata)
   - ImgProxy (Image Processing)

3. **Check Critical Services**
   - Pooler must be "healthy" not just "running"
   - Analytics must respond on port 4000
   - Kong must respond on port 8000

## Known Working Configuration

### Environment Variables
```env
VAULT_ENC_KEY=abcdefghijklmnopqrstuvwxyz123456  # EXACTLY 32 chars
POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
```

### Init Containers Required
- kong-init: Creates kong.yml config file
- vector-init: Creates vector.yml config file  
- pooler-init: Creates pooler.exs config file
- edge-functions-init: Creates config.toml

## Common Regression Causes

1. **Changing VAULT_ENC_KEY length**
   - Must be exactly 32 characters
   - Cannot be base64 encoded (44 chars)

2. **Removing Init Containers**
   - Causes "Is a directory" errors
   - Required for proper config file creation

3. **Modifying Database Roles**
   - All roles must be created before services start
   - Passwords must match across all services

4. **Changing Schema Creation Order**
   - _analytics and _supavisor must be in _supabase database
   - auth and _realtime must be in main database

## Testing Protocol

### Quick Test (2 minutes)
```bash
docker-compose up -d
sleep 30
docker-compose ps
# All 13 services should be "Up" and most "healthy"
```

### Full Test (5 minutes)
```bash
./regression-test.sh
# Should show "SUCCESS RATE: 13/13 = 100%"
```

## If Regression Occurs

1. **Check Git History**
   ```bash
   git log --oneline -10
   git diff HEAD~1
   ```

2. **Identify Breaking Change**
   - Check VAULT_ENC_KEY length
   - Verify init containers exist
   - Check database role creation

3. **Revert if Necessary**
   ```bash
   git revert HEAD
   git push origin main
   ```

## Continuous Integration

Add to CI/CD pipeline:
```yaml
- name: Run Regression Test
  run: |
    ./regression-test.sh
    if [ $? -ne 0 ]; then
      echo "Regression detected!"
      exit 1
    fi
```

## Key Lessons Learned

1. **VAULT_ENC_KEY**: 32 chars, not base64
2. **Init Containers**: Essential for config files
3. **Test Everything**: Even "improvements" can break things
4. **Document Quirks**: Supavisor's encryption is particular

---

**Remember**: What worked at 100% should stay at 100%. Test before changing!