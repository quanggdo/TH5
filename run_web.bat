@echo off
REM Script để chạy ứng dụng với port web cố định (Windows)

REM Port cố định
set WEB_PORT=5000

echo 🚀 Chạy Habit Tracker với port web cố định: %WEB_PORT%
echo 📱 URL: http://localhost:%WEB_PORT%
echo.

REM Chạy ứng dụng với port cố định
flutter run -d chrome --web-port=%WEB_PORT%

pause
