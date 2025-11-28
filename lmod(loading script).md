Running the script is straightforward. Here’s the step-by-step:

---

### **1️⃣ Save the script**

For example, save it as `install_lmod.sh` in your home directory:

```bash
nano ~/install_lmod.sh
```

* Paste the script content.
* Save the file (`Ctrl+O`, Enter, `Ctrl+X`).

---

### **2️⃣ Make it executable**

```bash
chmod +x ~/install_lmod.sh
```

This gives the script permission to run.

---

### **3️⃣ Run the script**

```bash
./install_lmod.sh
```

or if you’re in a different directory:

```bash
bash ~/install_lmod.sh
```

### **4️⃣ After running**

1. Reload your shell to apply the changes:

```bash
source ~/.bashrc
```

2. Check Lmod:

```bash
ml --version
ml avail
echo $MODULEPATH
```

If everything is correct, `ml` should now work on the **head node** and on **compute nodes** (as long as `$HOME/software` is accessible).

---

If you want, I can give you a **one-liner to run this script on all compute nodes automatically**, so `ml` works everywhere without manual copying. Do you want me to do that?
