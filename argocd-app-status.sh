#!/bin/bash

TIMEOUT=300
INTERVAL=5
START_TIME=$(date +%s)

ARGOCD_TOKEN="..."
ARGOCD_URL="..."
APP_NAME="..."

echo_exit() {
  echo "$1"
  exit $2
}

get_sync_status() {
  RESPONSE=$(curl -s -X GET "https://$ARGOCD_URL/api/v1/applications/$APP_NAME" \
    -H "Authorization: Bearer $ARGOCD_TOKEN" \
    -H "Content-Type: application/json")
  if [[ -z "$RESPONSE" ]]; then
    echo_exit "[ERROR] Failed to fetch sync status." 3
  fi
  echo "$RESPONSE" | jq -r .status.sync.status
}

get_health_status() {
  RESPONSE=$(curl -s -X GET "https://$ARGOCD_URL/api/v1/applications/$APP_NAME" \
    -H "Authorization: Bearer $ARGOCD_TOKEN" \
    -H "Content-Type: application/json")
  if [[ -z "$RESPONSE" ]]; then
    echo_exit "[ERROR] Failed to fetch health status." 3
  fi
  echo "$RESPONSE" | jq -r .status.health.status
}

check_application_status() {
  while true; do
    SYNC_STATUS=$(get_sync_status)
    HEALTH_STATUS=$(get_health_status)
    echo "[INFO] Sync status: $SYNC_STATUS, Health status: $HEALTH_STATUS"

    if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
      echo_exit "[SUCCESS] Application is successfully synced and healthy." 0
    fi
    
    if [[ "$SYNC_STATUS" == "OutOfSync" || "$HEALTH_STATUS" == "Unhealthy" ]]; then
      echo_exit "[WARNING] Application is in an undesired state: $SYNC_STATUS, $HEALTH_STATUS" 1
    fi

    CURRENT_TIME=$(date +%s)
    if (( CURRENT_TIME - START_TIME >= TIMEOUT )); then
      echo_exit "[ERROR] Timeout reached. Exiting." 2
    fi

    sleep $INTERVAL
  done
}

echo "Starting ArgoCD application status check..." 
check_application_status
