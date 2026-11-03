#!/bin/bash

echo "Checking port 8080..."

PID=$(lsof -ti :8080)

if [ -n "$PID" ]; then
    echo "Stopping process on port 8080 (PID: $PID)..."
    kill $PID

    sleep 2

    # Force stop only if it is still running
    PID=$(lsof -ti :8080)
    if [ -n "$PID" ]; then
        kill -9 $PID
    fi
fi

echo "Starting FoundIt..."
./mvnw spring-boot:run