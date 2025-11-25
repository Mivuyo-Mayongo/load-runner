#!/bin/bash
set -e

echo "=============================="
echo "  HemeLB Installation Script"
echo "  Author: Mivuyo"
echo "=============================="

### 1. Create directory structure
echo "[1/8] Creating directory structure..."
mkdir -p ~/mivuyo/software
mkdir -p ~/mivuyo/software/lmod/modulefiles/load
cd ~/mivuyo/software

### 2. Install prerequisites
echo "[2/8] Installing prerequisites..."
sudo dnf install -y cmake
sudo dnf groupinstall -y "Development Tools"

echo "Installing TinyXML..."
if ! sudo yum install -y tinyxml-devel; then
    echo "TinyXML failed. Enabling EPEL..."
    sudo dnf install -y epel-release
    sudo yum install -y tinyxml-devel
fi

### 3. Clone HemeLB
echo "[3/8] Cloning HemeLB..."
cd ~/mivuyo/software
git clone https://github.com/hemelb-codes/hemelb.git || true
cd hemelb

### 4. Create build directory
echo "[4/8] Creating build directory..."
mkdir -p build
cd build

### 5. Load MPI
echo "[5/8] Loading OpenMPI 5.0.9..."
module load openmpi/5.0.9

### 6. Run ccmake
echo "=================================================================="
echo " IMPORTANT: When the ccmake window opens, you MUST apply the"
echo " following settings exactly as listed below:"
echo "=================================================================="
echo ""
echo "------ PAGE 1 SETTINGS ------"
echo "BOOST_TARBALL        = https://archives.boost.io/release/1.77.0/source/boost_1_77_0.tar.gz"
echo "CMAKE_INSTALL_PREFIX = /home/cput/mivuyo/software/hemleb"
echo "HEMELB_BUILD_DEBUGGER = ON"
echo "HEMELB_BUILD_TESTS    = ON"
echo "HEMELB_KERNEL         = LBGK"
echo "HEMELB_INLET_BOUNDARY = NASHZEROTHORDERPRESSUREIOLET"
echo "HEMELB_EXECUTABLE     = hemelb"
echo ""
echo "------ ParMETIS SETTINGS ------"
echo "ParMETIS_CC      = /home/cput/software/openmpi-5.0.9/bin/mpicc"
echo "ParMETIS_CXX     = /home/cput/software/openmpi-5.0.9/bin/mpicxx"
echo "ParMETIS_TARBALL = https://karypis.github.io/glaros/files/sw/parmetis/parmetis-4.0.3.tar.gz"
echo ""
echo "------ PAGE 2 SETTINGS ------"
echo "HEMELB_LATTICE                 = D3Q15"
echo "HEMELB_STENCIL                 = FourPoint"
echo "HEMELB_WALL_BOUNDARY           = SIMPLEBOUNCEBACK"
echo "HEMELB_POINTPOINT_IMPLEMENTATION = Coalesce"
echo "HEMELB_USE_SSE3                = ON"
echo "HEMELB_USE_KRUEGER_ORDERING    = ON"
echo "HEMELB_VALIDATE_GEOMETRY       = OFF"
echo "HEMELB_USE_SUBPROJECT_MAKE_JOBS = 1"
echo ""
echo "=================================================================="
echo "When ready:"
echo "  Press [c] → configure"
echo "  Press [c] until no more errors"
echo "  Press [g] → generate"
echo "  Press [q] → quit"
echo "=================================================================="
echo ""

read -p "Press ENTER to start ccmake..."
ccmake ..

### 7. Build HemeLB
echo "[6/8] Building HemeLB..."
make -j"$(nproc)"

### 8. Create Lmod module
echo "[7/8] Creating modulefile..."

cat << 'EOF' > ~/mivuyo/software/lmod/modulefiles/load/hemelb
#%Module1.0

proc ModulesHelp { } {
    puts stderr "Loads HemeLB environment"
}

module-whatis "HemeLB module"

# Load correct MPI version
module load openmpi/5.0.9

set root /home/cput/mivuyo/software/hemleb

prepend-path PATH $root/bin
setenv HEMELB_HOME $root
EOF

echo "[8/8] Module created."

echo "=========================================================="
echo " HemeLB installation completed!"
echo " To load the module, run:"
echo ""
echo "  module use ~/mivuyo/software/lmod/modulefiles/load"
echo "  module load hemelb"
echo ""
echo " Then verify:"
echo "  echo \$HEMELB_HOME"
echo "  which hemelb"
echo "=========================================================="
