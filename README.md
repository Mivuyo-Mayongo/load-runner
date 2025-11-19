# **Matlab Installation Steps (Linux – Cluster Setup)**

## **Step 1: Load or Install MATLAB**

### **1. Download the MATLAB Linux Installer**

* Go to the **MathWorks** website and download the *Linux installer ZIP file* for Matlab (e.g., `matlab_R2025b_Linux.zip`).
* Save it somewhere on your local machine (e.g., `Downloads` folder).

### **2. Upload the Installer to the Cluster**

You must upload the ZIP file to your cluster using `scp` from PowerShell (Windows).

**General format:**

```
scp "path/to/file.zip" username@IP_Address:/target/directory/
```

**Example using your actual path:**

```
scp "C:\Users\Mivuy\Downloads\matlab_R2025b_Linux.zip" cput@10.10.10.18:/home/cput/MATLAB_benchmark/
```

* After running this, enter the **cluster password** when prompted.
* The file will be transferred to the directory `/home/cput/MATLAB_benchmark/`.

---

## **Step 2: Prepare Installation Folder & Extract Installer**

### **1. Navigate to the Home Directory on the Head Node**

After connecting to the head node (via SSH):

```
cd /home/cput
ls -ln
```

* `cd` changes to your home directory.
* `ls -ln` lists files and folders with permissions.

### **2. Create a Folder for MATLAB Installation**

Make a dedicated folder so MATLAB files stay organized:

```
mkdir MATLAB_R2025b
```

### **3. Unzip the Installer**

Extract the ZIP file into the folder you created:

```
unzip matlab_R2025b_Linux.zip -d MATLAB_R2025b
```

This command:

* `unzip` = extracts ZIP file contents
* `-d MATLAB_R2025b` = sends all files into the `MATLAB_R2025b` folder

### **4. Enter the Installation Directory**

```
cd MATLAB_R2025b
```

Inside this folder, you should see:

* `install`
* `readme.txt`
* `bin/`
* Other installation-related files

---

If you want, I can also help you write **Step 3 (running installer)** or **turn all of this into a GitHub README format**.

