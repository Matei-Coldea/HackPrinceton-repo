#!/bin/bash

# Quick Start Script - Guardian Card API
# Minimal script to quickly start the server

cd "$(dirname "$0")/backend"
source venv/bin/activate 2>/dev/null || source ../venv/bin/activate 2>/dev/null || echo "No venv found - using system Python"
export FLASK_APP=app.py
export FLASK_ENV=development
flask run --port 5000 --host 0.0.0.0


