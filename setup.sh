#!/bin/bash

echo "========================================"
echo "🚀 T-one Streaming Voice Setup Script"
echo "========================================"
echo

echo "🔧 Running Unix initialization script..."
chmod +x init/unix.sh
./init/unix.sh
if [ $? -ne 0 ]; then
    echo "❌ Initialization failed"
    exit 1
fi
echo

echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo
echo "🚀 To start the server:"
echo "   make up_dev          (Compact mode - fast)"
echo "   make up_dev_full     (Full mode with KenLM - accurate)"
echo
echo "📊 To download full models with KenLM (5.6GB):"
echo "   make download_full_models"
echo
echo "🌐 Server will be available at: http://localhost:8080"
echo
