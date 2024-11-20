### check_ceph_daemons.py

`rgw`(RADOS Gateway)와 `node-exporter` 데몬의 상태를 모니터링하고 비정상 상태에서 자동으로 재시작하여 서비스 가용성을 보장하는 스크립트입니다.

---

#### 배경

이 스크립트는 `https://s3.mycephcluster.com` 엔드포인트에서 간헐적으로 발생한 **503 Service Unavailable** 오류를 해결하기 위해 개발되었습니다. 해당 문제는 의존 서비스에 심각한 영향을 미쳤습니다.

---

### 장애 요약

#### 영향
- `https://s3.myceph-cluster.com` 외부 링크가 접근 불가.
- 버킷 접근 실패.
- `Object Gateway -> Buckets` 목록에 있는 모든 버킷 사용 불가.

#### 근본 원인
- 3개의 **RGW 데몬**(RADOS Gateway)이 동시에 응답하지 않는 "freeze" 상태에 진입.
- Ceph 클러스터는 데몬 상태를 `running`으로 표시했으나, 로그 기록이나 헬스 체크에 응답하지 않음.
- HAProxy 인그레스에서 헬스 체크 실패로 인해 RGW 인스턴스를 제외하며 **503 오류** 발생.

```bash
$ ceph orch ps --daemon-type rgw
NAME                           HOST         PORTS    STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
rgw.hangrum.myceph-m-01.hfswvz  myceph-m-01  *:18080  running (5h)      8m ago   7M     257M        -  17.2.5   cc65afd6173a  d6a2ec4f6b8b
rgw.hangrum.myceph-m-02.zvuvsr  myceph-m-02  *:18080  running (3d)     35s ago   7M     415M        -  17.2.5   cc65afd6173a  a08ca3c1cb0e
rgw.hangrum.myceph-m-03.obvccd  myceph-m-03  *:18080  running (12d)    35s ago   7M     293M        -  17.2.5   cc65afd6173a  a847ccda1d72
```

### 해결책

`check_ceph_daemons.py` 스크립트는 5분마다 **cron job**으로 실행되며, 지정된 데몬의 상태를 확인하고 비정상 상태일 경우 이를 재시작합니다.

```bash
$ cat /etc/cron.d/check_ceph_daemons
*/5 * * * * root /srv/cron-script/check_ceph_daemons.py
```

### 작동 방식

1. **헬스 체크**:
   - 각 데몬의 루트 URL (`http://{host}:{port}`)을 확인합니다.
   - **HTTP 200** 응답을 5초 내에 받지 못하면 비정상으로 간주합니다.

2. **비정상 데몬 재시작**:
   - 비정상으로 확인된 데몬에 대해 다음 명령어 실행:
     ```bash
     ceph orch daemon restart {daemon-type}.{daemon-id}
     ```

3. **데몬 타입 설정 가능**:
   - 현재는 `rgw`와 `node-exporter`를 모니터링합니다.
   - 추가 데몬을 모니터링하려면 `target` 리스트에 타입을 추가:
     ```python
     target = ['rgw', 'node-exporter']
     ```

4. **데몬 타입 식별**:
   - `ceph orch ps` 명령어를 사용하여 데몬 타입을 식별. `NAME` 컬럼의 첫 번째 `.` 이전 부분이 데몬 타입입니다:
     ```bash
     $ ceph orch ps
     NAME                                    HOST         PORTS        STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION         IMAGE ID      CONTAINER ID
     alertmanager.myceph-m-02                myceph-m-02  *:9093,9094  running (3w)      8m ago   7M    20.5M        -                  ba2b418f427c  5fc2ca58c707
     crash.myceph-01                         myceph-01                 running (7M)      6m ago  15M    8848k        -  17.2.5          cc65afd6173a  2800980bf3b8
     ```

### 사용법

1. **데몬 설정**:
   - 모니터링할 데몬 타입을 스크립트의 `target` 리스트에 추가:
     ```python
     target = ['rgw', 'node-exporter']
     ```

2. **헬스 체크 로직**:
   - 스크립트는 `requests` 라이브러리를 사용하여 각 데몬의 루트 URL에 HTTP GET 요청을 전송.
   - 응답이 없거나 오류가 발생하면 데몬을 재시작.

3. **예제 재시작 명령**:
   ```bash
   ceph orch daemon restart rgw.hangrum.myceph-m-01.hfswvz
