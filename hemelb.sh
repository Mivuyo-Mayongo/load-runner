#!/bin/bash
# HemeLB Installation and Run Script (Portable Version)
# Author: mivuyo
# Date: 2025-11-25

set -e  # Exit immediately if a command exits with a non-zero status

############################
# 1. Create Software Directory
############################
INSTALL_DIR="$HOME/mivuyo/software"
echo "Creating software directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

############################
# 2. Install Prerequisites
############################
echo "Installing prerequisites..."
sudo dnf install -y cmake
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y epel-release
sudo yum install -y tinyxml-devel git

############################
# 3. Clone HemeLB Repository
############################
echo "Cloning HemeLB repository..."
git clone https://github.com/hemelb-codes/hemelb.git
cd hemelb

echo "Creating build directory..."
mkdir -p build
cd build

############################
# 4. Load MPI Module and Detect Paths
############################
echo "Loading MPI module..."
module load mpi/openmpi-x86_64

# Auto-detect MPI compilers for ParMETIS
PARMETIS_CC=$(which mpicc)
PARMETIS_CXX=$(which mpicxx)

############################
# 5. Run ccmake with Instructions
############################
echo "=================================================================="
echo " IMPORTANT: When the ccmake window opens, apply these settings:"
echo "=================================================================="
echo ""
echo "------ PAGE 1 SETTINGS ------"
echo "BOOST_TARBALL        = https://archives.boost.io/release/1.77.0/source/boost_1_77_0.tar.gz"
echo "CMAKE_INSTALL_PREFIX = $INSTALL_DIR/hemelb"
echo "HEMELB_BUILD_DEBUGGER = ON"
echo "HEMELB_BUILD_TESTS    = ON"
echo "HEMELB_KERNEL         = LBGK"
echo "HEMELB_INLET_BOUNDARY = NASHZEROTHORDERPRESSUREIOLET"
echo "HEMELB_EXECUTABLE     = hemelb"
echo ""
echo "------ ParMETIS SETTINGS ------"
echo "ParMETIS_CC      = $PARMETIS_CC"
echo "ParMETIS_CXX     = $PARMETIS_CXX"
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

echo "Building HemeLB..."
make -j$(nproc)

############################
# 6. Setup Lmod Module
############################
echo "Setting up HemeLB Lmod module..."
MODULE_DIR="$INSTALL_DIR/lmod/modulefiles/load"
mkdir -p "$MODULE_DIR"

cat <<EOL > "$MODULE_DIR/hemelb"
#%Module1.0
proc ModulesHelp { } {
    puts stderr "Loads HemeLB environment"
}
module-whatis "HemeLB module"

# Load MPI module (adjust version if necessary)
module load openmpi/5.0.9

set root \$env(HOME)/mivuyo/software/hemelb
prepend-path PATH \$root/bin
setenv HEMELB_HOME \$root
EOL

echo "Loading HemeLB module..."
module use "$INSTALL_DIR/lmod/modulefiles/load"
module --ignore_cache avail
module --ignore_cache load hemelb

echo "Verifying installation..."
echo "HEMELB_HOME = $HEMELB_HOME"
which hemelb

############################
# 7. Prepare Benchmark
############################
echo "Preparing benchmark files..."
WORK_DIR="$HOME/work"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

cp "$INSTALL_DIR/hemelb/hemleb/share/hemelb/resources/large_cylinder.xml" .
cp "$INSTALL_DIR/hemelb/hemleb/share/hemelb/resources/large_cylinder.gmy" .

mkdir -p output

# Add XML property block if not already present
XML_FILE="large_cylinder.xml"
if ! grep -q "<properties>" "$XML_FILE"; then
cat <<EOL >> "$XML_FILE"
<properties>
  <propertyoutput file="whole.xtr" period="100">
    <geometry type="whole" />
    <field type="velocity" />
    <field type="pressure" />
  </propertyoutput>
</properties>
EOL
fi

############################
# 8. Run HemeLB Simulation
############################
echo "Running HemeLB simulation..."
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test

echo "HemeLB installation and test run complete!"
