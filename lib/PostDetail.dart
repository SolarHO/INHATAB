import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';


class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late DatabaseReference postRef;
  bool liked = false;
  int likeCount = 0;
  List<Comment> comments = [];
  TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      String? selectedBoard = prefs.getString('selectedBoard');
      if (selectedBoard == null) {
        throw Exception('게시판을 선택하지 않았습니다.');
      }
      postRef = FirebaseDatabase.instance
          .reference()
          .child('boardinfo')
          .child('boardstat')
          .child(selectedBoard)
          .child(widget.postId)
          .child('contents');

      _fetchLikeCount();
      _fetchComments();
    });
  }

  Future<void> _fetchLikeCount() async { // 좋아요 수 표시
    try {
      DatabaseEvent event = await postRef.once();
      DataSnapshot snapshot = event.snapshot;

      Map? postData = snapshot.value as Map?;
      setState(() {
        likeCount = postData?['likecount'] ?? 0;
      });
    } catch (error) {
      print("좋아요 수를 가져오는 도중 오류 발생: $error");
    }
  }

  Future<Map<String, dynamic>> _fetchPostDetails() async {   //게시글내용 가져오기
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedBoard = prefs.getString('selectedBoard');
    if (selectedBoard == null) {
      throw Exception('게시판을 선택하지 않았습니다.');
    }
    try {
      DatabaseEvent event = await postRef.once();
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? postData = snapshot.value as Map<dynamic, dynamic>?;

      if (postData != null) {
        return {
          'title': postData['title'],
          'content': postData['content'],
          'timestamp': postData['timestamp'],
          'imageUrl': postData['imageUrl'],
        };
      } else {
        throw Exception('게시글 데이터가 없습니다.');
      }
    } catch (error) {
      print("게시글 상세 정보를 가져오는 데 실패했습니다: $error");
      throw error;
    }
  }

  Future<void> _likePost() async {    // 좋아요! 메소드
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    try {
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userId);
      DatabaseEvent event = await userRef.child('like').child(widget.postId).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) {
        await postRef.child('likecount').set(ServerValue.increment(1));
        await userRef.child('like').child(widget.postId).set(true);
        await _fetchLikeCount();
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('이미 좋아요를 눌렀습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print("좋아요를 추가하는 데 실패했습니다: $error");
      throw error;
    }
  }

  Future<void> _fetchComments() async {   // 댓글 표시 메서드
    try {
      DatabaseReference commentRef = postRef.child('comment');
      DatabaseEvent event = await commentRef.once();
      DataSnapshot commentSnapshot = event.snapshot;
      Map<dynamic, dynamic>? commentData = commentSnapshot.value as Map<dynamic, dynamic>?;

      if (commentData != null) {
        List<Comment> fetchedComments = [];
        commentData.forEach((commentId, commentValue) {
          if (commentValue is Map<dynamic, dynamic>) {
            Comment comment = Comment.fromMap(commentId, commentValue);
            comment.replies = [];
            if (commentValue['replies'] != null) {
              Map<dynamic, dynamic> replies = commentValue['replies'];
              replies.forEach((replyId, replyValue) {
                if (replyValue is Map<dynamic, dynamic>) {
                  Comment reply = Comment.fromMap(replyId, replyValue);
                  comment.replies.add(reply);
                }
              });
              // 대댓글도 시간순으로 정렬
              comment.replies.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            }
            fetchedComments.add(comment);
          }
        });
        // 댓글을 시간순으로 정렬
        fetchedComments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() {
          comments = fetchedComments;
        });
      }
    } catch (error) {
      print("댓글을 가져오는 데 실패했습니다: $error");
    }
  }

  Future<void> _addComment(String comment, {String? parentId}) async {  //댓글추가 메서드
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }

    try {
      DatabaseReference commentRef;
      if (parentId != null) {
        commentRef = postRef.child('comment').child(parentId).child('replies').push();
      } else {
        commentRef = postRef.child('comment').push();
      }
      DatabaseReference userRef = postRef.child('users').child(userId);

      DataSnapshot userSnapshot = await userRef.once().then((snapshot) => snapshot.snapshot);
      int userAnonymity;
      if (userSnapshot.value == null) {
        DataSnapshot userCountSnapshot = await postRef.child('users').once().then((snapshot) => snapshot.snapshot);
        int userCount = 0;
        if (userCountSnapshot.value != null) {
          userCount = (userCountSnapshot.value as Map<dynamic, dynamic>).length;
        }
        userAnonymity = userCount + 1;
        await userRef.set({'anonymity': userAnonymity});
      } else {
        userAnonymity = (userSnapshot.value as Map<dynamic, dynamic>)['anonymity'];
      }

      String anonymousName = '익명$userAnonymity';

      await commentRef.set({
        'comment': comment,
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'userName': anonymousName,
        'userId': userId,
      });

      await _fetchComments();
    } catch (error) {
      print("댓글을 추가하는 데 실패했습니다: $error");
      throw error;
    }
  }

  void _showReplyDialog(String parentId) {    // 대댓글 작성 다이얼로그
    TextEditingController _replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('대댓글 작성'),
          content: TextField(
            controller: _replyController,
            decoration: InputDecoration(hintText: '대댓글을 입력하세요...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (_replyController.text.isNotEmpty) {
                  _addComment(_replyController.text, parentId: parentId);
                  Navigator.pop(context);
                }
              },
              child: Text('작성'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 상세 정보'),
      ),
        body: FutureBuilder(
          future: _fetchPostDetails(),
          builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('게시글을 불러오는 동안 오류가 발생했습니다.'));
            } else if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.data!['title'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '작성 시간: ${snapshot.data!['timestamp']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (snapshot.data!['imageUrl'] != null)
                        Image.network(
                          snapshot.data!['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      SizedBox(height: 16),
                      Text(
                        snapshot.data!['content'],
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '좋아요 수: $likeCount',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: 8),
                          if (!liked)
                            ElevatedButton(
                              onPressed: _likePost,
                              child: Text('좋아요'),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildCommentSection(),
                    ],
                  ),
                ),
              );
            } else {
              return Center(child: Text('게시글을 찾을 수 없습니다.'));
            }
          },
        ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildCommentForm(),
        _buildCommentList(),
      ],
    );
  }

  Widget _buildCommentForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: '댓글을 입력하세요...',
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {
            if (_commentController.text.isNotEmpty) {
              _addComment(_commentController.text);
              _commentController.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCommentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(comment.userName),
              subtitle: Text(comment.comment),
              trailing: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(comment.timestamp),
                ),
              ),
              onTap: () {
                _showReplyDialog(comment.id);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: comment.replies.length,
                itemBuilder: (context, replyIndex) {
                  final reply = comment.replies[replyIndex];
                  return ListTile(
                    title: Text(reply.userName),
                    subtitle: Text(reply.comment),
                    trailing: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(reply.timestamp),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class Comment {
  final String id;
  final String comment;
  final int timestamp;
  final String userName;
  final String userId;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.comment,
    required this.timestamp,
    required this.userName,
    required this.userId,
    this.replies = const [],
  });

  factory Comment.fromMap(String id, Map<dynamic, dynamic> data) {
    return Comment(
      id: id,
      comment: data['comment'],
      timestamp: DateTime.parse(data['timestamp']).millisecondsSinceEpoch,
      userName: data['userName'],
      userId: data['userId'],
      replies: [],
    );
  }
}