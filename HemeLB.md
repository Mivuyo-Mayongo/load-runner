# Comprehensive HemeLB Installation Guide - In-Depth Explanation

## 1. Prerequisites - Detailed Breakdown

### System Packages Explained

**CMake**: Cross-platform build system generator
```bash
sudo dnf install cmake
# Why: HemeLB uses CMake for configuring the build process across different platforms
```

**Development Tools**: Essential compiler toolchain
```bash
sudo dnf groupinstall "Development Tools"
# Includes: gcc, g++, make, autotools, git, etc.
# Why: Needed to compile C/C++ code and manage build dependencies
```

**TinyXML**: XML parsing library
```bash
sudo dnf install tinyxml-devel
# Why: HemeLB uses XML files for configuration (input parameters, geometry specs)
# The -devel package includes header files needed for compilation
```

### Why These Prerequisites Matter
- **CMake**: Handles complex dependency chains and platform-specific compilation
- **Development Tools**: Provides the actual compilers and build utilities
- **TinyXML**: Parses simulation configuration files in XML format

## 2. Dependency Installation - Deep Dive

### GKLib: Fundamental Utility Library
**Purpose**: Provides basic data structures and utilities used by METIS/ParMETIS
```bash
git clone https://github.com/KarypisLab/GKlib.git
cd GKlib
make config cc=gcc prefix=/path
make
make install
```

**Key Configuration Options**:
- `cc=gcc`: Specifies C compiler (could use `icc`, `clang`)
- `prefix=/path`: Installation directory (crucial for later dependencies)
- `openmp=set`: Enables OpenMP parallelization (recommended for performance)

### METIS: Graph Partitioning Library
**Purpose**: Partitions unstructured graphs for parallel processing
```bash
git clone https://github.com/KarypisLab/METIS.git
cd METIS
make config cc=gcc prefix=/path gklib_path=/path/to/gklib
make install
```

**Advanced Configuration Flags**:
- `shared=1`: Builds shared libraries (.so) instead of static (.a)
- `i64=1`: Uses 64-bit integers (essential for large meshes >2B elements)
- `r64=1`: Uses 64-bit floating point (better precision for large simulations)

**Critical Dependency Chain**: METIS requires GKLib, must specify `gklib_path`

### ParMETIS: Parallel Graph Partitioning
####1. First, Load MPI Module or Set MPI Environment
**Purpose**: MPI-parallel version of METIS for large-scale simulations
```bash
git clone https://github.com/KarypisLab/ParMETIS.git
cd ParMETIS
make config cc=mpicc prefix=/path gklib_path=/path metis_path=/path
make install
```

**Important Notes**:
- Uses `mpicc` instead of `gcc` (MPI compiler wrapper)
- Requires both GKLib AND METIS as dependencies
- Must specify both `gklib_path` and `metis_path` if installed separately

### Dependency Troubleshooting
**Common Error**: `/usr/bin/ld: cannot find -lGKlib`
**Cause**: Library installed in non-standard location or wrong path
**Solution**:
```bash
# Check actual library location
ls /path/to/gklib/
# Should see: include/ lib/ lib64/ (or similar)

# Fix library path issue
cp /path/to/gklib/lib64/libGKlib.a /path/to/gklib/lib/
# OR create symbolic link
ln -s /path/to/gklib/lib64/libGKlib.a /path/to/gklib/lib/libGKlib.a
```

## 3. HemeLB Installation - Comprehensive Guide

### Method 1: Interactive CMake Configuration
```bash
git clone https://github.com/hemelb-codes/hemelb.git
cd hemelb
mkdir build && cd build

# Load required environment modules
module load gcc openmpi

# Interactive configuration
ccmake ..
```

