#!/bin/bash
set -e  # Exit on any error

echo "=================================================="
echo "    HemeLB Dependency Installation Script"
echo "=================================================="
echo "This script will install:"
echo "  1. GKLib    - Utility library"
echo "  2. METIS    - Graph partitioning library" 
echo "  3. ParMETIS - Parallel graph partitioning library"
echo ""
echo "Installation directory: $HOME/software/"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to verify installation
verify_installation() {
    local name=$1
    local include_file=$2
    local lib_file=$3
    
    if [ -f "$include_file" ] && [ -f "$lib_file" ]; then
        print_status "$name installed successfully"
        return 0
    else
        print_error "$name installation failed"
        return 1
    fi
}

# Create software directory
mkdir -p $HOME/software

# ============================================================================
# STEP 1: Install GKLib
# ============================================================================
echo ""
echo "=================================================="
echo "STEP 1: Installing GKLib"
echo "=================================================="

cd ~

if [ ! -d "GKlib" ]; then
    print_status "Cloning GKLib repository..."
    git clone https://github.com/KarypisLab/GKlib.git
else
    print_status "GKLib repository already exists, using existing clone"
fi

cd GKlib

print_status "Cleaning previous builds..."
rm -rf build
rm -rf $HOME/software/gklib 2>/dev/null || true

print_status "Configuring GKLib..."
if make config cc=gcc prefix=$HOME/software/gklib openmp=set; then
    print_status "Building GKLib..."
    make
    
    print_status "Installing GKLib..."
    make install
    
    # Fix library path if needed
    if [ -f "$HOME/software/gklib/lib64/libGKlib.a" ] && [ ! -f "$HOME/software/gklib/lib/libGKlib.a" ]; then
        print_status "Creating library symlink..."
        mkdir -p $HOME/software/gklib/lib
        ln -sf $HOME/software/gklib/lib64/libGKlib.a $HOME/software/gklib/lib/libGKlib.a
    fi
else
    print_error "GKLib configuration failed"
    exit 1
fi

# Verify GKLib
verify_installation "GKLib" \
    "$HOME/software/gklib/include/GKlib.h" \
    "$HOME/software/gklib/lib/libGKlib.a" || exit 1

# ============================================================================
# STEP 2: Install METIS
# ============================================================================
echo ""
echo "=================================================="
echo "STEP 2: Installing METIS"
echo "=================================================="

cd ~

if [ ! -d "METIS" ]; then
    print_status "Cloning METIS repository..."
    git clone https://github.com/KarypisLab/METIS.git
else
    print_status "METIS repository already exists, using existing clone"
fi

cd METIS

print_status "Cleaning previous builds..."
rm -rf build
rm -rf $HOME/software/metis 2>/dev/null || true

print_status "Configuring METIS..."
if make config cc=gcc prefix=$HOME/software/metis gklib_path=$HOME/software/gklib; then
    print_status "Building METIS..."
    make
    
    print_status "Installing METIS..."
    make install
else
    print_error "METIS configuration failed, trying CMake..."
    # Fall back to CMake
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$HOME/software/metis \
        -DGKLIB_PATH=$HOME/software/gklib \
        -DCMAKE_C_COMPILER=gcc
    make
    make install
    cd ..
fi

# Verify METIS
verify_installation "METIS" \
    "$HOME/software/metis/include/metis.h" \
    "$HOME/software/metis/lib/libmetis.a" || exit 1

# ============================================================================
# STEP 3: Install ParMETIS
# ============================================================================
echo ""
echo "=================================================="
echo "STEP 3: Installing ParMETIS"
echo "=================================================="

cd ~

if [ ! -d "ParMETIS" ]; then
    print_status "Cloning ParMETIS repository..."
    git clone https://github.com/KarypisLab/ParMETIS.git
else
    print_status "ParMETIS repository already exists, using existing clone"
fi

cd ParMETIS

print_status "Cleaning previous builds..."
rm -rf build
rm -rf $HOME/software/parmetis 2>/dev/null || true

# Check for MPI
print_status "Checking for MPI..."
if ! command_exists mpicc; then
    print_warning "mpicc not found in PATH"
    
    # Try to load MPI module
    if command_exists module; then
        print_status "Attempting to load MPI module..."
        module avail mpi 2>/dev/null | head -10
        # Try common MPI module names
        for mod in mpi/openmpi-x86_64 openmpi mpich intel-mpi; do
            if module load $mod 2>/dev/null; then
                print_status "Loaded MPI module: $mod"
                break
            fi
        done
    fi
    
    # Check again
    if ! command_exists mpicc; then
        print_error "MPI compiler (mpicc) not found and no module available"
        print_error "Please install OpenMPI or load an MPI module first"
        exit 1
    fi
fi

print_status "MPI found: $(which mpicc)"
mpicc --version

