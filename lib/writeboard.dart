import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage 패키지 추가
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Image Picker 패키지 추가
import 'dart:io';

import 'model/BoardModel.dart';

class WriteBoardPage extends StatefulWidget {
  const WriteBoardPage({Key? key}) : super(key: key);

  @override
  _WriteBoardPageState createState() => _WriteBoardPageState();
}

class _WriteBoardPageState extends State<WriteBoardPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _imageUrl;
  String? _fileName; // 파일 이름을 저장할 변수 추가
  int? likecount;
  bool isAnonymous = false;
  String? _selectedImageFilePath; // 선택된 이미지의 파일 경로

  String generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  //이미지 선택 함수
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // 갤러리에서 이미지 선택

    if (pickedFile != null) {
      setState(() {
        _selectedImageFilePath = pickedFile.path; // 파일 경로 저장
        _fileName = pickedFile.path.split('/').last; // 파일 이름 저장
      });
    }
  }

  // 이미지 선택 및 업로드 함수
  Future<String?> _uploadImage(String filePath) async {
    // 이미지 파일이 선택된 경우에만 실행
    final String postId = generateRandomId();
    final String fileName = 'images/$postId.jpg'; // Firebase Storage에 저장될 파일 경로

    final Reference storageRef =
        FirebaseStorage.instance.ref().child(fileName); // 저장소 참조 생성
    final UploadTask uploadTask = storageRef.putFile(File(filePath)); // 파일 업로드

    // 파일 업로드가 완료되면 다운로드 URL을 반환
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl; // 다운로드 URL 반환
  }

  Future<void> _savePost() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      DatabaseReference userRef =
          FirebaseDatabase.instance.reference().child('users');
      DatabaseEvent event = await userRef.child(user!.uid).once();
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? userData =
          snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        String userName = userData['name'];

        DateTime now = DateTime.now();
        String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? selectedBoard = prefs.getString('selectedBoard');
        if (selectedBoard == null) {
          throw Exception('게시판을 선택하지 않았습니다.');
        }
        if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
          );
          return;
        }

        if (_selectedImageFilePath != null) {
          _imageUrl = await _uploadImage(_selectedImageFilePath!);
          if (_imageUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
            );
            return;
          }
        }

        DatabaseReference postRef = FirebaseDatabase.instance
            .reference()
            .child('boardinfo')
            .child('boardstat')
            .child(selectedBoard)
            .push();
        String postId = postRef.key!;

        await postRef.set({
          'postId': postId,
          'title': _titleController.text,
          'uid': user.uid,
          'name': userName,
          'timestamp': timestamp,
          'anony': isAnonymous,
        });

        DatabaseReference contentRef = postRef.child('contents');
        await contentRef.set({
          'title': _titleController.text,
          'content': _contentController.text,
          'timestamp': timestamp,
          'imageUrl': _imageUrl, // 이미지 URL 저장
        });

        // 게시글 저장 후에 결과를 반환하고 이전 페이지로 이동
        Provider.of<BoardModel>(context, listen: false).clear();
        Provider.of<BoardModel>(context, listen: false).fetchPosts();
        Navigator.pop(context, 'refresh');
      } else {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e) {
      print('게시글 저장 오류: $e');
      Navigator.pop(context, 'refresh');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("익명"),
                Checkbox(
                  value: isAnonymous, // 체크박스의 상태를 isAnonymous 변수와 동기화
                  onChanged: (bool? value) {
                    setState(() {
                      isAnonymous = value!; // 체크박스가 변경될 때 isAnonymous 변수 업데이트
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '제목',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용',
              ),
              maxLines: null,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _selectImage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_upload),
                  SizedBox(width: 8.0),
                  Text('이미지 업로드'),
                ],
              ),
            ),
            SizedBox(height: 8.0),
            if (_fileName != null) // 파일 이름이 있을 경우에만 표시
              Text(
                '선택된 이미지: $_fileName',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _savePost,
              child: Text('게시글 저장'),
            ),
          ],
        ),
      ),
    );
  }
}
