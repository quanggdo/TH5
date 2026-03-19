import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy userId hiện tại, trả về null nếu chưa đăng nhập
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập ẩn danh
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Đăng nhập bằng email & password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Đăng ký bằng email & password
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Email của user hiện tại (nếu có)
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Thay đổi mật khẩu: cần xác thực lại bằng mật khẩu hiện tại
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Không có tài khoản đang đăng nhập');
    }

    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    // Reauthenticate
    await user.reauthenticateWithCredential(cred);
    // Update password
    await user.updatePassword(newPassword);
  }
}
