# TH5 — Habit Tracker (Flutter + Firebase)

Ứng dụng theo dõi thói quen hàng ngày theo **tuần** hoặc **cách ngày**, xây dựng theo kiến trúc **MVVM** (Model–View–ViewModel) với **Provider** làm state management.

---

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                    ← Entry point, khởi tạo Firebase & MultiProvider
├── firebase_options.dart        ← Cấu hình Firebase (API keys)
│
├── models/                      ← Lớp dữ liệu (Data Layer)
│   ├── habit_model.dart         ← Cấu hình thói quen (lưu local)
│   └── habit_log_model.dart     ← Kết quả thực hiện (lưu Firebase)
│
├── services/                    ← Lớp xử lý dữ liệu ngoại vi (Service Layer)
│   ├── auth_service.dart        ← Xác thực Firebase Auth
│   ├── local_storage_service.dart ← SharedPreferences (offline)
│   ├── firestore_service.dart   ← Cloud Firestore (online)
│   └── connectivity_service.dart ← Kiểm tra trạng thái mạng
│
└── providers/                   ← Lớp logic & quản lý trạng thái (ViewModel)
    ├── habit_provider.dart      ← CRUD thói quen + lọc + tìm kiếm
    └── calendar_provider.dart   ← Logic lịch Ngày/Tuần/Tháng + đánh dấu hoàn thành
