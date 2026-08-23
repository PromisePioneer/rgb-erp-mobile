#!/bin/bash
# Pre-commit check script for RGB ERP Mobile

set -e

echo "🔍 Running pre-commit checks..."

cd ~/Documents/rgb/erp_mobile_new

echo "1. Running flutter analyze..."
flutter analyze

echo "2. Running tests..."
flutter test

echo "3. Building debug APK..."
flutter build apk --debug

echo "✅ All checks passed!"
