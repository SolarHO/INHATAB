import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.
  final _auth = FirebaseAuth.instance;
  final _prefs = SharedPreferences.getInstance();
  final unfocusNode = FocusNode();
  // State field(s) for ID widget.
  FocusNode? idFocusNode;
  TextEditingController? idController;
  String? Function(BuildContext, String?)? idControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    idFocusNode?.dispose();
    idController?.dispose();

    passwordFocusNode?.dispose();
    passwordController?.dispose();
  }
  Future<void> login(BuildContext context) async {
    try {
      final id = idController?.text.trim() ?? '';
      final password = passwordController?.text ?? '';

      if (id.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID와 비밀번호를 입력하세요.')),
        );
        return;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: id,
        password: password,
      );

      if (userCredential.user != null) {
        // 인증 성공, SharedPreferences에 사용자 정보 저장
        final prefs = await _prefs;
        await prefs.setString('userId', id);

        // TestPage로 이동
        context.go('/TestPage');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증에 실패했습니다. 다시 시도하세요.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Firebase 인증 예외 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}')),
      );
      print('Firebase Auth error: ${e.message}');
    } catch (e) {
      // 기타 예외 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다. 다시 시도하세요.')),
      );
      print('Login error: $e');
    }
  }
}
