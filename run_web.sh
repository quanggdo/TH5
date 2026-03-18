#!/bin/bash
# Script để chạy ứng dụng với port web cố định

# Port cố định
WEB_PORT=5000

echo "🚀 Chạy Habit Tracker với port web cố định: $WEB_PORT"
echo "📱 URL: http://localhost:$WEB_PORT"
echo ""

# Chạy ứng dụng với port cố định
flutter run -d chrome --web-port=$WEB_PORT
