# 🚀 Installation and Usage Guide for system_optimizer-script

This guide will help you download, install, and run the **system_optimizer-script** on Debian-based Linux distributions (Ubuntu, Debian, Linux Mint, Pop!_OS, etc.).

---

## 📥 Step 1 — Download the Script

### ✔️ Option 1 — Using Git (Recommended)

```bash
git clone https://github.com/your-username/system_optimizer-script.git
cd system_optimizer-script
```

### ✔️ Option 2 — Manual Download

1. Click the green **"Code"** button on the repository page.
2. Select **"Download ZIP"**.
3. Extract the ZIP file to your preferred location.
4. Open the terminal and navigate to the extracted folder:

```bash
cd path/to/extracted-folder
```

---

## 🔧 Step 2 — Make the Script Executable

```bash
chmod +x optimizer
```

---

## 🚀 Step 3 — Run the Script

Run the script with **sudo**:

```bash
sudo ./optimizer
```

---

## 🌍 (Optional) Install Globally

If you want to be able to run the script from anywhere on your system:

```bash
sudo cp optimizer /usr/local/bin/
```

Now you can run it from any terminal like this:

```bash
sudo optimizer
```

---

## ✅ What This Script Does

- 🛠️ Updates the system.
- 🧹 Cleans:
  - Cache files
  - Logs
  - Temporary files
  - Trash
  - Old Linux kernels
- 📊 Shows disk usage **before and after cleaning** (with a simple graphical representation).
- 🔁 Offers the option to reboot the system after completion.

---

## ⚠️ Notes

- ✅ Compatible with **Debian-based distributions** only.
- ⚠️ Must be run with **sudo** or as **root**.
- 🛡️ Use responsibly. Always review any script before using it in production environments.

---

## 💙 Thank You

Thank you for using **system_optimizer-script**.  
Feel free to contribute, report issues, or suggest improvements on the [GitHub repository](https://github.com/hendrywd3v/system_optimizer-script).

---
