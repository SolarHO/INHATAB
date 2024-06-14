import 'package:INHATAB/model/BoardModel.dart';
import 'package:INHATAB/model/PostModel.dart';
import 'package:INHATAB/model/chat_model.dart';
import 'package:INHATAB/model/commentModel.dart';
import 'package:INHATAB/model/userModel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  PostDetailPage({required this.postId});

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  SharedPreferences? prefs;
  bool _isAnonymous = true; //댓글 익명 여부
  bool _isReplyAnonymous = true; // 대댓글 익명 여부
  String? writerStatus;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    initPrefs();
    Provider.of<PostModel>(context, listen: false).clear();
    Provider.of<CommentModel>(context, listen: false).clear();
    Provider.of<PostModel>(context, listen: false).fetchPost(widget.postId).then((_) async {
      String? writerId = Provider.of<PostModel>(context, listen: false).writerId;
      if (writerId != null) {
        writerStatus = await Provider.of<PostModel>(context, listen: false).fetchWriterStatus(writerId); //작성자 상태가 탈퇴된 사용자인지 구분
        setState(() {}); // 상태 업데이트
      }
    });
    Provider.of<CommentModel>(context, listen: false).fetchComments(widget.postId);
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _showReplyDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReplyDialog(commentId: commentId,postId: widget.postId);
      },
    );
  }

  void _showChatConfirmationDialog(String postUserId) {  //채팅 다이얼로그
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('채팅하기'),
          content: Text('작성자와 채팅하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startChatWithUser(postUserId);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _startChatWithUser(String postUserId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedBoard = prefs.getString('selectedBoard');

      if (selectedBoard == null) {
        throw Exception('게시판 선택이 안되었습니다.');
      }

      final chatModel = Provider.of<ChatModel>(context, listen: false);
      await chatModel.startChatWithUser(postUserId, selectedBoard, widget.postId, context);
    } catch (error) {
      print('채팅방 생성 중 오류 발생: $error');
    }
  }
  void _showCommentChatDialog(String commentUserId, bool isAnonymous) {
    print("Comment User ID: $commentUserId, Is Anonymous: $isAnonymous"); // 디버깅 정보 추가
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('채팅하기'),
          content: Text('댓글 작성자와 채팅하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startChatWithCommentUser(commentUserId, isAnonymous);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }


  void _showReplyChatDialog(String replyUserId, bool isAnonymous) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('채팅하기'),
          content: Text('대댓글 작성자와 채팅하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startChatWithReplyUser(replyUserId, isAnonymous);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _startChatWithCommentUser(String commentUserId, bool isAnonymous) async {
    try {
      final chatModel = Provider.of<ChatModel>(context, listen: false);
      await chatModel.startChatFromComment(commentUserId, widget.postId, context, isAnonymous);
    } catch (error) {
      print('채팅방 생성 중 오류 발생: $error');
    }
  }

  Future<void> _startChatWithReplyUser(String replyUserId, bool isAnonymous) async {
    try {
      final chatModel = Provider.of<ChatModel>(context, listen: false);
      await chatModel.startChatFromComment(replyUserId, widget.postId, context, isAnonymous);
    } catch (error) {
      print('채팅방 생성 중 오류 발생: $error');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<BoardModel>(context).selectedBoard.toString()),
        actions: <Widget>[
          Visibility(
            visible: Provider.of<PostModel>(context).writerId != Provider.of<userModel>(context).getUid(),
              child: IconButton(
              icon: Icon(Icons.mail),
              onPressed: () {
                String? postUserId = Provider.of<PostModel>(context, listen: false).writerId;
                _showChatConfirmationDialog(postUserId!);
              },
            ),
          ),
          Visibility(
            visible: Provider.of<PostModel>(context).writerId == Provider.of<userModel>(context).getUid(),
              child: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text('게시글을 삭제하시겠습니까?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('확인'),
                          onPressed: () async {
                            await Provider.of<PostModel>(context, listen: false).deletePost(widget.postId);
                            Provider.of<BoardModel>(context, listen: false).deletePost(widget.postId);
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ]
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Consumer<PostModel>(
                builder: (context, postModel, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(postModel.title ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(postModel.writerName ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(postModel.timestamp ?? '', style: TextStyle(fontSize: 11)),
                      SizedBox(height: 16),
                      //이미지 영역
                      if (postModel.imageUrl != null)
                        Image.network(postModel.imageUrl!),
                      SizedBox(height: 16),
                      Text(postModel.content ?? '', style: TextStyle(fontSize: 18)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.thumb_up),
                            color: Provider.of<PostModel>(context).likebtnColor,
                            onPressed: () async {
                              await postModel.likePost();
                              Provider.of<BoardModel>(context, listen: false).updateLikeCount(postModel.PostId!, postModel.likeCount ?? 0);
                            },
                          ),
                          Text(
                            '${postModel.likeCount ?? 0}',
                            style: TextStyle(
                              color: Provider.of<PostModel>(context).likebtnColor,
                            ),
                          ),
                        ],
                      )
                    ],
                  );
                },
              ),
              Row(
                children: [
                  Text("익명"),
                  Checkbox(
                    value: _isAnonymous, //체크박스 초기 활성화 상태(true)
                    onChanged: (bool? value) {
                      setState(() {
                        _isAnonymous = value!; // 익명 여부 체크박스
                      });
                    },
                  ),
                  Expanded( //댓글 입력 폼
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: '댓글을 입력하세요.',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            String commentText = _commentController.text.trim();
                            if (commentText.isNotEmpty) {
                              Provider.of<CommentModel>(context, listen: false).addCommentToDb(_commentController.text, _isAnonymous);
                              Provider.of<BoardModel>(context, listen: false).incCommentCount(widget.postId);
                              _commentController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('댓글을 입력해주세요')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Consumer<CommentModel>(
                builder: (context, commentModel, child) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: commentModel.commentContents.length,
                    itemBuilder: (context, index) {
                      // 디버깅 로그 추가
                      print("댓글 인덱스: $index, 전체 댓글 수: ${commentModel.commentContents.length}");
                      print("익명 여부 인덱스: $index, 익명 여부 배열 크기: ${commentModel.isAnonymous.length}");
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Row(
                              children: [
                                Text(
                                  commentModel.userNames[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: commentModel.userIds[index] != 'unknown' ? FontWeight.bold : null,
                                    color: commentModel.userIds[index] == commentModel.postWriter ? Colors.green : null,
                                  ),
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  commentModel.timestamps[index], // 시간 포맷 변경
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ],
                            ),
                            subtitle: Text(commentModel.commentContents[index]),
                            trailing: Visibility(
                              visible: commentModel.userIds[index] != 'unknown',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton( //대댓글 추가
                                    icon: Icon(Icons.mode_comment_rounded),
                                    iconSize: 13.0,
                                    visualDensity: const VisualDensity(horizontal: -4),
                                    onPressed: () {
                                      _showReplyDialog(commentModel.commentIds[index]);
                                    },
                                  ),
                                  IconButton( //쪽지 보내기
                                    icon: Icon(Icons.mail),
                                    iconSize: 13.0,
                                    visualDensity: const VisualDensity(horizontal: -4),
                                    onPressed: () {
                                      if (index < commentModel.userIds.length && index < commentModel.isAnonymous.length) {
                                        print("Comment User ID: ${commentModel.userIds[index]}, Is Anonymous: ${commentModel.isAnonymous[index]}");
                                        _showCommentChatDialog(commentModel.userIds[index], commentModel.isAnonymous[index]);
                                      } else {
                                        print("Index out of range: $index");
                                      }


                                    },
                                  ),
                                  Visibility( //댓글 삭제
                                    visible: commentModel.userIds[index] == Provider.of<userModel>(context).getUid(),
                                    child: IconButton(
                                      icon: Icon(Icons.delete),
                                      iconSize: 13.0,
                                      visualDensity: const VisualDensity(horizontal: -4),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: Text('댓글을 삭제하시겠습니까?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('취소'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('확인'),
                                                  onPressed: () async {
                                                    await Provider.of<CommentModel>(context, listen: false).deleteComment(commentModel.commentIds[index]);
                                                    Provider.of<BoardModel>(context, listen: false).decCommentCount(widget.postId);
                                                    Provider.of<CommentModel>(context, listen: false).clear();
                                                    Provider.of<CommentModel>(context, listen: false).fetchComments(widget.postId);
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: commentModel.replies[index].length,
                            itemBuilder: (context, replyIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Text(
                                      commentModel.replies[index][replyIndex]['replyName']!, style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 15, color: commentModel.replies[index][replyIndex]['replyuid'] == commentModel.postWriter ? Colors.green : null,)),
                                      SizedBox(width: 4.0),
                                      Text(
                                        commentModel.replies[index][replyIndex]['timestamp']!, // 시간 포맷 변경
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(commentModel.replies[index][replyIndex]['replyContent']!),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton( //쪽지 보내기
                                        icon: Icon(Icons.mail),
                                        iconSize: 13.0,
                                        visualDensity: const VisualDensity(horizontal: -4),
                                        onPressed: () {
                                          if (index < commentModel.replies.length && replyIndex < commentModel.replies[index].length) {
                                            print("Reply User ID: ${commentModel.replies[index][replyIndex]['replyuid']}, Is Anonymous: ${commentModel.replies[index][replyIndex]['replyName'] == '익명'}");
                                            _showReplyChatDialog(commentModel.replies[index][replyIndex]['replyuid']!, commentModel.replies[index][replyIndex]['replyName'] == '익명');
                                          } else {
                                            print("Index out of range: $index, ReplyIndex: $replyIndex");
                                          }
                                        },
                                      ),
                                      Visibility(
                                        visible: commentModel.replies[index][replyIndex]['replyuid'] == Provider.of<userModel>(context).getUid(),
                                        child: IconButton( //대댓글 삭제
                                          icon: Icon(Icons.delete),
                                          iconSize: 13.0,
                                          visualDensity: const VisualDensity(horizontal: -4),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: Text('대댓글을 삭제하시겠습니까?'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text('취소'),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: Text('확인'),
                                                      onPressed: () async {
                                                        await Provider.of<CommentModel>(context, listen: false).deleteReplies(commentModel.commentIds[index], commentModel.replies[index][replyIndex]['replyId']!);
                                                        Provider.of<BoardModel>(context, listen: false).decCommentCount(widget.postId);
                                                        Provider.of<CommentModel>(context, listen: false).clear();
                                                        Provider.of<CommentModel>(context, listen: false).fetchComments(widget.postId);
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Divider(); // 댓글 사이에 divider 추가
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ReplyDialog extends StatefulWidget {
  final String commentId;
  final String postId;
  ReplyDialog({required this.commentId, required this.postId});

  @override
  _ReplyDialogState createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final _commentController = TextEditingController();
  bool _isReplyAnonymous = true; // 대댓글 익명 여부

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('대댓글 작성'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: '대댓글을 입력하세요.',
            ),
          ),
          Row(
            children: [
              Text("익명"),
              Checkbox(
                value: _isReplyAnonymous, // 체크박스 초기상태(true)
                onChanged: (bool? value) {
                  setState(() {
                    _isReplyAnonymous = value!; // 익명 여부 체크
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('확인'),
          onPressed: () {
            String replietext = _commentController.text.trim();
            if(replietext.isNotEmpty) {
              Provider.of<CommentModel>(context, listen: false).addReplyToDb(widget.commentId, replietext, _isReplyAnonymous);
              Provider.of<BoardModel>(context, listen: false).incCommentCount(widget.postId);
              Provider.of<CommentModel>(context, listen: false).clear();
              Provider.of<CommentModel>(context, listen: false).fetchComments(widget.postId);
              _commentController.clear();
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('대댓글을 입력해주세요')),
              );
            }
          },
        ),
      ],
    );
  }
}
