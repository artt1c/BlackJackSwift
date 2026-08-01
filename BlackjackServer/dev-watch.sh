#!/bin/bash

# Navigate to the BlackjackServer directory
cd /build/BlackjackServer

get_checksum() {
    # Find all Swift files in server and shared models, print their modification times and hash them
    find /build/BlackjackServer/Sources /build/SharedModels/Sources -name "*.swift" -type f -exec stat -c "%Y %n" {} + 2>/dev/null | sha256sum
}

echo "Starting dev watcher..."

while true; do
    echo "----------------------------------------"
    echo "Compiling and starting application..."
    echo "----------------------------------------"
    
    # Run the application in the background
    swift run BlackjackServer serve --hostname 0.0.0.0 --port 8080 &
    APP_PID=$!
    
    # Wait for changes
    CHECKSUM=$(get_checksum)
    while [ "$CHECKSUM" = "$(get_checksum)" ]; do
        sleep 1.5
    done
    
    echo "----------------------------------------"
    echo "Changes detected! Restarting..."
    echo "----------------------------------------"
    
    kill $APP_PID
    wait $APP_PID 2>/dev/null
done
