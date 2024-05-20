import 'dart:js_util';
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

  List<String> _mechanic = ['기계공학과','기계설계공학과','메카트로닉스공학과','반도체기계정비학과','조선기계공학과','항공기계공학과','자동차공학과'];
  List<String> _itFusion = ['전기공학과','전자공학과','정보통신공학과','컴퓨터정보공학과','컴퓨터시스템공학과','디지털마케팅공학과'];
  List<String> _newMaterial = ['건설환경공학과','공간정보빅데이터학과','화학생명공학과','재료공학과'];
  List<String> _ArchitecturaDesign = ['건축학과','실내건축학과','산업디자인학과','패션디자인학과'];
  List<String> _service = ['항공운항과','항공경영학과','관광경영학과','경영비서학과','호텔경영학과','물류시스템학과','스포츠헬스케어학과'];
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
            style: FlutterFlowTheme.of(context).headlineMedium.override(
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
          child: ListView(
            children: [
              ..._postTitles.map((title) {
                return InkWell(
                  onTap: () async {
                    SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                    await prefs.setString('selectedBoard', title);
                    GoRouter.of(context).go('/Boardload');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 13),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
              ExpansionTile(
                title: Text('기계공학부'),
                children: _mechanic.map((String value) {
                  return Column(
                    children: [
                      Divider(), 
                      ListTile(
                        title: Text(value),
                        onTap: () {
                          setState(() async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          await prefs.setString('selectedBoard', value);
                          GoRouter.of(context).go('/Boardload');
                        });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
              ExpansionTile(
                title: Text('IT융합공학부'),
                children: _itFusion.map((String value) {
                  return Column(
                    children: [
                      Divider(), 
                      ListTile(
                        title: Text(value),
                        onTap: () {
                          setState(() async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          await prefs.setString('selectedBoard', value);
                          GoRouter.of(context).go('/Boardload');
                        });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
              ExpansionTile(
                title: Text('지구환경신소재공학부'),
                children: _newMaterial.map((String value) {
                  return Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Text(value),
                        onTap: () {
                          setState(() async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          await prefs.setString('selectedBoard', value);
                          GoRouter.of(context).go('/Boardload');
                        });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
              ExpansionTile(
                title: Text('건축디자인학부'),
                children: _ArchitecturaDesign.map((String value) {
                  return Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Text(value),
                        onTap: () {
                          setState(() async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          await prefs.setString('selectedBoard', value);
                          GoRouter.of(context).go('/Boardload');
                        });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
              ExpansionTile(
                title: Text('서비스경영학부'),
                children: _service.map((String value) {
                  return Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Text(value),
                        onTap: () {
                          setState(() async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          await prefs.setString('selectedBoard', value);
                          GoRouter.of(context).go('/Boardload');
                        });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}