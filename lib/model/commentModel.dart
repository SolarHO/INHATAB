import 'package:INHATAB/model/PostModel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentModel with ChangeNotifier {
  String? postId; // 게시글 ID
  String? postWriter; //게시글 작성자Id
  List<String> commentIds = []; // 댓글 ID
  List<String> userIds = []; //댓글 작성자 ID
  List<String> userNames = []; //댓글 작성자 이름
  List<String> commentContents = []; // 댓글 내용
  List<String> timestamps = []; // 댓글 작성 시간
  List<List<Map<String, String>>> replies = []; // 대댓글
  Map<String, int> anonymousCounts = {}; //사용자의 익명 댓글 수를 저장하는 맵
  List<bool> isAnonymous = []; // 익명 여부 저장
  int globalAnonymousCount = 1; // 전역 익명 카운트
  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    // 'MM-dd HH:mm' 형식으로 날짜와 시간을 포맷
    return DateFormat('MM/dd HH:mm').format(dateTime);
  }


  // 작성자에게 댓글이 달렸다고 알림
  Future<void> _sendNotification(String fromUserId, String toUserId, String message, String timestamp) async {
    DatabaseReference notificationRef = FirebaseDatabase.instance.reference().child('alerts').child(toUserId).push();
    await notificationRef.set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'timestamp': timestamp,
    });
  }


  Future<void> _createNotification(String userId, bool isReply) async {
    if (postWriter != null && postWriter != userId) {
      String? selectedBoard = (await SharedPreferences.getInstance()).getString('selectedBoard');
      if (selectedBoard == null) return;

      DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard).child(postId!);
      DataSnapshot postSnapshot = (await postRef.once()).snapshot;
      if (postSnapshot.value == null) return;

      Map<dynamic, dynamic> postData = postSnapshot.value as Map<dynamic, dynamic>;
      String title = postData['title'] ?? '제목 없음';

      String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      String notificationMessage = isReply
          ? "'$title' 게시글에 댓글이 달렸습니다."
          : "'$title' 게시글에 댓글이 달렸습니다.";
      await _sendNotification(userId, postWriter!, notificationMessage, formattedTimestamp);
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

  Future<String?> _fetchReplyUserName(String userId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
    DataSnapshot snapshot = await userRef.once().then((event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      return userData['name'];
    }
    return null;
  }

  // 댓글을 불러오는 메서드
  Future<void> fetchComments(String postIds) async {
    try {
      postId = postIds;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedBoard = prefs.getString('selectedBoard');
      if (selectedBoard == '인기게시글') {
        selectedBoard = await getActualBoard(postId!);
      }
      DatabaseReference contentsRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId!);
      DatabaseReference commentsRef = contentsRef.child('contents').child('comment');

      // 게시글 작성자 ID를 불러오는 코드 추가
      DataSnapshot writerSnapshot = (await contentsRef.child('uid').once()).snapshot;
      postWriter = writerSnapshot.value as String?;

      DataSnapshot commentsSnapshot = (await commentsRef.once()).snapshot;

      anonymousCounts.clear(); // 댓글 불러올 때 익명 카운트 초기화
      globalAnonymousCount = 1; // 전역 익명 카운트 초기화

      if (commentsSnapshot.value != null) {
        Map<dynamic, dynamic>? comments = commentsSnapshot.value as Map<dynamic, dynamic>?;

        if (comments != null) {
          var sortedComments = comments.entries.toList()
            ..sort((a, b) => DateTime.parse(a.value['timestamp']).compareTo(DateTime.parse(b.value['timestamp'])));

          for (var entry in sortedComments) {
            String? commentContent = entry.value['comment'];
            String? commentId = entry.key;
            String? userId = entry.value['userId'];
            String? userName = entry.value['userName'];
            bool isAnonymous = entry.value['anony']; // 익명 여부를 가져옴
            String? timestamp = entry.value['timestamp'];
            List<Map<String, String>> replyList = [];

            // 댓글 작성자의 이름을 업데이트된 이름으로 불러오기
            if (!isAnonymous) {
              userName = await _fetchUserName(userId!) ?? userName;
            }

            // 대댓글 노드가 있는지 확인
            if (entry.value['replies'] != null) {
              DataSnapshot repliesSnapshot = (await commentsRef.child(commentId!).child('replies').once()).snapshot;

              if (repliesSnapshot.value != null) {
                Map<dynamic, dynamic>? repliesData = repliesSnapshot.value as Map<dynamic, dynamic>?;
                for (var replyEntry in repliesData!.entries) {
                  String replyId = replyEntry.key;
                  String replyUserId = replyEntry.value['userId'];
                  String replyUserName = replyEntry.value['userName'];
                  bool isReplyAnonymous = replyEntry.value['anony'];

                  if (!isReplyAnonymous) {
                    replyUserName = await _fetchUserName(replyUserId) ?? replyUserName;
                  }

                  replyList.add({
                    'replyId': replyId,
                    'replyContent': replyEntry.value['comment'],
                    'timestamp': formatTimestamp(replyEntry.value['timestamp']),
                    'replyuid': replyUserId,
                    'replyName': isReplyAnonymous ? getAnonymousName(replyUserId) : replyUserName,
                  });
                }
              }
              addComment(commentId!, commentContent!, userId!, timestamp!, userName!, isAnonymous, replyList);
            } else {
              addComment(commentId!, commentContent!, userId!, timestamp!, userName!, isAnonymous, replyList);
            }
          }
        }
      }
    } catch (error) {
      print("댓글 정보를 가져오는 데 실패했습니다: $error");
    }
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

  //익명 닉네임을 가져오는 메서드
  String getAnonymousName(String userId) {
    if (userId == postWriter) { // 게시글 작성자가 댓글을 작성한 경우
      return '익명(작성자)';
    } else {
      if (!anonymousCounts.containsKey(userId)) {
        anonymousCounts[userId] = globalAnonymousCount++;
      }
      return '익명${anonymousCounts[userId]}';
    }
  }

  //댓글 작성 메서드
  Future<void> addCommentToDb(String commentContent, bool isAnonymous) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == '인기게시글') {
      selectedBoard = await getActualBoard(postId!);
    }
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');
    if (postId != null) {
      DatabaseReference commentRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId!);
      String commentId = commentRef.child('contents').child('comment').push().key!;
      await commentRef.child('commentcount').set(ServerValue.increment(1));
      await commentRef.child('contents').child('comment').child(commentId).set({
        'comment': commentContent,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'userName': userName, // DB에는 원래 작성자의 이름 저장
        'anony': isAnonymous, // 익명 체크박스의 상태 저장
      });
      addComment(commentId, commentContent, userId!, DateTime.now().toIso8601String(), userName!, isAnonymous, []);
      if (postWriter != null && postWriter != userId) {


        // 알림 생성
        await _createNotification(userId!, false);

      }
    }

  }

  //대댓글 작성 메서드
  Future<void> addReplyToDb(String commentId, String replyContent, bool isReplyAnonymous) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == '인기게시글') {
      selectedBoard = await getActualBoard(postId!);
    }
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');
    DatabaseReference replyRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId!);
    String replyId = replyRef.child('contents').child('comment').child(commentId).child('replies').push().key!;
    await replyRef.child('commentcount').set(ServerValue.increment(1));
    await replyRef.child('contents').child('comment').child(commentId).child('replies').child(replyId).set({
      'comment': replyContent,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'userName': userName, // DB에는 원래 작성자의 이름 저장
      'anony': isReplyAnonymous, // 익명 체크박스의 상태 저장
    });

    // 알림 생성
    await _createNotification(userId!, false);

  }

  // 댓글을 추가하는 메서드
  void addComment(String commentId, String commentContent, String userId, String timestamp, String userName, bool isAnonymous, List<Map<String, String>> replyList) {
    if(isAnonymous == true) {
      userNames.add(getAnonymousName(userId));
    } else {
      userNames.add(userName);
    }
    userIds.add(userId);
    commentIds.add(commentId);
    commentContents.add(commentContent);
    timestamps.add(formatTimestamp(timestamp));
    replies.add(replyList);
    this.isAnonymous.add(isAnonymous); // 익명 여부 저장
    notifyListeners();
  }

  Future<void> deleteComment(String commentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == '인기게시글') {
      selectedBoard = await getActualBoard(postId!);
    }
    DatabaseReference Ref = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId!);
    DataSnapshot repliesSnapshot = (await Ref.child('contents').child('comment').child(commentId).child('replies').once()).snapshot;

    if (repliesSnapshot.value != null) {
      // 대댓글이 있는 경우, 댓글의 이름과 내용을 "삭제"로 변경
      await Ref.child('contents').child('comment').child(commentId).update({
        'anony': false,
        'userName': '(삭제)',
        'comment': '삭제된 댓글입니다.',
        'userId': 'unknown'
      });
    } else {
      // 대댓글이 없는 경우, 댓글을 데이터베이스에서 삭제
      await Ref.child('contents').child('comment').child(commentId).remove();
    }
    await Ref.child('commentcount').set(ServerValue.increment(-1));
    notifyListeners();
  }

  Future<void> deleteReplies(String commentId, String replyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == '인기게시글') {
      selectedBoard = await getActualBoard(postId!);
    }
    DatabaseReference Ref = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat').child(selectedBoard!).child(postId!);
    DatabaseReference replyRef = Ref.child('contents').child('comment').child(commentId).child('replies').child(replyId);

    // 대댓글 삭제
    await replyRef.remove();

    // 댓글의 대댓글과 userId를 확인
    DataSnapshot commentSnapshot = (await Ref.child('contents').child('comment').child(commentId).once()).snapshot;
    Map<dynamic, dynamic>? commentData = commentSnapshot.value as Map<dynamic, dynamic>?;
    String? userId = commentData?['userId'];
    Map<dynamic, dynamic>? replies = commentData?['replies'] as Map<dynamic, dynamic>?;

    if (userId == 'unknown' && (replies == null || replies.isEmpty)) {
      // userId가 'unknown'이고 대댓글이 없는 경우, 댓글을 데이터베이스에서 삭제
      await Ref.child('contents').child('comment').child(commentId).remove();
    }
    await Ref.child('commentcount').set(ServerValue.increment(-1));
    notifyListeners();
  }

  // 모델을 초기화하는 메서드
  void clear() {
    postId = null;
    commentIds.clear();
    userNames.clear();
    userIds.clear();
    commentContents.clear();
    timestamps.clear();
    replies.clear();
    anonymousCounts.clear();
    notifyListeners();
  }
}
