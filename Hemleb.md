# HemeLB Installation and Run Guide

## Create the Main Software Directory Structure
```bash
mkdir -p ~/mivuyo/software
cd ~/mivuyo/software
```

## Prerequisites
```bash
sudo dnf install cmake
sudo dnf groupinstall "Development Tools"
sudo yum install tinyxml-devel # might require enabling EPEL
```

### Enable EPEL
```bash
sudo dnf install epel-release -y
sudo yum install tinyxml-devel
```

## HemeLB Installation
```bash
cd ~/mivuyo/software
# Clone HemeLB
git clone https://github.com/hemelb-codes/hemelb.git
cd hemelb

mkdir build
cd build

# Load MPI module
module load mpi/openmpi-x86_64

ccmake ..
# press 'c' to config
# press 'e' to exit
# maybe press 'c' again
# press 'g' to generate Unix Makefile and exit

# Important settings:
# ParMetis tarball: https://karypis.github.io/glaros/files/sw/parmetis/parmetis-4.0.3.tar.gz
# install dir: ~/bin

make -j$(nproc)
```

## Hemelb Module Setup
```bash
mkdir -p ~/mivuyo/software/lmod/modulefiles/load
nano ~/mivuyo/software/lmod/modulefiles/load/hemelb
```

Add the following:
```tcl
#%Module1.0
proc ModulesHelp { } {
    puts stderr "Loads HemeLB environment"
}
module-whatis "HemeLB module"

# IMPORTANT:
# Pay close attention to MPI module version!
# Example: openmpi/5.0.9 (NOT mpi/openmpi-x86_64)

module load openmpi/5.0.9

set root /home/cput/mivuyo/software/hemelb
prepend-path PATH $root/bin
setenv HEMELB_HOME $root
```

### Load the Module
```bash
module use /home/cput/mivuyo/software/lmod/lmod/modulefiles/load
module --ignore_cache avail
module --ignore_cache load hemelb
```

Verify:
```bash
echo $HEMELB_HOME
which hemelb
```

## HemeLB Run
```bash
# 1. Create working directory
mkdir ~/work
cd ~/work

# 2. Copy benchmark files
cp ~/mivuyo/software/hemelb/hemleb/share/hemelb/resources/large_cylinder.xml .
cp ~/mivuyo/software/hemelb/hemleb/share/hemelb/resources/large_cylinder.gmy .

# 3. Create output directory
mkdir output

# 4. Edit configuration file
nano large_cylinder.xml
```

### XML Configuration Addition
Add before `</hemelbsettings>`:
```xml
<properties>
  <propertyoutput file="whole.xtr" period="100">
    <geometry type="whole" />
    <field type="velocity" />
    <field type="pressure" />
  </propertyoutput>
</properties>
```

## Running Simulations
```bash
# Method 1: Using hemelb from PATH
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test

# Method 2: Full path
mpirun -n 4 ~/mivuyo/software/hemelb/hemleb/bin/hemelb -in large_cylinder.xml -out output/large_cylinder_test

# Multiple tests
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test1
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test2
```