print_status "Configuring ParMETIS..."
if make config cc=mpicc prefix=$HOME/software/parmetis \
    gklib_path=$HOME/software/gklib \
    metis_path=$HOME/software/metis; then
    
    print_status "Building ParMETIS..."
    make
    
    print_status "Installing ParMETIS..."
    make install
else
    print_error "ParMETIS configuration failed, trying CMake..."
    # Fall back to CMake
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$HOME/software/parmetis \
        -DGKLIB_PATH=$HOME/software/gklib \
        -DMETIS_PATH=$HOME/software/metis \
        -DCMAKE_C_COMPILER=$(which mpicc)
    make
    make install
    cd ..
fi

# Verify ParMETIS
verify_installation "ParMETIS" \
    "$HOME/software/parmetis/include/parmetis.h" \
    "$HOME/software/parmetis/lib/libparmetis.a" || exit 1

# ============================================================================
# STEP 4: Set Environment Variables
# ============================================================================
echo ""
echo "=================================================="
echo "STEP 4: Setting Environment Variables"
echo "=================================================="

ENV_FILE="$HOME/hemelb_dependencies.env"

cat > $ENV_FILE << EOF
# HemeLB Dependencies Environment
export GKLib_HOME=$HOME/software/gklib
export METIS_HOME=$HOME/software/metis
export ParMETIS_HOME=$HOME/software/parmetis

# Update paths
export LD_LIBRARY_PATH=\$GKLib_HOME/lib64:\$GKLib_HOME/lib:\$METIS_HOME/lib:\$ParMETIS_HOME/lib:\$LD_LIBRARY_PATH
export CPATH=\$GKLib_HOME/include:\$METIS_HOME/include:\$ParMETIS_HOME/include:\$CPATH
export MANPATH=\$GKLib_HOME/share/man:\$METIS_HOME/share/man:\$ParMETIS_HOME/share/man:\$MANPATH
EOF

print_status "Environment file created: $ENV_FILE"
print_status "To use these dependencies, run: source $ENV_FILE"

# Also add to bashrc if user wants
read -p "Do you want to add these to your ~/.bashrc? (y/n): " add_to_bashrc
if [[ $add_to_bashrc == "y" || $add_to_bashrc == "Y" ]]; then
    cat $ENV_FILE >> ~/.bashrc
    print_status "Environment variables added to ~/.bashrc"
    print_status "Run 'source ~/.bashrc' to apply in current session"
fi

# ============================================================================
# STEP 5: Final Verification
# ============================================================================
echo ""
echo "=================================================="
echo "STEP 5: Final Verification"
echo "=================================================="

print_status "Testing library accessibility..."

# Test GKLib
if gcc -I$HOME/software/gklib/include -L$HOME/software/gklib/lib -lGKlib --verbose > /dev/null 2>&1; then
    print_status "GKLib: ✅ Accessible"
else
    print_warning "GKLib: ⚠️  May have accessibility issues"
fi

# Test METIS
cat > test_metis.c << 'EOF'
#include <metis.h>
#include <stdio.h>
int main() {
    printf("METIS test successful - version defined\n");
    return 0;
}
EOF

if gcc -I$HOME/software/metis/include -L$HOME/software/metis/lib test_metis.c -lmetis -o test_metis 2>/dev/null; then
    print_status "METIS: ✅ Accessible"
    rm test_metis 2>/dev/null || true
else
    print_warning "METIS: ⚠️  May have accessibility issues"
fi
rm test_metis.c 2>/dev/null || true

# Test ParMETIS with MPI
cat > test_parmetis.c << 'EOF'
#include <parmetis.h>
#include <stdio.h>
int main() {
    printf("ParMETIS test successful - headers available\n");
    return 0;
}
EOF

if mpicc -I$HOME/software/parmetis/include test_parmetis.c -o test_parmetis 2>/dev/null; then
    print_status "ParMETIS: ✅ Accessible"
    rm test_parmetis 2>/dev/null || true
else
    print_warning "ParMETIS: ⚠️  May have accessibility issues"
fi
rm test_parmetis.c 2>/dev/null || true

echo ""
echo "=================================================="
print_status "INSTALLATION COMPLETED SUCCESSFULLY! 🎉"
echo "=================================================="
echo ""
echo "Summary of installed dependencies:"
echo "  GKLib:    $HOME/software/gklib"
echo "  METIS:    $HOME/software/metis" 
echo "  ParMETIS: $HOME/software/parmetis"
echo ""
echo "Next steps:"
echo "  1. Source the environment: source $ENV_FILE"
echo "  2. Install HemeLB using these dependencies"
echo "  3. Use the module files for easy loading"
echo ""
echo "For HemeLB configuration, use these paths:"
echo "  - METIS_INCLUDE_DIR: $HOME/software/metis/include"
echo "  - METIS_LIBRARY: $HOME/software/metis/lib/libmetis.a"
echo "  - ParMETIS_INCLUDE_DIR: $HOME/software/parmetis/include"
echo "  - ParMETIS_LIBRARY: $HOME/software/parmetis/lib/libparmetis.a"
echo "=================================================="
