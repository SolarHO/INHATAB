import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'create_account_widget.dart' show CreateAccountWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateAccountModel extends FlutterFlowModel<CreateAccountWidget> {
  ///  State fields for stateful widgets in this page.

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
  // State field(s) for passwordcheck widget.
  FocusNode? passwordcheckFocusNode;
  TextEditingController? passwordcheckController;
  late bool passwordcheckVisibility;
  String? Function(BuildContext, String?)? passwordcheckControllerValidator;
  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameController;
  String? Function(BuildContext, String?)? nameControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    passwordcheckVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    idFocusNode?.dispose();
    idController?.dispose();

    passwordFocusNode?.dispose();
    passwordController?.dispose();

    passwordcheckFocusNode?.dispose();
    passwordcheckController?.dispose();

    nameFocusNode?.dispose();
    nameController?.dispose();
  }
}