```

---

## 📦 Models — Mô tả chi tiết

### `habit_model.dart` — Cấu hình thói quen

Lưu **cấu hình** thói quen vào **SharedPreferences** (local).

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | `String` | ID duy nhất (UUID) |
| `title` | `String` | Tên thói quen (VD: "Uống nước") |
| `detail` | `String` | Mô tả chi tiết |
| `type` | `HabitType` | `weekly` (theo tuần) hoặc `interval` (cách ngày) |
| `weeklyDays` | `List<int>?` | Ngày trong tuần: `[1,3,5]` = Thứ 2, 4, 6 |
| `intervalDays` | `int?` | Số ngày cách quãng (VD: 2 = cách 1 ngày) |
| `startDate` | `DateTime` | Ngày bắt đầu tính chu kỳ |
| `timesPerDay` | `int` | Số lần thực hiện/ngày (VD: uống nước 8 lần) |
| `lastCompleted` | `DateTime?` | Lần gần nhất hoàn thành (local, không cần Firebase) |
| `category` | `String` | Nhãn phân loại: "Sức khỏe", "Học tập",... |
| `isDeleted` | `bool` | Soft-delete: `true` = ẩn khỏi UI nhưng giữ dữ liệu lịch sử |

**Phương thức quan trọng:**
- `toJson()` / `fromJson()` — Chuyển đổi JSON cho SharedPreferences
- `isDueOn(DateTime date)` — Kiểm tra thói quen có cần thực hiện vào ngày `date` không (timezone-safe)

### `habit_log_model.dart` — Kết quả thực hiện

Lưu **trạng thái hoàn thành** lên **Firestore** (cloud).

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | `String?` | ID document trên Firestore |
| `habitId` | `String` | Liên kết với `Habit.id` |
| `userId` | `String` | Lấy từ `AuthService.currentUserId` |
| `date` | `String` | Ngày thực hiện, định dạng `YYYY-MM-DD` |
| `isCompleted` | `bool` | `true` khi đạt đủ `timesPerDay` |
| `count` | `int` | Số lần đã bấm hoàn thành (VD: 2/3) |

**Phương thức:**
- `toFirestore()` / `fromFirestore()` — Cho Firestore
- `toJson()` / `fromJson()` — Cho offline pending queue

---

## 🔧 Services — Mô tả chi tiết

### `auth_service.dart` — Xác thực người dùng

| Phương thức | Mô tả |
|-------------|-------|
| `currentUserId` | Lấy `uid` hiện tại (dùng để lưu log lên Firestore) |
| `authStateChanges` | Stream theo dõi đăng nhập/đăng xuất |
| `signInAnonymously()` | Đăng nhập ẩn danh |
| `signInWithEmail(email, password)` | Đăng nhập email |
| `registerWithEmail(email, password)` | Đăng ký tài khoản |
| `signOut()` | Đăng xuất |

### `local_storage_service.dart` — Lưu trữ offline

| Phương thức | Mô tả |
|-------------|-------|
| `saveHabits(List<Habit>)` | Lưu toàn bộ danh sách thói quen |
| `getHabits()` | Đọc danh sách thói quen |
| `updateLastCompleted(id, date)` | Cập nhật riêng `lastCompleted` cho 1 habit |
| `savePendingLogs(List<HabitLog>)` | Lưu logs chờ đồng bộ khi mất mạng |
| `getPendingLogs()` | Đọc pending logs |
| `clearPendingLogs()` | Xóa pending logs sau khi sync thành công |

### `firestore_service.dart` — Cloud Firestore

| Phương thức | Mô tả |
|-------------|-------|
| `syncLog(HabitLog)` | Đẩy/cập nhật 1 log (composite key: `userId_habitId_date`) |
| `syncPendingLogs(List<HabitLog>)` | Batch write nhiều logs cùng lúc (offline → online) |
| `getLogsForDate(userId, date)` | Query logs cho 1 ngày |
| `getLogsByDateRange(userId, start, end)` | Query logs theo khoảng ngày bất kỳ |
| `getLogsForWeek(userId, startOfWeek)` | Query logs cho 1 tuần |
| `getLogsForMonth(userId, month)` | Query logs cho 1 tháng |

### `connectivity_service.dart` — Kiểm tra mạng

| Phương thức | Mô tả |
|-------------|-------|
| `connectionStream` | `Stream<bool>` theo dõi mạng real-time |
| `checkConnection()` | Kiểm tra kết nối hiện tại (trả về `bool`) |

---

## 🧠 Providers — Mô tả chi tiết

### `habit_provider.dart` — Quản lý danh sách thói quen

**Nhận:** `LocalStorageService` qua constructor (DI).

| API | Mô tả |
|-----|-------|
| `activeHabits` | Danh sách thói quen chưa bị xóa |
| `isLoading` | Trạng thái đang tải |
| `loadHabits()` | Tải từ SharedPreferences |
| `addHabit(Habit)` | Thêm thói quen mới |
| `updateHabit(Habit)` | Cập nhật thói quen |
| `deleteHabit(id)` | Xóa mềm (`isDeleted = true`) |
| `markCompleted(id)` | Cập nhật `lastCompleted = now()` |
| `getHabitsForDate(date)` | Lấy thói quen cần làm hôm nay |
| `filterHabits(category)` | Lọc theo nhãn phân loại |
| `getHabitById(id)` | Lấy 1 habit (dùng cho form Sửa) |
| `categories` | Danh sách nhãn duy nhất |

### `calendar_provider.dart` — Logic lịch & hoàn thành

**Nhận:** `FirestoreService` + `LocalStorageService` qua constructor (DI).

| API | Mô tả |
|-----|-------|
| `selectedDate` | Ngày đang được chọn |
| `currentView` | Chế độ xem: `day`, `week`, `month` |
| `habitsForToday` | Thói quen cần làm trong ngày được chọn |
| `completionCount` | `Map<habitId, count>` — số lần đã làm |
| `periodLogs` | Danh sách logs cho chế độ xem tuần/tháng |
| `selectDate(date, allHabits, userId)` | Chọn ngày → load habits + completion |
| `changeView(view, allHabits, userId)` | Đổi chế độ xem Ngày/Tuần/Tháng |
| `fetchLogsForView(baseDate, userId)` | Tải logs khi chuyển tuần/tháng |
| `toggleCompletion(habitId, userId, date, timesPerDay)` | Bấm hoàn thành (tăng count, offline fallback) |

---

## 🔄 Luồng hoạt động chính

### 1. Khởi động ứng dụng

```
main.dart
  │
  ├─ Firebase.initializeApp()        ← Kết nối Firebase
  ├─ Khởi tạo Services (4 instance)
  └─ MultiProvider
       ├─ Provider<AuthService>
       ├─ Provider<ConnectivityService>
       ├─ Provider<LocalStorageService>
       ├─ Provider<FirestoreService>
       ├─ ChangeNotifierProvider<HabitProvider>  ← ..loadHabits() tự động
       └─ ChangeNotifierProvider<CalendarProvider>
```

### 2. Người dùng tạo thói quen mới

```
UI (Form) ──> HabitProvider.addHabit(habit)
                  │
                  ├─ Thêm vào _activeHabits (RAM)
                  ├─ LocalStorageService.saveHabits() (SharedPreferences)
                  └─ notifyListeners() → UI rebuild
```

### 3. Người dùng xem ngày cụ thể

```
UI (Lịch) ──> CalendarProvider.selectDate(date, allHabits, userId)
                  │
                  ├─ Lọc habits cần làm hôm nay (isDueOn)
                  ├─ FirestoreService.getLogsForDate() → completionCount
                  └─ notifyListeners() → UI hiển thị danh sách + trạng thái
```

### 4. Người dùng bấm "Hoàn thành"

```
UI (Checkbox) ──> CalendarProvider.toggleCompletion(habitId, userId, date, timesPerDay)
                      │
                      ├─ Tăng count (0 → 1 → 2 → ... → timesPerDay → reset 0)
                      ├─ isCompleted = (count >= timesPerDay)
                      ├─ notifyListeners() → UI cập nhật ngay
                      │
                      ├─ [Có mạng] → FirestoreService.syncLog()
                      └─ [Mất mạng] → LocalStorageService.savePendingLogs()
