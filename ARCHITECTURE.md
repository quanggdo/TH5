# Ứng dụng Theo dõi Thói quen - Hướng dẫn cấu trúc

## 📁 Cấu trúc Thư mục (MVVM Architecture)

```
lib/
├── main.dart                          # Entry point ứng dụng
├── firebase_options.dart              # Cấu hình Firebase
│
├── models/                            # Model Layer (M)
│   ├── habit_model.dart              # Model cho Thói quen
│   └── habit_log_model.dart          # Model cho Log thực hiện
│
├── screens/                           # View Layer (V) - Màn hình chính
│   └── home_screen.dart              # Màn hình chính
│
├── widgets/                           # Reusable UI Components
│   ├── habit_card.dart               # Thẻ hiển thị thói quen
│   ├── view_mode_selector.dart       # Selector xem ngày/tuần/tháng
│   ├── habit_filter.dart             # Dialog lọc thói quen
│   └── index.dart                    # Barrel export
│
├── providers/                         # ViewModel Layer (VM)
│   ├── habit_provider.dart           # Logic quản lý thói quen
│   └── calendar_provider.dart        # Logic quản lý lịch
│
├── services/                          # Service Layer
│   ├── auth_service.dart             # Xác thực người dùng
│   ├── firestore_service.dart        # Firebase Firestore
│   ├── local_storage_service.dart    # Lưu trữ cục bộ
│   └── connectivity_service.dart     # Kiểm tra kết nối
│
└── utils/                             # Utility functions
    └── sample_habits.dart            # Dữ liệu mẫu
```

## 🏗️ Mô tả từng layer

### 1. **Models** (lib/models/)
- **habit_model.dart**: Đại diện cho một thói quen
  - Fields: id, title, detail, type (weekly/interval), weeklyDays, intervalDays, startDate, timesPerDay, lastCompleted, category, isDeleted
  - Methods: isDueOn() - kiểm tra thói quen có cần thực hiện vào ngày nào đó

- **habit_log_model.dart**: Ghi lại từng lần thực hiện
  - Fields: id, habitId, userId, date, isCompleted, count

### 2. **Screens** (lib/screens/)
- **home_screen.dart**: Màn hình chính
  - Hiển thị danh sách thói quen của ngày
  - Cho phép lọc theo loại (category)
  - Chọn chế độ xem (ngày/tuần/tháng)
  - Toggle trạng thái hoàn thành

### 3. **Widgets** (lib/widgets/)
Các UI component có thể tái sử dụng:

- **habit_card.dart**: Thẻ hiển thị thói quen
  - Checkbox trạng thái
  - Thời gian thực hiện
  - Tiêu đề (bold, 1 dòng, TextOverflow.ellipsis)
  - Chi tiết (3 dòng, TextOverflow.ellipsis)
  - Loại thói quen (Hàng tuần/Cách N ngày)

- **view_mode_selector.dart**: 3 nút chọn Ngày/Tuần/Tháng
  - Hiện tại chỉ thay đổi UI, không chuyển dữ liệu

- **habit_filter.dart**: Dialog lọc theo category
  - Checkbox "Tất cả"
  - Checkbox cho từng category
  - Nút "Áp dụng" và "Hủy"

### 4. **Providers** (lib/providers/)
Quản lý state và business logic:

- **habit_provider.dart** (extends ChangeNotifier):
  - `loadHabits()`: Tải danh sách từ local storage
  - `addHabit()`: Thêm thói quen mới
  - `updateHabit()`: Cập nhật thói quen
  - `deleteHabit()`: Xóa mềm (soft-delete)
  - `markCompleted()`: Đánh dấu hoàn thành
  - `getHabitsForDate()`: Lấy danh sách theo ngày
  - `filterHabits()`: Lọc theo category
  - `categories`: Lấy danh sách category

- **calendar_provider.dart**: Quản lý lịch (có thể mở rộng)

### 5. **Services** (lib/services/)
Lớp trừu tượng giao tiếp với các nguồn dữ liệu:

- **auth_service.dart**: Xác thực Firebase
- **firestore_service.dart**: Firestore CRUD
- **local_storage_service.dart**: SharedPreferences
- **connectivity_service.dart**: Kiểm tra mạng

### 6. **Utils** (lib/utils/)
- **sample_habits.dart**: Dữ liệu mẫu để test UI

## 🔄 Dependency Injection Pattern

```dart
// main.dart
MultiProvider(
  providers: [
    // Services
    Provider<AuthService>.value(value: authService),
    Provider<LocalStorageService>.value(value: localStorageService),
    Provider<FirestoreService>.value(value: firestoreService),
    Provider<ConnectivityService>.value(value: connectivityService),
    
    // ViewModels
    ChangeNotifierProvider<HabitProvider>(
      create: (_) => HabitProvider(localStorageService)..loadHabits(),
    ),
  ],
  child: const MyApp(),
)
```

## 📱 Cách sử dụng trong Widget

```dart
// Đọc dữ liệu
Consumer<HabitProvider>(
  builder: (context, habitProvider, _) {
    final habits = habitProvider.getHabitsForDate(DateTime.now());
    // ...
  },
)

// Cập nhật dữ liệu
context.read<HabitProvider>().markCompleted(habitId);
```

## 🎯 Các tính năng chính

✅ **Đã Implement**:
- ✅ Hiển thị danh sách thói quen trong ngày
- ✅ Thẻ thói quen với đầy đủ thông tin
- ✅ Toggle trạng thái hoàn thành
- ✅ Lọc thói quen theo category
- ✅ Selector chế độ xem (ngày/tuần/tháng)
- ✅ Kiến trúc MVVM rõ ràng

⏳ **Cần Mở rộng**:
- [ ] Thêm chức năng chuyển đổi xem tuần/tháng
- [ ] Tính toán thói quen cần làm cho tuần/tháng
- [ ] Màn hình tạo/sửa thói quen
- [ ] Lưu trạng thái hoàn thành vào database
- [ ] Hiển thị tiến độ/thống kê
- [ ] Dark mode
- [ ] Notification nhắc nhở

## 🚀 Cách chạy ứng dụng

```bash
# Cải tạo dự án
flutter pub get

# Chạy ứng dụng
flutter run

# Build APK (Android)
flutter build apk
```

---

**Ghi chú**: Ứng dụng sử dụng Provider pattern để quản lý state, cho phép UI tự động cập nhật khi dữ liệu thay đổi.
