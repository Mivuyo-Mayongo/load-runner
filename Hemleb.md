## HemeLB Installation and Run Guid
*Create the main-software diretcory structure
``
mkdir -p ~/mivuyo/software
cd ~/mivuyo/software
``
## Prerequisites
sudo dnf install cmake
sudo dnf groupinstall "Development Tools"
sudo yum install tinyxml-devel # this might give you an error reason might be requiring to enable EPEL
##enable Epel
sudo dnf install epel-release -y
##re run 
sudo yum install tinyxml-devel

## HemelB Installation Only
cd ~/mivuyo/software
** clone HemeLB
git clone https://github.com/hemelb-codes/hemelb.git
cd hemelb

mkdir build
cd build
**Load MPI module
module load mpi/openmpi-x86_64

ccmake ..
# press `c` to config
# press `e` to exit
# Maybe press `c` to config again
# press g to generate a Unix MakeFile and exit back

# Important setting to change
# ParMetis tarball : https://karypis.github.io/glaros/files/sw/parmetis/parmetis-4.0.3.tar.gz
# install dir : ~/bin

make -j$(nproc)

## Hemelb Module Setup
mkdir -p ~/mivuyo/software/lmod/modulefiles/load
nano ~/mivuyo/software/lmod/modulefiles/load/hemelb
## step2 
#%Module1.0

proc ModulesHelp { } {
    puts stderr "Loads HemeLB environment"
}

module-whatis "HemeLB module"
``
#IMPORTANT:
#Pay very close attention to the MPI module version available on your system!
#You MUST load the correct MPI module here, otherwise the module will FAIL.
#Example: On your machine the correct module is:
#openmpi/5.0.9
#NOT mpi/openmpi-x86_64 (this one does NOT exist)
#So update the line below to match your actual 'module avail' output.

module load openmpi/5.0.9

set root /home/cput/mivuyo/software/hemelb

prepend-path PATH $root/bin
setenv HEMELB_HOME $root

## STEP 3 - Load the module
module use /home/cput/mivuyo/software/lmod/lmod/modulefiles/load
module --ignore_cache avail
module --ignore_cache load hemelb
## Step 4- verify it works
echo $HEMELB_HOME
which hemelb

## HemelB RUN
# 1. Create working directory
mkdir ~/work
cd ~/work

# 2. Copy benchmark files (adjust path to your installation)
cp ~/mivuyo/software/hemelb/hemleb/share/hemelb/resources/large_cylinder.xml .
cp ~/mivuyo/software/hemelb/hemleb/share/hemelb/resources/large_cylinder.gmy .

# 3. Create output directory
mkdir output

# 4. Edit configuration file
nano large_cylinder.xml
### Editing the XML configuration 
Add the output properties section before the closing </hemelbsettings>

<properties>
  <propertyoutput file="whole.xtr" period="100">
    <geometry type="whole" />
    <field type="velocity" />
    <field type="pressure" />
  </propertyoutput>
</properties>

## Running Simulations
# Method 1: Using hemelb from PATH (if module loaded)
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test

# Method 2: Using full path to executable
mpirun -n 4 ~/mivuyo/software/hemelb/hemleb/bin/hemelb -in large_cylinder.xml -out output/large_cylinder_test

# Run multiple tests
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test1
mpirun -n 4 hemelb -in large_cylinder.xml -out output/large_cylinder_test2
