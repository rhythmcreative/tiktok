#!/bin/bash

# This script runs the TikTok Electron app using npm start
# It can be used for AUR and other package managers combined with libelectron

echo "Starting TikTok..."
cd /home/rhythmcreative/tiktok || exit 1
npm start
