# 🚀 Hướng dẫn chạy Habit Tracker

## 📋 Yêu cầu

- Flutter SDK (version 3.11.1+)
- Dart SDK
- Chrome (để chạy web)

## 🌐 Chạy trên Web với Port Cố Định

### Phương pháp 1: Sử dụng Script (Khuyên dùng)

**Trên Windows:**
```bash
run_web.bat
```

**Trên macOS/Linux:**
```bash
bash run_web.sh
```

### Phương pháp 2: Chạy thủ công

```bash
# Port cố định: 5000
flutter run -d chrome --web-port=5000
```

**URL truy cập:** `http://localhost:5000`

## 📱 Chạy trên Thiết bị di động

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

## 🔧 Cấu hình Port Web

Để thay đổi port, chỉnh sửa:
- **run_web.bat** hoặc **run_web.sh**: Thay đổi giá trị `WEB_PORT`
- **lib/utils/web_config.dart**: Cập nhật `DEFAULT_WEB_PORT` và `WEB_URL`

Ví dụ (port 8080):
```bash
flutter run -d chrome --web-port=8080
```

## 📦 Cài đặt Dependencies

```bash
flutter pub get
```

## 🧪 Chạy Tests

```bash
flutter test
```

## 🏗️ Build Production

**Web:**
```bash
flutter build web --web-port=5000
```

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

---

**App Title:** Habit tracker - Nhóm 2  
**Port Mặc định:** 5000  
**Kiến trúc:** MVVM
