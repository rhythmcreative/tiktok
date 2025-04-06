#!/bin/bash

# Launch TikTok in a standalone chromium/chrome window
if command -v chromium &> /dev/null; then
    chromium --app="https://www.tiktok.com/" --new-window --profile-directory=TikTok
elif command -v google-chrome &> /dev/null; then
    google-chrome --app="https://www.tiktok.com/" --new-window --profile-directory=TikTok
elif command -v firefox &> /dev/null; then
    firefox --new-instance --kiosk "https://www.tiktok.com/"
else
    echo "No compatible browser found. Please install Chromium, Google Chrome, or Firefox."
    exit 1
fi

#!/bin/bash
#This launch script is only used for the AUR and other package managers combined with libelectron
cd /tiktok/application &&
npm start
