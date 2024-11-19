### check_ceph_daemons.py

A script designed to monitor and restart unhealthy Ceph daemons, particularly the `rgw` (RADOS Gateway) and `node-exporter` daemons, ensuring uninterrupted service availability.

---

#### Background

The script was developed to address intermittent service disruptions observed at the endpoint `https://s3.mycephcluster.com`. These disruptions manifested as **503 Service Unavailable** errors, causing significant impact on dependent services.

---

### Incident Summary

#### Impact
- External links to `https://s3.myceph-cluster.com` were inaccessible.  
- Unable to access bucket.
- All buckets listed under `Object Gateway -> Buckets` became unavailable.  

#### Root Cause
- All 3 **RGW daemons** (RADOS Gateway) entered an unresponsive "freeze" state simultaneously.
- While the Ceph cluster reported the daemons as `running`, they failed to log any activity or respond to health checks.
- The HAProxy-based ingress excluded the RGW instances due to failed health checks, resulting in **503 errors**.

```bash
$ ceph orch ps --daemon-type rgw
NAME                           HOST         PORTS    STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
rgw.hangrum.myceph-m-01.hfswvz  myceph-m-01  *:18080  running (5h)      8m ago   7M     257M        -  17.2.5   cc65afd6173a  d6a2ec4f6b8b
rgw.hangrum.myceph-m-02.zvuvsr  myceph-m-02  *:18080  running (3d)     35s ago   7M     415M        -  17.2.5   cc65afd6173a  a08ca3c1cb0e
rgw.hangrum.myceph-m-03.obvccd  myceph-m-03  *:18080  running (12d)    35s ago   7M     293M        -  17.2.5   cc65afd6173a  a847ccda1d72
```

### Solution

The `check_ceph_daemons.py` script was implemented as a **cron job** running every 5 minutes. It checks the health of specified daemons and restarts them if they become unresponsive.

```bash
$ cat /etc/cron.d/check_ceph_daemons
*/5 * * * * root /srv/cron-script/check_ceph_daemons.py
```

### How It Works

1. **Health Check**:
   - The script checks the root URL (`http://{host}:{port}`) of each daemon.
   - If no **HTTP 200** response is received within 5 seconds, the daemon is flagged as unhealthy.

2. **Restart Unhealthy Daemons**:
   - For each unhealthy daemon, the script runs:
     ```bash
     ceph orch daemon restart {daemon-type}.{daemon-id}
     ```

3. **Configurable Daemon Types**:
   - The script currently monitors `rgw` and `node-exporter`.
   - To add more daemons, simply append their types to the `target` list:
     ```python
     target = ['rgw', 'node-exporter']
     ```

4. **Identifying Daemon Types**:
   - Use the `ceph orch ps` command. The daemon type is derived from the `NAME` column, taking the part before the first `.`:
     ```bash
     $ ceph orch ps
     NAME                                    HOST         PORTS        STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION         IMAGE ID      CONTAINER ID
     alertmanager.myceph-m-02                myceph-m-02  *:9093,9094  running (3w)      8m ago   7M    20.5M        -                  ba2b418f427c  5fc2ca58c707
     crash.myceph-01                         myceph-01                 running (7M)      6m ago  15M    8848k        -  17.2.5          cc65afd6173a  2800980bf3b8
     ```

---

### Usage

1. **Daemon Configuration**:
   - Add the desired daemon types to the `target` list in the script:
     ```python
     target = ['rgw', 'node-exporter']
     ```

2. **Health Check Logic**:
   - The script uses `requests` to send an HTTP GET request to each daemon's root URL.
   - If no response or an error occurs, the daemon is restarted.

3. **Example Restart Command**:
   ```bash
   ceph orch daemon restart rgw.hangrum.myceph-m-01.hfswvz
   ```
