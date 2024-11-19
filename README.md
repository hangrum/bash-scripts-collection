# System Automation Scripts

This is a curated collection of scripts and playbooks I developed to tackle various system management, automation, and troubleshooting tasks. Each script is designed to simplify workflows, improve efficiency, and handle large-scale operations when necessary.

---

## 📂 Script Highlights

### 🔧 **System Administration**
- **`bash/motd-secure.sh`**  
  Disables system MOTD, secures related configurations, and cleans up unnecessary messages.
- **`bash/set-umask-to-all.sh`**  
  Globally enforces `umask 022` for all users to maintain consistent file permissions.

### 🌐 **Network & API**
- **`python/pause_prtg.py`**  
  Pauses or resumes PRTG devices through API integration, based on hostname.
- **`bash/ipmi-sel-clean.sh`**  
  Clears IPMI SEL logs and syncs system clocks to maintain hardware health.

### 🛠️ **DevOps & Automation**
- **`ansible/update-ca-certificates.yml`**  
  Ansible tasks for updating CA certificates, addressing issues like Comodo AddTrust expiration.
- **`python/check_ceph_daemons.py`**  
  Monitors and restarts unhealthy Ceph daemons automatically to ensure cluster stability.

### 📊 **High-Performance Operations**
- **`bash/s3-log-structure-update.sh`**  
  Processes and restructures S3 log file paths in parallel, enabling ingestion of massive log datasets.
  - **THREAD variable to specify maximum threads**
    - Default is set to 5. If the number of files is 5 or less, the number of threads is automatically reduced.
    - For more than 5 files, the file list is evenly distributed across a maximum of 5 threads.
  - **Generate and distribute file lists from S3**
    - Retrieves the full list of target files (`wp-images-access-log202`) from S3 and splits them into smaller lists using `split` for parallel processing.
  - **Copy to the new structure, validate, and delete original files**
    - Copies files to the new directory structure, validates the process, and deletes the original files once verification is complete.

#### Key Variables
- **BUCKET**: S3 bucket address.
- **THREAD**: Maximum number of executable threads.
- **FILE_DIR**: Temporary directory to store the S3 file list.
- **LOG_DIR**: Directory for storing log files.

---

## Why This Collection?
These scripts represent practical solutions I've built for real-world scenarios in system engineering. Whether it's managing thousands of files, optimizing log pipelines, or automating repetitive tasks, this collection showcases my approach to problem-solving and efficiency in large-scale environments.

---
