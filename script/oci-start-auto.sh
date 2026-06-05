#!/bin/bash

# 인스턴스 세부정보 -> OCID
# Instance details -> OCID
INSTANCE_ID=""
LOG_FILE="oci-start.log"

while true; do
  echo "$(date): System Start..." >> "$LOG_FILE"
  
  # 전원 켜기 명령 전송 / Send power-on command
  START_CMD=$(oci compute instance action --instance-id "$INSTANCE_ID" --action START 2>&1)
  
  # 1. "Out of host capacity"가 있거나 "ServiceError"가 나면 실패로 간주(500에러 포함)
  # 1. Treated as a failure if "Out of host capacity" or "ServiceError" occurs (including 500 errors).
  if echo "$START_CMD" | grep -qE "Out of host capacity|ServiceError|InternalError"; then
    echo "$(date): ❌ Oracle server down or out of stock (Status 500 / Insufficient Capacity)... Retrying in 15s." >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    sleep 15
    continue
  fi

  echo "$(date): ⏳ Start requested (STARTING)... Monitoring actual running status." >> "$LOG_FILE"
  
  # 2. 상태 모니터링(실행 명령은 들어갔으나, 리소스 부족으로 다시 중단되는 경우 탐지)
  # 2. Status Monitoring (Detecting termination due to resource shortage after command initiation)
  for i in {1..6}; do
    sleep 5
    STATUS=$(oci compute instance get --instance-id "$INSTANCE_ID" --query "data.\"lifecycle-state\"" --raw-output 2>/dev/null)
    
    # 만약 상태 조회에서 500 에러로 인해 빈값으로 나오면 루프 탈출 후 재시도
    # Break the loop and retry if the status check yields an empty response due to a 500 error.
    if [ -z "$STATUS" ]; then
      echo "$(date): ⚠️ Status check error..." >> "$LOG_FILE"
      echo "---" >> "$LOG_FILE"
      break
    fi

    echo "$(date): Current status: $STATUS" >> "$LOG_FILE"
    
    if [ "$STATUS" = "RUNNING" ]; then
      echo "$(date): 🎉 [Start Success] Server is running! Exiting the loop." >> "$LOG_FILE"
      exit 0
    elif [ "$STATUS" = "STOPPED" ]; then
      echo "$(date): ⚠️ Server stopped unexpectedly during startup." >> "$LOG_FILE"
      echo "---" >> "$LOG_FILE"
      break
    fi
  done

  echo "$(date): 🔄 Proceeding to the next attempt..." >> "$LOG_FILE"
  sleep 5
done