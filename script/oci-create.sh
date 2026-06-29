#!/bin/bash
LOG_FILE="oci-instance-created.log"
SUCCESS_FLAG="$HOME/.oci-instance-created"

# 본인 환경에 맞게 수정 / Customize for your environment
COMPARTMENT_ID="" # 계정 태넌시 OCID (Tenancy OCID)
AVAILABILITY_DOMAIN="" # 생성위치 (Identity domain) / ex) Rhgk:AP-CHUNCHEON-1-AD-1
SUBNET_ID="" # 서브넷OCID (SUBNET OCID)
IMAGE_ID="" # 운영체제 OCID (OS OCID) / https://docs.oracle.com/en-us/iaas/images/index.htm
INSTANCE_NAME="" # 인스턴스 이름 (Instance Name)
VOLUME_SIZE=100 # 볼륨 사이즈 (Volume size)
SSH_KEY_FILE=""  # SSH 공개키 파일 경로 (Path to the SSH public key file) / ex) oci.pub


# 이미 성공했으면 종료 / Success. Exiting...
if [ -f "$SUCCESS_FLAG" ]; then
    exit 0
fi

while true; do
    echo "$(date): Attempting to create instance..." >> "$LOG_FILE"

    RESULT=$(oci compute instance launch \
        --compartment-id "$COMPARTMENT_ID" \
        --availability-domain "$AVAILABILITY_DOMAIN" \
        --shape "VM.Standard.A1.Flex" \
        --shape-config '{"ocpus": 2, "memoryInGBs": 12}' \
        --subnet-id "$SUBNET_ID" \
        --source-details "{\"sourceType\":\"image\",\"imageId\":\"$IMAGE_ID\",\"bootVolumeSizeInGBs\":$VOLUME_SIZE}" \
        --assign-public-ip true \
        --ssh-authorized-keys-file "$SSH_KEY_FILE" \
        --display-name "$INSTANCE_NAME" \
        2>&1)

    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ] && echo "$RESULT" | grep -q "ocid1.instance"; then
        echo "$(date): SUCCESS!" >> "$LOG_FILE"
        echo "$RESULT" >> "$LOG_FILE"
        touch "$SUCCESS_FLAG"
        exit 0
    else
        # 에러 상세 로그 기록 / Record detailed error logs
        echo "$(date): Failed (exit code: $EXIT_CODE)" >> "$LOG_FILE"
        echo "$RESULT" >> "$LOG_FILE"
        echo "---" >> "$LOG_FILE"
        sleep 120
    fi
done
