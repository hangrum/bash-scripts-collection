#!/bin/bash
# Written by sm2972@gmail.com
# As-Is: s3://web-access-log/access-log2020-08-27-05-35-44-4A074562F35D14ED
# To-Be: s3://web-access-log/2020/08/27/05/35-44-4A074562F35D14ED

# THREAD: 사용할 최고 스레드
THREAD=7
BUCKET="s3://web-access-log"
# TMP_BUCKET_FILE_LIST_DIR: 변경 대상 bucket file list 를 저장하는 디렉토리
TMP_BUCKET_FILE_LIST_DIR="/var/tmp"
# TOTAL_S3_FILE_LIST: 변경 대상 bucket file list 전체 리스트. split 명령으로 스레드 수로 라인을 나눠 저장
TOTAL_S3_FILE_LIST="s3_access_log_total_list"
S3_TARGET_LIST="$TMP_BUCKET_FILE_LIST_DIR/$TOTAL_S3_FILE_LIST"
# LOG_DIR: 로그 파일 저장 디렉토리
LOG_DIR="/var/log/aws_s3_batch"
# SPLIT_FILE_PATTERN: split 할때 저장될 파일 패턴(접두어). split -d 옵션으로 뒤에 숫자가 붙게 된다.
SPLIT_FILE_PATTERN="s3_list"

# LOG: 로그파일 이름
LOG="$LOG_DIR/aws_s3_batch.log"

# 로그 디렉토리 없을시 생성
if [ ! -d $LOG_DIR ]; then
	mkdir -p $LOG_DIR
fi

now() 
{ 
	echo [$(date '+%Y-%m-%d %H:%M:%S')]
}

log() 
{ 
	echo "$(now) $1" >> $LOG
}

# change_structure: s3 파일 구조변경 함수
# As-Is: s3://web-access-log/access-log2020-08-27-05-35-44-4A074562F35D14ED
# To-Be: s3://web-access-log/2020/08/27/05/35-44-4A074562F35D14ED
change_structure()
{
for i in $(cat $1); do # $1: SPLIT_FILE_PATTERN 파일
	NEWPATH=$(echo $i | sed -e 's/access-log\([[:digit:]]\{4\}\)-\([[:digit:]]\{2\}\)-\([[:digit:]]\{2\}\)-\([[:digit:]]\{2\}\)-\(.*\)/\1\/\2\/\3\/\4\/\5/g')
	log "[INFO] Copy: $BUCKET/$i to $BUCKET/$NEWPATH"
	/usr/local/bin/aws s3 cp $BUCKET/$i $BUCKET/$NEWPATH --quiet
	EXSISTS=$(/usr/local/bin/aws s3 ls $BUCKET/$NEWPATH)
	if [ ! -z "$EXSISTS" ]; then
		log "[INFO] Delete: $BUCKET/$i"
		/usr/local/bin/aws s3 rm $BUCKET/$i --quiet
	else
		log "[ERROR] Failed copy: $BUCKET/$i It will try again next running"
	fi
done

# 변경 완료 후 해당SPLIT_FILE_PATTERN 삭제
rm $1 2>/dev/null
log "[INFO] COMPLETE: file removed $1"
}

# S3_ACCESS_FILE_CNT: bucket 에 구조 변경 대상 파일 갯수
S3_ACCESS_FILE_CNT=$(/usr/local/bin/aws s3 ls $BUCKET | grep -access-log202 | wc -l)

# 변경할 로그 없을 경우 exit
if [ $S3_ACCESS_FILE_CNT -eq 0 ];then
	exit 1

# THREAD 갯수보다 S3_ACCESS_FILE_CNT 가 적을 경우 THREAD 수를 줄여서 실행.
# ex) THREAD=5, S3_ACCESS_FILE_CNT=3 일 경우 THREAD = 3 으로 변경하여
# 파일 리스트 올라오는대로 바로 작업 하기 위한 조치 and 중복 작업 방지
elif [ $S3_ACCESS_FILE_CNT -lt $THREAD ];then
	THREAD=$S3_ACCESS_FILE_CNT
fi

# PROCESS_CNT: 본 스크립트 돌고있는 갯수 파악
PROCESS_CNT=$(ps aux | grep $0 | grep -v grep |wc -l)

# 기존 프로세스가 돌고 있으면 exit
# PROCESS_CNT-3: cronjob 실행 시 3개 프로세스가 생성됨. 기존 프로세스만 count 위해 -3
if [ $((PROCESS_CNT-3)) -lt $THREAD ];then
	/usr/local/bin/aws s3 ls $BUCKET | grep '-access-log202' | awk '{print $4}' > $S3_TARGET_LIST
else
	log "[INFO] Script already running. Process count: $PROCESS_CNT"
	exit 1
fi

# LINE_COUNT: split 실행전 대상 파일 전체 갯수,
# LINE_PER_THREAD: 스래드당 처리 라인
LINE_COUNT=$(cat $S3_TARGET_LIST | wc -l)
LINE_PER_THREAD=$(echo "scale=0; $LINE_COUNT/$THREAD" | bc -l)
log "[INFO] Found $LINE_COUNT log files on $BUCKET"

# -d: 파일명 SPLIT_FILE_PATTERN 뒤 숫자를 매겨 파일 생성
# -l: 나눌 라인 수
split -d -l $LINE_PER_THREAD $S3_TARGET_LIST $TMP_BUCKET_FILE_LIST_DIR/$SPLIT_FILE_PATTERN

# split 명령 이후 생성된 파일 목록
SPLIT_FILE_LIST=$(find $TMP_BUCKET_FILE_LIST_DIR -type f -name "$SPLIT_FILE_PATTERN*")
#REMAIN_SPLIT_FILE_LIST=$(find $TMP_BUCKET_FILE_LIST_DIR -type f -name "$SPLIT_FILE_PATTERN*"|wc -l)
REMAIN_SPLIT_FILE_LIST()
{
echo $(find $TMP_BUCKET_FILE_LIST_DIR -type f -name "$SPLIT_FILE_PATTERN*"|wc -l)
}

log "[INFO] Total $(REMAIN_SPLIT_FILE_LIST) thread started."
log "[INFO] $LINE_PER_THREAD files per thread running."

for i in $SPLIT_FILE_LIST;do
	log "[INFO] Start $BUCKET files relocate Thread: $i"
	# split 된 파일 별로 함수 실행
	change_structure $i &
done
# CNT: 좀비 프로세스를 막기 위한 count
CNT=0
while true;do
	# 도는 프로세스가 없으면 완료로 로그에 기록 및 종료
	if [ $(REMAIN_SPLIT_FILE_LIST) -eq 0 ];then
		log "[INFO] Complete $BUCKET files relocate"
		exit 0
	else
	# 만약 10번 반복했을때 process 가 계속 살아있다면 종료
		sleep 1
		((CNT=CNT+1))
		if [ $CNT -gt 10 ];then
			exit 1
		fi
	fi
done

exit 0
