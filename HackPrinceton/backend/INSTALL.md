# Installation Guide

## Quick Install (Recommended)

Install the core dependencies without quantum computing:

```bash
cd backend
pip install -r requirements.txt
```

This will install everything needed except Qiskit (quantum computing).

## ✅ What You Get

With the core installation:
- ✅ Flask web framework
- ✅ Database support (SQLAlchemy)
- ✅ ML transaction scoring (scikit-learn, pandas, numpy)
- ✅ Stripe payment integration
- ✅ Authentication (JWT)
- ✅ All API endpoints
- ✅ Classical greedy algorithm for obligations planning

## 🔬 Optional: Quantum Computing (Qiskit)

**⚠️ Warning:** Qiskit has compatibility issues with Python 3.12+

### For Python 3.11 and below:

```bash
pip install -r requirements-quantum.txt
```

### For Python 3.12+:

Qiskit installation may fail due to symengine build issues. **This is OK!** The system automatically falls back to the classical greedy algorithm, which works just as well for most use cases.

If you want to try anyway:

```bash
# Try newer versions (may work)
pip install qiskit>=1.0.0 qiskit-optimization>=0.6.1
```

## 🐍 Check Your Python Version

```bash
python3 --version
```

## 📦 Full Installation Steps

### Option 1: Using Anaconda (Recommended if you have it)

```bash
cd /Users/mateicoldea/Documents/Projects/Hackathons/HackPrinceton/backend

# Activate your conda environment
conda activate base  # or your preferred environment

# Install dependencies
pip install -r requirements.txt

# Initialize database
flask db upgrade

# Run the server
export FLASK_APP=app.py
flask run --port 8000
```

### Option 2: Using venv

```bash
cd /Users/mateicoldea/Documents/Projects/Hackathons/HackPrinceton/backend

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Initialize database
flask db upgrade

# Run the server
export FLASK_APP=app.py
flask run --port 8000
```

## 🧪 Verify Installation

```bash
# Test that core modules work
python3 -c "from app import app; print('✅ App imported successfully')"

# Test ML libraries
python3 -c "import sklearn, pandas, numpy; print('✅ ML libraries work')"

# Test Flask
python3 -c "import flask; print('✅ Flask works')"
```

## ❓ Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'flask'"

**Solution:** Make sure you activated your virtual environment or installed dependencies:
```bash
pip install -r requirements.txt
```

### Issue: Qiskit installation fails with symengine error

**Solution:** This is expected on Python 3.12+. Just skip it:
```bash
# Install without quantum dependencies
pip install -r requirements.txt
```

The system will automatically use classical algorithms instead.

### Issue: Port 5000 is already in use (AirPlay)

**Solution:** Use port 8000 instead:
```bash
flask run --port 8000
```

### Issue: Database migration errors

**Solution:** Create the database:
```bash
flask db upgrade
```

## 📊 What Gets Installed

### Core Dependencies (~150MB):
- Flask 3.0.3
- SQLAlchemy 2.0.44
- pandas >=2.2.0
- scikit-learn >=1.4.0
- numpy >=1.26.0, <2.0.0
- And ~35 other packages

### Quantum (Optional, ~500MB):
- qiskit 0.45.0
- qiskit-optimization 0.6.0
- And dependencies (rustworkx, symengine, etc.)

## 🎯 Ready to Run!

After installation:

```bash
# Start the server
export FLASK_APP=app.py
flask run --port 8000
```

Then visit: http://localhost:8000/health

## 🚀 Quick Start Script

Or just use the provided script:

```bash
chmod +x run_server.sh
./run_server.sh
```

(You may need to edit it to use port 8000 instead of 5000)

