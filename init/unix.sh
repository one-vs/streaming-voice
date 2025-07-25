#!/bin/bash

echo "========================================"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 T-one macOS Initialization"
else
    echo "🐧 T-one Linux Initialization"
fi
echo "========================================"
echo

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ uv not found. Installing uv..."
    echo
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install uv"
        echo "📝 Please install manually: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
    
    # Reload shell to get uv in PATH
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
    
    # Check again after reload
    if ! command -v uv &> /dev/null; then
        echo "✅ uv installed successfully"
        echo "🔄 Please restart your terminal and run the script again"
        echo "   Or run: source ~/.bashrc (or ~/.zshrc)"
        exit 0
    fi
    
    echo "✅ uv installed successfully"
fi

echo "✅ uv found"
echo

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    uv venv .venv
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi
echo

# Install dependencies
echo "📥 Installing Python dependencies..."
uv sync --extra demo --extra dev
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo

# Download models
echo "🤖 Downloading AI models..."
make download_models
if [ $? -ne 0 ]; then
    echo "❌ Failed to download models"
    exit 1
fi
echo "✅ Models downloaded"
echo

echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo
echo "🚀 To activate virtual environment:"
echo "   source .venv/bin/activate"
echo
echo "🌐 To start the server:"
echo "   make up_dev          (Compact mode)"
echo "   make up_dev_full     (Full mode with KenLM)"
echo
echo "📊 Server will be available at: http://localhost:8080"
echo
