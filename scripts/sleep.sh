#!/bin/bash

# Kill any existing swayidle instances
killall swayidle 2>/dev/null

# Function to check if media is playing with multiple detection methods
is_media_playing() {
    # Method 1: Check playerctl
    if playerctl status 2>/dev/null | grep -q "Playing"; then
        echo "$(date): Playerctl detected playing media" >> /tmp/idle_debug.log
        return 0
    fi

    # Method 2: Check for audio output
    if pactl list short sinks | grep -q RUNNING; then
        echo "$(date): Audio output detected" >> /tmp/idle_debug.log
        return 0
    fi

    # Method 3: Check browser tab audio
    if pgrep -f "chromium.*--type=renderer" > /dev/null || pgrep -f "firefox.*-contentproc" > /dev/null; then
        # If browser process with potential audio is found
        echo "$(date): Browser with potential audio detected" >> /tmp/idle_debug.log
        return 0
    fi

    echo "$(date): No media activity detected" >> /tmp/idle_debug.log
    return 1
}

# Function for lock command
do_lock() {
    if ! is_media_playing; then
        echo "$(date): Executing lock" >> /tmp/idle_debug.log
        swaylock --clock --fade-in 0.5 --grace 5 --effect-blur 7x5
    else
        echo "$(date): Skipping lock - media is active" >> /tmp/idle_debug.log
    fi
}

# Function for suspend command
do_suspend() {
    if ! is_media_playing; then
        echo "$(date): Executing suspend" >> /tmp/idle_debug.log
        systemctl suspend
    else
        echo "$(date): Skipping suspend - media is active" >> /tmp/idle_debug.log
    fi
}

# Clear old log
echo "$(date): Starting new session" > /tmp/idle_debug.log

# Start swayidle with explicit command calls
swayidle -w \
    timeout 300 'bash -c "$(declare -f is_media_playing do_lock); do_lock"' \
    timeout 450 'bash -c "$(declare -f is_media_playing do_suspend); do_suspend"' \
    before-sleep 'swaylock --clock --fade-in 0.5 --grace 5 --effect-blur 7x5' &

# Save the PID
echo $! > /tmp/swayidle.pid
