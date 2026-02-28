#!/bin/bash

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/tmp/backup_$DATE"
BUCKET_NAME="cloud-infra-backup-412461686085"
LOG_DIR="/home/ec2-user/logs"
NGINX_LOG_DIR="/var/log/nginx"

mkdir -p "$BACKUP_DIR"
echo "[$DATE] Starting backup..."

if [ -d "$LOG_DIR" ]; then
    cp -r "$LOG_DIR" "$BACKUP_DIR/uptime-logs"
    echo "Copied uptime logs"
fi

if [ -d "$NGINX_LOG_DIR" ]; then
    sudo cp -r "$NGINX_LOG_DIR" "$BACKUP_DIR/nginx-logs"
    sudo chmod -R 755 "$BACKUP_DIR/nginx-logs"
    echo "Copied nginx logs"
fi

echo "=== Disk Usage ===" > "$BACKUP_DIR/system-info.txt"
df -h >> "$BACKUP_DIR/system-info.txt"
echo "" >> "$BACKUP_DIR/system-info.txt"
echo "=== Memory Usage ===" >> "$BACKUP_DIR/system-info.txt"
free -h >> "$BACKUP_DIR/system-info.txt"
echo "" >> "$BACKUP_DIR/system-info.txt"
echo "=== Running Services ===" >> "$BACKUP_DIR/system-info.txt"
systemctl list-units --type=service --state=running >> "$BACKUP_DIR/system-info.txt"

sudo tar -czf "/tmp/backup_$DATE.tar.gz" -C /tmp "backup_$DATE"
echo "Compressed backup"

aws s3 cp "/tmp/backup_$DATE.tar.gz" "s3://$BUCKET_NAME/backups/backup_$DATE.tar.gz"
echo "Uploaded to S3: s3://$BUCKET_NAME/backups/backup_$DATE.tar.gz"

sudo rm -rf "$BACKUP_DIR"
sudo rm -f "/tmp/backup_$DATE.tar.gz"
echo "Cleaned up temp files"

echo "[$DATE] Backup complete!"
