
APP_URL="${1:-http://localhost:8080/health}"
LOG_DIR="$HOME/foundit-production/logs"
LOG_FILE="$LOG_DIR/health-check.log"

mkdir -p "$LOG_DIR"

if curl -fsS "$APP_URL" > /dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - UP - $APP_URL" | tee -a "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - DOWN - $APP_URL" | tee -a "$LOG_FILE"
    exit 1
fi