
set -e

APP_DIR="$HOME/foundit-production"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
PLIST="$HOME/Library/LaunchAgents/com.foundit.app.plist"
LABEL="com.foundit.app"
JAR_SOURCE="target/foundit-0.0.1-SNAPSHOT.jar"
NEW_RELEASE="$RELEASES_DIR/$(date +%Y%m%d%H%M%S)"
DOMAIN="gui/$(id -u)"
JAVA_BIN="$(/usr/libexec/java_home -v 21)/bin/java"

mkdir -p "$RELEASES_DIR" "$APP_DIR/logs" "$HOME/Library/LaunchAgents"

if [ ! -f "$JAR_SOURCE" ]; then
    echo "ERROR: JAR not found: $JAR_SOURCE"
    exit 1
fi

mkdir -p "$NEW_RELEASE"
cp "$JAR_SOURCE" "$NEW_RELEASE/app.jar"

PREVIOUS_RELEASE=""
if [ -L "$CURRENT_LINK" ]; then
    PREVIOUS_RELEASE=$(readlink "$CURRENT_LINK")
fi

# Stop the previous launchd service
launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null || true

# Switch to the new release
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

# Create a persistent macOS service
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$JAVA_BIN</string>
        <string>-jar</string>
        <string>$CURRENT_LINK/app.jar</string>
        <string>--server.port=8080</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$APP_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$APP_DIR/logs/app.log</string>
    <key>StandardErrorPath</key>
    <string>$APP_DIR/logs/app.log</string>
</dict>
</plist>
EOF

start_app() {
    launchctl bootstrap "$DOMAIN" "$PLIST"
}

echo "Starting FoundIt with launchd..."
start_app

for i in {1..30}; do
    if curl -fsS http://localhost:8080/health >/dev/null; then
        echo "Deployment successful!"
        ./scripts/health-check.sh http://localhost:8080/health
        exit 0
    fi
    sleep 2
done

echo "Deployment failed. Rolling back..."

launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null || true

if [ -n "$PREVIOUS_RELEASE" ]; then
    ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"
    start_app
    echo "Previous release restored."
else
    rm -f "$CURRENT_LINK" "$PLIST"
    echo "No previous release available."
fi

exit 1
