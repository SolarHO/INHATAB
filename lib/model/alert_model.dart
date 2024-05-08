import 'package:flutterflow_ui/flutterflow_ui.dart';
import '../widget/alert_widget.dart' show AlertWidget;
import 'package:flutter/material.dart';

class AlertModel extends FlutterFlowModel<AlertWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
