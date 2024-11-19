# Bash & Automation Scripts

This is a collection of scripts and playbooks I developed to tackle various system management, automation, and troubleshooting tasks. Each script is designed to simplify workflows, improve efficiency, and handle large-scale operations when necessary.

---

## 📂 Script Highlights

### 🔧 **System Administration**
- **`motd-secure.sh`**  
  Disables system MOTD, secures related configurations, and cleans up unnecessary messages.
- **`set-umask-to-all.sh`**  
  Globally enforces `umask 022` for all users to maintain consistent file permissions.

### 🌐 **Network & API**
- **`pause_prtg.py`**  
  Pauses or resumes PRTG devices through API integration, based on hostname.
- **`ipmi-sel-clean.sh`**  
  Clears IPMI SEL logs and syncs system clocks to maintain hardware health.

### 🛠️ **DevOps & Automation**
- **`update-ca-certificates.yml`**  
  Ansible tasks for updating CA certificates, addressing issues like Comodo AddTrust expiration.
- **`check_ceph_daemons.py`**  
  Monitors and restarts unhealthy Ceph daemons automatically to ensure cluster stability.

### 📊 **High-Performance Operations**
- **`s3-log-structure-update.sh`**  
  Processes and restructures S3 log file paths in parallel, enabling ingestion of massive log datasets.

---

## Why This Collection?
These scripts represent practical solutions I've built for real-world scenarios in system engineering. Whether it's managing thousands of files, optimizing log pipelines, or automating repetitive tasks, this collection showcases my approach to problem-solving and efficiency in large-scale environments.

---
