#!/bin/bash

echo "🚀 Starting DynamicFeatureModule Demo..."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null
then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Not in MockBackend directory"
    echo "Please run: cd MockBackend && ./start-demo.sh"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Create modules if they don't exist
if [ ! -f "downloads/module-payment-v1.0.0.zip" ]; then
    echo "📦 Creating test modules..."
    node create-test-modules.js
    echo ""
fi

# Start server
echo "🚀 Starting backend server..."
echo ""
npm start