import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoardModel with ChangeNotifier {
  String? selectedBoard = ''; //현재 선택한 게시판
  List<String> saveBoard = []; //글을 작성한 게시판
  List<String> postTitles = []; //게시글 제목
  List<String> postIds = []; //게시글 ID
  List<String> name = []; //작성자 이름
  List<int> likeCounts = []; //좋아요 수
  List<int> commentCounts = []; //댓글 수
  List<String> timestamps = []; //글 작성 시간
  String? lastKey; //마지막으로 불러온 글 키 값
  int limit = 20; //한번에 불러오는 글 제한
  FocusNode unfocusNode = FocusNode(); // unfocusNode 추가
  String? searchQuery; // 검색어

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    // 'yy-MM-dd HH:mm' 형식으로 날짜와 시간을 포맷
    return DateFormat('yy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> fetchPosts({String? query}) async { //게시글 목록 불러오기
  SharedPreferences prefs = await SharedPreferences.getInstance();
  selectedBoard = prefs.getString('selectedBoard');
  if (selectedBoard == null) {
    throw Exception('게시판을 선택하지 않았습니다.');
  }
  searchQuery = query; // 검색어  저장
  try {
    DatabaseReference postRef = FirebaseDatabase.instance.reference().child('boardinfo').child('boardstat');
    DatabaseReference popularPostRef = postRef.child('인기게시글');
    Query dbQuery;

    if (selectedBoard == '인기게시글') {
      dbQuery = popularPostRef.orderByKey();
    } else {
      dbQuery = postRef.child(selectedBoard!).orderByKey();
    }

    // _lastKey가 있으면 _lastKey 이전의 게시글을 불러옴
    if (lastKey != null) {
      dbQuery = dbQuery.endBefore(lastKey);
    }

    // 가장 최근의 _limit개의 게시글을 불러옴
    dbQuery = dbQuery.limitToLast(limit);

    DatabaseEvent event = await dbQuery.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<dynamic, dynamic>? posts = snapshot.value as Map<dynamic, dynamic>?;

      if (posts != null) {
        var reversedPosts = posts.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        // _lastKey 업데이트
        String newLastKey = reversedPosts.last.key;

        // 처음 작성된 게시글을 불러왔으면 새로고침 중단
        if (lastKey == newLastKey) {
          return;
        }

        lastKey = newLastKey;

        // 검색어가 있는 경우, 해당하는 게시글만 필터링
        if (searchQuery != null && searchQuery!.isNotEmpty) {
          reversedPosts = reversedPosts.where((entry) {
            String title = entry.value['title']?.toString() ?? '';
            return title.contains(searchQuery!);
          }).toList();
        }
        
        if(selectedBoard == '인기게시글') {
          for (var entry in reversedPosts) {
            String postId = entry.key;
            String boardName = entry.value['selectedBoard']?.toString() ?? '';
            DatabaseReference boardPostRef = postRef.child(boardName).child(postId);

            DatabaseEvent boardPostEvent = await boardPostRef.once();
            DataSnapshot boardPostSnapshot = boardPostEvent.snapshot;

            if (boardPostSnapshot.value != null) {
              Map<dynamic, dynamic>? postInfo = boardPostSnapshot.value as Map<dynamic, dynamic>?;

              if (postInfo != null) {
                String title = postInfo['title']?.toString() ?? '제목 없음';
                String? username;
                if (postInfo['anony'] == true) {
                  username = "익명";
                } else {
                  String userId = postInfo['uid']?.toString() ?? '';
                  if (userId.isNotEmpty) {
                    username = await _fetchUserName(userId) ?? "탈퇴된 사용자";
                  } else {
                    username = "알 수 없음";
                  }
                }
                String timestamp = postInfo['timestamp']?.toString() ?? DateTime.now().toIso8601String();
                int likeCount = postInfo['likecount'] ?? 0;
                int commentCount = postInfo['commentcount'] ?? 0;

                if (title != null && postId != null && username != null) {
                  addPost(title, boardName ,postId, username, likeCount, commentCount, timestamp);
                }
              }
            }
          }
        } else {
          for (var entry in reversedPosts) {
            String title = entry.value['title']?.toString() ?? '제목 없음';
            String postId = entry.key;
            String? username;
            if (entry.value['anony'] == true) {
              username = "익명";
            } else {
              String userId = entry.value['uid']?.toString() ?? '';
              if (userId.isNotEmpty) {
                username = await _fetchUserName(userId) ?? "탈퇴된 사용자";
              } else {
                username = "알 수 없음";
              }
            }
            String timestamp = entry.value['timestamp']?.toString() ?? DateTime.now().toIso8601String();
            int likeCount = entry.value['likecount'] ?? 0;
            int commentCount = entry.value['commentcount'] ?? 0;

            if (title != null && postId != null && username != null) {
              addPost(title, selectedBoard!, postId, username, likeCount, commentCount, timestamp);
            }
          }
        }
      }
    }
    print(saveBoard);
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

  void addPost(String title, String boardName,String id, String username, int likeCount, int commentCount, String timestamp) { //게시글 추가
    postTitles.add(title);
    saveBoard.add(boardName);
    postIds.add(id);
    name.add(username);
    likeCounts.add(likeCount);
    commentCounts.add(commentCount);
    timestamps.add(formatTimestamp(timestamp));
    notifyListeners();
  }

  void deletePost(String postId) {
    int index = postIds.indexOf(postId);
    if(index != -1) {
      postTitles.removeAt(index);
      saveBoard.remove(index);
      postIds.removeAt(index);
      name.removeAt(index);
      likeCounts.removeAt(index);
      commentCounts.removeAt(index);
      timestamps.removeAt(index);
    }
    notifyListeners();
  }

  void setLastKey(String key) {
    lastKey = key;
    notifyListeners();
  }

  void updateLikeCount(String postId, int newLikeCount) {
    int index = postIds.indexOf(postId);
    if (index != -1) {
      likeCounts[index] = newLikeCount;
      notifyListeners();
    }
  }

  void incCommentCount(String postId) { //댓글 수 증가
    int index = postIds.indexOf(postId);
    if (index != -1) {
      commentCounts[index] ++;
      notifyListeners();
    }
  }

  void decCommentCount(String postId) { //댓글 수 감소
    int index = postIds.indexOf(postId);
    if (index != -1) {
      commentCounts[index] --;
      notifyListeners();
    }
  }


  void clearSearch() {
    searchQuery = null;
    clear();
    fetchPosts(); // 검색어를 초기화한 후 게시글 다시 불러오기
  }

  void clear() {
    selectedBoard = null;
    postTitles.clear();
    saveBoard.clear();
    postIds.clear();
    name.clear();
    likeCounts.clear();
    commentCounts.clear();
    timestamps.clear();
    lastKey = null;
    notifyListeners();
  }
}
