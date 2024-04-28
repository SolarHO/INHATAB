import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode(); //화면의 다른 부분을 탭할 때 포커스를 해제
  // State field(s) for ID widget.
  FocusNode? idFocusNode; //ID입력필드의 포커스를 관리하기 위한 FocusNode
  TextEditingController? idController; //ID입력필드를 제어하기 위한 controller
  String? Function(BuildContext, String?)? idControllerValidator; //ID필드의 유효성 검사
  // State field(s) for password widget.
  FocusNode? passwordFocusNode; //PW입력필드의 포커스를 관리하기 위한 FocusNode
  TextEditingController? passwordController; //PW입력필드를 제어하기 위한 controller
  late bool passwordVisibility; //PW입력 필드의 가시성 상태를 나타내는변수
  String? Function(BuildContext, String?)? passwordControllerValidator; //PW입력필드으 유효성 검사 함수

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
}
