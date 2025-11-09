#!/bin/bash

# Guardian Card API - Run Server Script
# This script starts the Flask development server with proper configuration

set -e  # Exit on error

echo "🚀 Starting Guardian Card API Server..."
echo "================================================"

# Change to backend directory
cd "$(dirname "$0")/backend"

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "✓ Found virtual environment"
    source venv/bin/activate
elif [ -d "../venv" ]; then
    echo "✓ Found virtual environment in parent directory"
    source ../venv/bin/activate
else
    echo "⚠️  No virtual environment found. Creating one..."
    python3 -m venv venv
    source venv/bin/activate
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found. Creating from example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✓ Created .env file. Please edit it with your configuration."
    else
        echo "⚠️  No .env.example found. Using default environment variables."
    fi
fi

# Set Flask environment variables
export FLASK_APP=app.py
export FLASK_ENV=development

# Check if database needs initialization
if [ ! -f "guardian.db" ] && [ ! -f "instance/guardian.db" ]; then
    echo "📊 Initializing database..."
    flask db upgrade || echo "⚠️  Database migration failed. Continuing anyway..."
fi

# Display info
echo ""
echo "================================================"
echo "🎯 Server Configuration:"
echo "   - Flask App: $FLASK_APP"
echo "   - Environment: $FLASK_ENV"
echo "   - Port: 5000"
echo "================================================"
echo ""
echo "📡 Starting server on http://localhost:5000"
echo ""
echo "Available endpoints:"
echo "   - GET  /health                  - Health check"
echo "   - POST /score-transaction       - ML transaction scoring"
echo "   - GET  /location-check          - Geo-guardian check"
echo "   - POST /guardian/authorize      - Transaction authorization"
echo "   - POST /location/update         - Location update"
echo "   - GET  /analytics/spending      - Spending analytics"
echo ""
echo "Press Ctrl+C to stop the server"
echo "================================================"
echo ""

# Run the Flask development server
flask run --port 5000 --host 0.0.0.0


