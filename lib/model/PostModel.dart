import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostModel with ChangeNotifier {
  String? PostId; // 게시글 ID
  String? title; // 게시글 제목
  String? content; // 게시글 내용
  String? writerId; //작성자 Id
  String? writerName; //작성자 이름
  int? likeCount; // 좋아요 수
  String? imageUrl; //이미지 url
  String? timestamp; // 게시글 작성 시간
  Color? likebtnColor;

  String? getWriterId() {
    return writerId;
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    // 'yyyy-MM-dd HH:mm' 형식으로 날짜와 시간을 포맷
    return DateFormat('yy-MM-dd HH:mm').format(dateTime);
  }

  // 게시글 정보를 불러오는 메서드
  Future<void> fetchPost(String postId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedBoard = prefs.getString('selectedBoard');
      String? userId = prefs.getString('userId');
      DatabaseReference userRef =
      FirebaseDatabase.instance.reference().child('users').child(userId!);
      DatabaseEvent event = await userRef.child('like').child(postId!).once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value == null) {
        likebtnColor = Colors.grey;
      } else {
        likebtnColor = Colors.blue;
      }

      // '인기게시글'일 경우, 해당 게시글의 실제 게시판을 찾습니다.
      DatabaseReference postRef;
      if (selectedBoard == '인기게시글') {
        String? actualBoard =
        await getActualBoard(postId); // '인기게시글'의 실제 게시판을 찾는 함수
        postRef = FirebaseDatabase.instance
            .reference()
            .child('boardinfo')
            .child('boardstat')
            .child(actualBoard!)
            .child(postId);
      } else {
        postRef = FirebaseDatabase.instance
            .reference()
            .child('boardinfo')
            .child('boardstat')
            .child(selectedBoard!)
            .child(postId);
      }

      snapshot = (await postRef.once()).snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? post = snapshot.value as Map<dynamic, dynamic>?;

        if (post != null) {
          PostId = postId;
          title = post['title'];
          writerId = post['uid'];
          if (post['anony'] == true) {
            writerName = "익명";
          } else {
            writerName = await _fetchUserName(writerId!); // 작성자 이름을 업데이트된 이름으로 불러오기
          }
          content = post['contents']['content'];
          likeCount = post['likecount'];
          imageUrl = post['contents']['imageUrl'];
          print(imageUrl);
          timestamp = formatTimestamp(post['timestamp']);
          notifyListeners();
        }
      }
    } catch (error) {
      print("게시글 정보를 가져오는 데 실패했습니다: $error");
    }
  }
  Future<String?> _fetchUserName(String userId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    DataSnapshot snapshot = await userRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      return userData['name'];
    }
    return null;
  }

  Future<String?> getActualBoard(String postId) async {
    // '인기게시글'의 postId 게시글 데이터에서 'selectedBoard' 값을 찾습니다.
    DatabaseReference popularPostRef = FirebaseDatabase.instance
        .reference()
        .child('boardinfo')
        .child('boardstat')
        .child('인기게시글')
        .child(postId);
    DataSnapshot snapshot = (await popularPostRef.once()).snapshot;

    // 'selectedBoard' 값을 반환합니다.
    if (snapshot.value != null) {
      Map<dynamic, dynamic>? post = snapshot.value as Map<dynamic, dynamic>?;
      if (post != null && post.containsKey('selectedBoard')) {
        return post['selectedBoard'];
      }
    }

    // 'selectedBoard' 값을 찾지 못했다면, null을 반환합니다.
    return null;
  }

  Future<void> likePost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? selectedBoard = prefs.getString('selectedBoard');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    try {
      DatabaseReference userRef =
      FirebaseDatabase.instance.reference().child('users').child(userId);
      DatabaseReference postRef = FirebaseDatabase.instance
          .reference()
          .child('boardinfo')
          .child('boardstat');
      DatabaseEvent event = await userRef.child('like').child(PostId!).once();
      DataSnapshot snapshot = event.snapshot;

      // '인기게시글'일 경우, 해당 게시글의 실제 게시판을 찾습니다.
      if (selectedBoard == '인기게시글') {
        selectedBoard = await getActualBoard(PostId!);
      }

      if (snapshot.value == null) {
        //아직 좋아요를 누르지 않은 글
        likeCount = (likeCount ?? 0) + 1;
        await postRef
            .child(selectedBoard!)
            .child(PostId!)
            .child('likecount')
            .set(ServerValue.increment(1));
        await userRef.child('like').child(PostId!).set(true);
        likebtnColor = Colors.blue;
        if (likeCount! >= 10) {
          //좋아요 수가 10을 넘으면 인기게시글에 등록됨
          await postRef
              .child('인기게시글')
              .child(PostId!)
              .child('selectedBoard')
              .set(selectedBoard);
        }
      } else {
        //좋아요를 누른 글(좋아요 취소)
        likeCount = (likeCount ?? 0) - 1;
        await postRef
            .child(selectedBoard!)
            .child(PostId!)
            .child('likecount')
            .set(ServerValue.increment(-1));
        await userRef.child('like').child(PostId!).remove();
        likebtnColor = Colors.grey;
        if (likeCount! < 10) {
          //좋아요 수가 10보다 낮아지면 인기게시글에서 제외됨
          await postRef.child('인기게시글').child(PostId!).remove();
        }
      }
      notifyListeners();
    } catch (error) {
      print("좋아요를 추가/취소하는 데 실패했습니다: $error");
      throw error;
    }
  }

  //게시글 삭제 메서드
  Future<void> deletePost(String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');

    // '인기게시글'일 경우, 해당 게시글의 실제 게시판을 찾습니다.
    if (selectedBoard == '인기게시글') {
      selectedBoard = await getActualBoard(postId);
    }

    DatabaseReference Ref = FirebaseDatabase.instance
        .reference()
        .child('boardinfo')
        .child('boardstat')
        .child(selectedBoard!)
        .child(postId!);

    await Ref.remove();
    notifyListeners();
  }

  Future<String> fetchWriterStatus(String writerId) async {
    //사용자의 상태확인 (삭제된사용자일경우....)
    DatabaseReference userRef =
    FirebaseDatabase.instance.reference().child('users').child(writerId);
    DataSnapshot snapshot =
    await userRef.once().then((event) => event.snapshot);

    if (snapshot.value == null) {
      return 'deleted';
    }

    Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
    return userData['status'] ?? 'active';
  }

  // 모델을 초기화하는 메서드
  void clear() {
    PostId = null;
    title = null;
    content = null;
    likeCount = null;
    timestamp = null;
    likebtnColor = null;
    notifyListeners();
  }
}