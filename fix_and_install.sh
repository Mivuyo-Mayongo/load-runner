#!/bin/bash
set -e

echo "=== Fixing GKLib Path and Installing METIS ==="

# Step 1: Fix GKLib library path
echo "1. Creating GKLib symlink..."
GKLib_HOME="$HOME/software/gklib"

if [ -f "$GKLib_HOME/lib64/libGKlib.a" ] && [ ! -f "$GKLib_HOME/lib/libGKlib.a" ]; then
    ln -sf $GKLib_HOME/lib64/libGKlib.a $GKLib_HOME/lib/libGKlib.a
    echo "✅ Created symlink: lib/libGKlib.a → lib64/libGKlib.a"
else
    echo "✅ GKLib library already accessible"
fi

# Verify
echo "GKLib lib directory:"
ls -la $GKLib_HOME/lib/

# Step 2: Install METIS
echo ""
echo "2. Installing METIS..."
cd ~/METIS

# Clean previous attempts
rm -rf build
rm -rf $HOME/software/metis 2>/dev/null || true

# Configure and build
make config cc=gcc prefix=$HOME/software/metis gklib_path=$GKLib_HOME
make
make install

# Step 3: Verify
echo ""
echo "3. Verifying METIS installation..."
if [ -d "$HOME/software/metis" ]; then
    echo "✅ METIS installed successfully!"
    echo "METIS installation:"
    tree $HOME/software/metis -L 2 2>/dev/null || ls -la $HOME/software/metis/
    
    # Check key files
    echo ""
    echo "Key files:"
    ls $HOME/software/metis/include/metis.h && echo "  ✅ metis.h"
    ls $HOME/software/metis/lib/libmetis.a && echo "  ✅ libmetis.a"
else
    echo "❌ METIS installation failed"
fi
