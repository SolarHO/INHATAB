import 'package:INHATAB/model/BoardModel.dart';
import 'package:INHATAB/model/PostModel.dart';
import 'package:INHATAB/model/commentModel.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    initPrefs();
    Provider.of<PostModel>(context, listen: false).clear();
    Provider.of<CommentModel>(context, listen: false).clear();
    Provider.of<PostModel>(context, listen: false).fetchPost(widget.postId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<BoardModel>(context).selectedBoard.toString()),
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
                            Provider.of<CommentModel>(context, listen: false).addCommentToDb(_commentController.text, _isAnonymous);
                            Provider.of<BoardModel>(context, listen: false).incCommentCount(widget.postId);
                            _commentController.clear();
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Row(
                              children: [
                                Text(
                                  commentModel.userNames[index],
                                  style: TextStyle(
                                    fontWeight: commentModel.userIds[index] != 'unknown' ? FontWeight.bold : null,
                                    color: commentModel.userIds[index] == commentModel.postWriter ? Colors.green : null,
                                  ),
                                ),
                                SizedBox(width: 8.0),
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
                                    onPressed: () {
                                      _showReplyDialog(commentModel.commentIds[index]);
                                    },
                                  ),
                                  IconButton( //쪽지 보내기
                                    icon: Icon(Icons.send),
                                    iconSize: 13.0,
                                    onPressed: () {
                                      
                                    },
                                  ),
                                  Visibility( //댓글 삭제
                                    visible: commentModel.userIds[index] == prefs?.getString('userId'),
                                    child: IconButton(
                                      icon: Icon(Icons.delete),
                                      iconSize: 13.0,
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
                                      Text(commentModel.replies[index][replyIndex]['replyName']!, style: TextStyle(fontWeight: FontWeight.bold,
                                      color: commentModel.replies[index][replyIndex]['replyuid'] == commentModel.postWriter ? Colors.green : null,)),
                                      SizedBox(width: 8.0),
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
                                        icon: Icon(Icons.send),
                                        iconSize: 13.0,
                                        onPressed: () {
                                          
                                        },
                                      ),
                                      Visibility(
                                        visible: commentModel.replies[index][replyIndex]['replyuid'] == prefs?.getString('userId'),
                                        child: IconButton( //대댓글 삭제
                                          icon: Icon(Icons.delete),
                                          iconSize: 13.0,
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
            Provider.of<CommentModel>(context, listen: false).addReplyToDb(widget.commentId, _commentController.text, _isReplyAnonymous);
            Provider.of<BoardModel>(context, listen: false).incCommentCount(widget.postId);
            Provider.of<CommentModel>(context, listen: false).clear();
            Provider.of<CommentModel>(context, listen: false).fetchComments(widget.postId);
            _commentController.clear();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
