# Production Keys and Configuration

## Overview
This document explains which environment variables and keys are required for production deployment.

## Required Keys

### 1. Rails Master Key (`config/master.key`)
- **Purpose**: Decrypts the `config/credentials.yml.enc` file
- **Format**: 64 hexadecimal characters (32 bytes when decoded)
- **Example**: `71e6994957408765fd1becdf7b634922f03797fd093e74a0d49e8570f9d9d6b4df4e809b34335d11c46a0ab8bd4e8f83e6657a010af8d8ec05effc7e0c500578`
- **Generation**: `rails secret` (will output 64-char hex string)
- **Storage**: 
  - Local: `config/master.key` (never commit to git)
  - Production: Set via environment variable or file mount in container
- **DO NOT**: Set `RAILS_MASTER_KEY` in `.env` or environment - this causes conflicts

### 2. Secret Key Base
- **Purpose**: Used for signing session cookies and message verification
- **Format**: 128-character hexadecimal string
- **How to set**: Store in `config/credentials.yml.enc` under `secret_key_base`
- **View current**: `rails credentials:show`
- **Edit**: `rails credentials:edit`

### 3. OAuth Credentials
Environment variables needed in `.env` or deployment:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=<your-client-id>.apps.googleusercontent.com

# Facebook OAuth (optional)
FACEBOOK_APP_ID=<your-app-id>
FACEBOOK_APP_SECRET=<your-app-secret>

# API Keys
DIGITRANSIT_API_KEY=<your-api-key>
OST_SERVER_ITEM_ACCESS_TOKEN=<your-token>
```

### 4. Frontend URLs
```bash
FRONTEND_URL=https://jombo.com
FRONTEND_URL_ES=https://jombo.com
FRONTEND_URL_FI=https://jombo.com
```

### 5. Monitoring (Optional)
```bash
ROLLBAR_ACCESS_TOKEN=<your-rollbar-token>
```

## Production Deployment Checklist

### Docker/Kubernetes
1. Mount `config/master.key` file or set via volume
2. Set all OAuth environment variables
3. Set FRONTEND_URL variables
4. Do NOT set `RAILS_MASTER_KEY` environment variable
5. Ensure `Rails.env` = `production`

### Rails Credentials Management
To add secrets to encrypted credentials:
```bash
rails credentials:edit
```

This opens an editor where you can add:
```yaml
secret_key_base: <your-64-char-hex>
aws:
  access_key_id: <key>
  secret_access_key: <secret>
```

## Troubleshooting

### Error: "key must be 16 bytes"
- **Cause**: Master key is too short (32 hex chars instead of 64)
- **Fix**: Generate a new key with `rails secret` and update `config/master.key`
- **Common mistake**: Having `RAILS_MASTER_KEY` in `.env` file

### Error: "bad decrypt" when running Rails
- **Cause**: Wrong master key for decrypting credentials
- **Fix**: Verify the `config/master.key` matches the original key used to encrypt credentials

### Error: Credentials not loading in production
- **Cause**: `config/master.key` not available to container/server
- **Fix**: Mount the key file or provide via build-time argument

## Security Best Practices

1. **Never commit** `config/master.key` to version control
2. **Never commit** `.env` files with secrets
3. **Rotate keys** periodically in production
4. **Use secrets management** solutions (AWS Secrets Manager, Vault, etc.)
5. **Restrict file permissions**: `chmod 600 config/master.key`
6. **Audit access** to master key in production environments

## Environment-Specific Configuration

### Development
- Use default Rails credentials
- Keep `.env` file for local OAuth testing

### Staging
- Use separate OAuth credentials
- Use secure key storage
- Test full deployment flow

### Production
- Use secure key management system
- Rotate secrets regularly
- Monitor access to sensitive data
- Use encrypted communication for all API calls