**ccmake Navigation**:
- Press `c`: Configure - detects dependencies and sets initial values
- Press `t`: Toggle advanced mode - shows all configuration options
- Navigate with arrow keys, edit with Enter
- Press `g`: Generate - creates Makefiles based on configuration
## First, Load MPI Module
**Critical CMake Variables to Set**:
- `CMAKE_INSTALL_PREFIX`: Where HemeLB will be installed
- `METIS_INCLUDE_DIR`: Path to METIS header files
- `METIS_LIBRARY`: Path to METIS library file (.a or .so)
- `ParMETIS_INCLUDE_DIR`: Path to ParMETIS header files  
- `ParMETIS_LIBRARY`: Path to ParMETIS library file
- `CMAKE_BUILD_TYPE`: Release (optimized) or Debug (with debug symbols)

### Method 2: Direct CMake Configuration
For when ccmake doesn't work or for scripted installations:
```bash
cmake -B build \
  -DCMAKE_INSTALL_PREFIX=/home/username/software/hemelb \
  -DCMAKE_BUILD_TYPE=Release \
  -DMETIS_INCLUDE_DIR=/path/to/metis/include \
  -DMETIS_LIBRARY=/path/to/metis/lib/libmetis.a \
  -DParMETIS_INCLUDE_DIR=/path/to/parmetis/include \
  -DParMETIS_LIBRARY=/path/to/parmetis/lib/libparmetis.a \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++

cmake --build build
cmake --install build
```

**Important Path Notes**:
- Use absolute paths, not relative paths
- Check file extensions: `.a` for static libraries, `.so` for shared libraries
- Ensure include directories contain the actual header files

## 4. Module System Setup - Complete Explanation

### Understanding Module Files
Module files manage environment variables (PATH, LD_LIBRARY_PATH) and dependencies

**Traditional Tcl Module File** (shown in notes):
```tcl
#%Module1.0
proc ModulesHelp { } {
    puts stderr "This module loads HemelB"
}
module-whatis "Loads HemelB"

# Load dependencies first
module load openmpi/5.0.7-gcc-14.3.0-source-omp-native

# Set installation root
set root /home/allen/fail/soft/hemelb

# Modify environment
prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib
setenv HEMELB_HOME $root
```

**Modern Lmod Lua Module File** (recommended):
```lua
-- -*- lua -*-
whatis("Name: HemeLB")
whatis("Version: 0.8.0")
whatis("Description: Lattice-Boltzmann simulator for blood flow")

help([[
HemeLB is a high-performance lattice-Boltzmann simulation code 
for blood flow in complex geometries.
]])

local base = "/home/username/software/hemelb"

-- Environment variables
setenv("HEMELB_HOME", base)
setenv("HEMELB_RESOURCES", pathJoin(base, "share/hemelb/resources"))

-- PATH modifications
prepend_path("PATH", pathJoin(base, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))

-- Load dependencies
load("gcc")
load("openmpi")
```

### Module File Locations
```bash
# System-wide (requires sudo)
/home/software/lmod/lmod/modulefiles/load/hemelb

# User-specific (recommended for testing)
mkdir -p ~/privatemodules/hemelb
# Add to MODULEPATH
export MODULEPATH=~/privatemodules:$MODULEPATH
```

## 5. Running HemeLB Simulations - Detailed Workflow

### Setting Up a Simulation
```bash
# Load the HemeLB module
module load hemelb

# Create working directory
mkdir -p ~/work/hemelb_simulation
cd ~/work/hemelb_simulation

# Copy example files from installation
cp $HEMELB_RESOURCES/large_cylinder.xml .
cp $HEMELB_RESOURCES/large_cylinder.gmy .

# Create output directory
mkdir output
```

### Understanding Input Files