```

### 5. Chuyển chế độ xem Tuần / Tháng

```
UI (Tab) ──> CalendarProvider.changeView(CalendarView.month, ...)
                 │
                 └─ FirestoreService.getLogsForMonth(userId, date)
                        │
                        └─ periodLogs → UI hiển thị lưới tháng
```

### 6. Khi có mạng lại (Offline Sync)

```
ConnectivityService.connectionStream ──> [isConnected = true]
    │
    ├─ LocalStorageService.getPendingLogs()
    ├─ FirestoreService.syncPendingLogs(pendingLogs)  ← Batch write
    └─ LocalStorageService.clearPendingLogs()
```

---

## 🎨 Hướng dẫn sử dụng trong giao diện (Views)

### Truy cập Provider trong Widget

```dart
// Đọc danh sách thói quen (tự rebuild khi thay đổi)
final habits = context.watch<HabitProvider>().activeHabits;

// Gọi hành động (không rebuild)
context.read<HabitProvider>().addHabit(newHabit);

// Lấy userId
final userId = context.read<AuthService>().currentUserId;
```

### Ví dụ: Màn hình danh sách thói quen

```dart
class HabitListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    if (habitProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: habitProvider.activeHabits.length,
      itemBuilder: (context, index) {
        final habit = habitProvider.activeHabits[index];
        return ListTile(
          title: Text(habit.title),
          subtitle: Text('${habit.category} • ${habit.timesPerDay} lần/ngày'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => habitProvider.deleteHabit(habit.id),
          ),
        );
      },
    );
  }
}
```

### Ví dụ: Lọc thói quen theo category

```dart
// Lấy danh sách category cho DropdownButton
final categories = context.watch<HabitProvider>().categories;

// Lọc
final filtered = context.read<HabitProvider>().filterHabits('Sức khỏe');
```

### Ví dụ: Hiển thị thói quen hôm nay + trạng thái hoàn thành

```dart
class TodayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final userId = context.read<AuthService>().currentUserId;

    return ListView.builder(
      itemCount: calendarProvider.habitsForToday.length,
      itemBuilder: (context, index) {
        final habit = calendarProvider.habitsForToday[index];
        final count = calendarProvider.completionCount[habit.id] ?? 0;

        return ListTile(
          title: Text(habit.title),
          subtitle: Text('$count / ${habit.timesPerDay} lần'),
          trailing: Checkbox(
            value: count >= habit.timesPerDay,
            onChanged: (_) {
              calendarProvider.toggleCompletion(
                habit.id, userId!, calendarProvider.selectedDate, habit.timesPerDay,
              );
            },
          ),
        );
      },
    );
  }
}
```

### Ví dụ: Chuyển chế độ xem Ngày → Tuần → Tháng

```dart
// Chuyển sang xem Tháng
final allHabits = context.read<HabitProvider>().activeHabits;
final userId = context.read<AuthService>().currentUserId;

context.read<CalendarProvider>().changeView(
  CalendarView.month, allHabits, userId,
);

// Khi người dùng chuyển sang tháng khác
context.read<CalendarProvider>().fetchLogsForView(
  DateTime(2026, 4, 1), userId!,
);
```

### Ví dụ: Form Thêm/Sửa thói quen

```dart
// Thêm mới
final newHabit = Habit(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Tập thể dục',
  detail: '30 phút mỗi ngày',
  type: HabitType.interval,
  intervalDays: 2,
  startDate: DateTime.now(),
  timesPerDay: 1,
  category: 'Sức khỏe',
);
context.read<HabitProvider>().addHabit(newHabit);

// Sửa: lấy dữ liệu cũ đổ vào form
final existing = context.read<HabitProvider>().getHabitById('habit_id_123');
if (existing != null) {
  // Đổ vào TextEditingController...
  titleController.text = existing.title;
}
```

### Ví dụ: Kiểm tra mạng trước khi tải dữ liệu quá khứ

```dart
final connectivity = context.read<ConnectivityService>();
final isOnline = await connectivity.checkConnection();

if (!isOnline) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Không có kết nối mạng. Dữ liệu quá khứ chưa thể tải.')),
  );
}
```

---

## 🛠 Dependencies

| Package | Mục đích |
|---------|----------|
| `firebase_core` | Khởi tạo Firebase |
| `firebase_auth` | Xác thực người dùng |
| `cloud_firestore` | Lưu trữ cloud |
| `shared_preferences` | Lưu trữ local |
| `provider` | State management (MVVM) |
| `connectivity_plus` | Kiểm tra mạng |

---

## ▶️ Chạy dự án

```bash
# Cài dependencies
flutter pub get

# Chạy trên Chrome
flutter run -d chrome

# Chạy trên Android
flutter run -d android

# Kiểm tra lỗi
flutter analyze
```
