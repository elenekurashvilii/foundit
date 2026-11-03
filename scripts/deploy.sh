set -e

APP_DIR="$HOME/foundit-production"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
JAR_SOURCE="target/foundit-0.0.1-SNAPSHOT.jar"
NEW_RELEASE="$RELEASES_DIR/$(date +%Y%m%d%H%M%S)"
PORT=8080

mkdir -p "$RELEASES_DIR" "$APP_DIR/logs"

if [ ! -f "$JAR_SOURCE" ]; then
    echo "ERROR: JAR file not found: $JAR_SOURCE"
    exit 1
fi

mkdir -p "$NEW_RELEASE"
cp "$JAR_SOURCE" "$NEW_RELEASE/app.jar"

PREVIOUS_RELEASE=""
if [ -L "$CURRENT_LINK" ]; then
    PREVIOUS_RELEASE=$(readlink "$CURRENT_LINK")
fi

echo "Stopping previous application..."
if [ -f "$APP_DIR/app.pid" ]; then
    kill "$(cat "$APP_DIR/app.pid")" 2>/dev/null || true
fi

ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "Starting new release..."
nohup java -jar "$CURRENT_LINK/app.jar" --server.port=$PORT \
    > "$APP_DIR/logs/app.log" 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$APP_DIR/app.pid"

echo "Waiting for application health check..."
for i in {1..30}; do
    if curl -fsS "http://localhost:$PORT/health" > /dev/null; then
        echo "Deployment successful!"
        ./scripts/health-check.sh "http://localhost:$PORT/health"
        exit 0
    fi
    sleep 2
done

echo "Deployment failed. Rolling back..."

kill "$NEW_PID" 2>/dev/null || true

if [ -n "$PREVIOUS_RELEASE" ]; then
    ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"
    nohup java -jar "$CURRENT_LINK/app.jar" --server.port=$PORT \
        > "$APP_DIR/logs/app.log" 2>&1 &
    echo $! > "$APP_DIR/app.pid"
    echo "Previous release restored."
else
    rm -f "$CURRENT_LINK" "$APP_DIR/app.pid"
    echo "No previous release available."
fi

exit 1