**large_cylinder.xml** - Main configuration:
```xml
<hemelbsettings>
  <simulation>
    <steps>10000</steps>          <!-- Number of time steps -->
    <stresstype>lb</stresstype>   <!-- Lattice-Boltzmann method -->
    <voxelsize>0.01</voxelsize>   <!-- Spatial resolution -->
  </simulation>
  
  <geometry>
    <geometryformat>gmyt</geometryformat>  <!-- Geometry file format -->
    <file>large_cylinder.gmy</file>        <!-- Geometry file -->
  </geometry>
  
  <!-- Add output configuration BEFORE closing tag -->
  <properties>
    <propertyoutput file="whole.xtr" period="100">
      <geometry type="whole" />
      <field type="velocity" />
      <field type="pressure" />
    </propertyoutput>
  </properties>
</hemelbsettings>
```

**large_cylinder.gmy** - Geometry file (binary format, contains mesh)

### Running the Simulation
```bash
# Basic run
mpirun -n 4 hemelb -in large_cylinder.xml -out output/test_run_1

# Understanding the command:
# mpirun -n 4: Run with 4 MPI processes
# hemelb: The main executable
# -in large_cylinder.xml: Input configuration file
# -out output/test_run_1: Output directory
```

### Output Configuration Explained
The properties section in the XML controls what data is saved:
- `file="whole.xtr"`: Output filename
- `period="100"`: Save every 100 time steps
- `geometry type="whole"`: Save data for entire domain
- `field type="velocity"`: Save velocity field
- `field type="pressure"`: Save pressure field

## 6. Common Errors - Detailed Solutions

### Permission Error During Installation
**Error**: `Cannot create directory: /usr/local/lib64/cmake/Catch2`
**Cause**: CMake trying to install to system directory without permissions
**Solution**:
```bash
rm -rf build
mkdir build && cd build
# Specify user-writable install prefix
cmake .. -DCMAKE_INSTALL_PREFIX=/home/username/software/hemelb
make install
```

### cTemplate Python Error
**Error**: FSM generation fails during build
**Cause**: Python script execution issues for template processing
**Solution**:
```bash
# Manually run the Python scripts
cd bootstrap_build/dependencies/ctemplate-prefix/src/ctemplate/src/htmlparser

python generate_fsm.py htmlparser_fsm.config > htmlparser_fsm.h
python2 generate_fsm.py jsparser_fsm.config > jsparser_fsm.h
python generate_fsm.py ../tests/statemachine_test_fsm.config > ../tests/statemachine_test_fsm.h

# Continue build
cd ~/hemelb/build
make -j$(nproc)
```

### Character Encoding Error
**Error**: `extended character § is not valid in an identifier`
**Cause**: Source code contains invalid characters
**Solution**:
```bash
# Edit the problematic file
vi hemelb-prefix/src/hemelb/util/static_assert.h
# Remove or comment out the § character on line 81
# Change: §
# To:     // §
```

## 7. Performance Considerations

### Build Optimization
```bash
# Use all available CPU cores for compilation
make -j$(nproc)

# Build type recommendations:
-DCMAKE_BUILD_TYPE=Release    # Production use (optimized)
-DCMAKE_BUILD_TYPE=Debug      # Development (with debug symbols)
```

### Runtime Optimization
```bash
# Optimal MPI process count (usually 1 per physical core)
mpirun -n 8 hemelb -in config.xml -out results

# For large simulations, consider process binding
mpirun -n 8 --map-by core --bind-to core hemelb -in config.xml -out results
```

## 8. Best Practices Summary

### Dependency Management
1. Install all dependencies (GKLib, METIS, ParMETIS) in the same directory tree
2. Use consistent compiler versions across all dependencies
3. Keep build directories separate from source directories

### Installation Strategy
1. Use user-writable directories for installation (`/home/username/software/`)
2. Test with small examples before running large simulations
3. Use module files for easy environment management

### Simulation Workflow
1. Always start with provided examples to verify installation
2. Create separate output directories for each run
3. Monitor output files for errors and convergence

### Troubleshooting Approach
1. Always check the most recent error messages first
2. Verify all dependency paths are correct and accessible
3. Clean build directories completely when encountering configuration issues

This comprehensive approach ensures a successful HemeLB installation and provides the foundation for running complex blood flow simulations.
