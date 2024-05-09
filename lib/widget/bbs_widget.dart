import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:flutter/material.dart';
import '../model/bbs_model.dart';
export '../model/bbs_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';
class BbsWidget extends StatefulWidget {
  const BbsWidget({Key? key}) : super(key: key);

  @override
  State<BbsWidget> createState() => _BbsWidgetState();
}

class _BbsWidgetState extends State<BbsWidget> {
  late BbsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> _postTitles = ['자유게시판','홍보게시판','장터게시판','동아리게시판']; //게시판 종류입니다. 해당 값을 세션으로 가져가서 글작성,글보여주기 등을 수행합니다.
                                                        //그래서 게시판 추가할거면 여기다가 쉼표하고 하나 넣어주시면 됩니덩 게시판종류변경됨
  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
      _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0x4C181BF8),
          automaticallyImplyLeading: false,
          title: Text(
            '게시판',
            style: FlutterFlowTheme
                .of(context)
                .headlineMedium
                .override(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 0,
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FlutterFlowTheme
                            .of(context)
                            .alternate,
                        FlutterFlowTheme
                            .of(context)
                            .secondaryText
                      ],
                      stops: [0, 1],
                      begin: AlignmentDirectional(0.87, -1),
                      end: AlignmentDirectional(-0.87, 1),
                    ),
                  ),
                  alignment: AlignmentDirectional(0, -1),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _postTitles.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () async {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('selectedBoard', _postTitles[index]);
                                  GoRouter.of(context).go('/Boardload');
                                },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                margin: EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _postTitles[index],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}