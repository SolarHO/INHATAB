import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/profile_model.dart';


class MyProfileWidget extends StatefulWidget {
  const MyProfileWidget({Key? key}) : super(key: key);

  @override
  _MyProfileWidgetState createState() => _MyProfileWidgetState();
}

class _MyProfileWidgetState extends State<MyProfileWidget> {
  late ProfileModel _model;

  @override
  void initState() {
    super.initState();
    _model = ProfileModel();
    _model.initState(context); // 모델의 초기화 메서드 호출
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    String currentPassword = '';
    String newName = _model.userName;
    String newPassword = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('회원 정보 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '현재 비밀번호'),
                onChanged: (value) {
                  currentPassword = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                bool verified = await _model.verifyCurrentPassword(currentPassword);
                if (verified) {
                  Navigator.of(context).pop();
                  _showNewProfileDialog(newName, newPassword);
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('현재 비밀번호가 올바르지 않습니다.')),
                  );
                }
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showNewProfileDialog(String newName, String newPassword) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('새로운 정보 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: '새 이름'),
                onChanged: (value) {
                  newName = value;
                },
                controller: TextEditingController(text: newName),
              ),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '새 비밀번호'),
                onChanged: (value) {
                  newPassword = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _model.updateUserProfile(newName, newPassword, context);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('회원 정보가 수정되었습니다.')),
                );
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    String currentPassword = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('회원탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '현재 비밀번호'),
                onChanged: (value) {
                  currentPassword = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                bool verified = await _model.verifyCurrentPassword(currentPassword);
                if (verified) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  await _model.deleteAccount(context); // 회원탈퇴
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('현재 비밀번호가 올바르지 않습니다.')),
                  );
                }
              },
              child: Text('탈퇴', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileModel>.value(
      value: _model,
      child: Consumer<ProfileModel>(
        builder: (context, model, child) {
          return GestureDetector(
            onTap: () => model.unfocusNode.canRequestFocus
                ? FocusScope.of(context).requestFocus(model.unfocusNode)
                : FocusScope.of(context).unfocus(),
            child: Scaffold(
              appBar: AppBar(
                title: Text('내 프로필'),
                backgroundColor: Color(0x4C181BF8),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (model.profileImageUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(model.profileImageUrl),
                      ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '이메일: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.email,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '이름: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.userName,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showEditProfileDialog,
                      child: Text('정보수정'),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => model.logout(context),
                      child: Text('로그아웃'),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _confirmDeleteAccount(context),
                      child: Text(
                        '회원탈퇴',
                        style: TextStyle(color: Colors.red), // 글씨색만 빨간색으로 설정
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}