#!/bin/sh
# Script to generate necessary secrets for deployment

echo "🔐 Generating secrets for Jombo API deployment"
echo "=============================================="
echo ""

# Check if Rails is available
if ! command -v rails &> /dev/null; then
    echo "❌ Rails not found. Please install Rails first:"
    echo "   gem install rails"
    exit 1
fi

echo "Generating SECRET_KEY_BASE..."
SECRET_KEY_BASE=$(rails secret)
echo "✅ SECRET_KEY_BASE generated"
echo ""

echo "📋 Copy these values to your Coolify environment variables:"
echo ""
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
echo ""
echo "RAILS_MASTER_KEY=<copy from config/master.key>"
echo ""
echo "POSTGRES_USER=jombo_api"
echo "POSTGRES_PASSWORD=<generate a strong password>"
echo "POSTGRES_DB=jombo_api_production"
echo ""
echo "⚠️  IMPORTANT: Keep these secrets secure and never commit them to Git!"
echo ""
echo "To generate a secure password, you can use:"
echo "  openssl rand -base64 32"
