import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/widget/appBar_haeder.dart';
import 'package:gramyshare/widget/comment_item.dart';
import 'package:gramyshare/widget/loading.dart';

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postMediaUrl,
    this.postOwnerId,
  });

  @override
  _CommentsState createState() => _CommentsState(
        postId: this.postId,
        postOwnerId: this.postMediaUrl,
        postMediaUrl: this.postOwnerId,
      );
}

class _CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  _CommentsState({
    this.postId,
    this.postMediaUrl,
    this.postOwnerId,
  });

  commentsContainer() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          List<CommentItem> comments = [];
          snapshot.data.documents.forEach((doc){
            comments.add(CommentItem.fromDoc(doc));
          });
          return ListView(
            children: comments,
          );
        },
    );
  }

  addComment() {
    commentsRef.document(postId).collection('comments').add({
      'username': currentUser.displayName,
      'comment': commentController.text,
      'timestamp': timestamp,
      'avatarUrl': currentUser.photoUrl,
      'userId': currentUser.id,
    });
    bool isNotOwner = postOwnerId != currentUser.id;
    // if(isNotOwner){
    activityRef
          .document(postOwnerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'comment',
        'commentData': commentController.text,
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': postMediaUrl,
        'timestamp': timestamp,
      });

    // }
    commentController.clear();
  }

  // removeLikeFromActivity() {
  //   bool isNotOwner = currentUserId != ownerId;
  //   if (isNotOwner) {
  //     activityRef
  //         .document(ownerId)
  //         .collection('feedItems')
  //         .document(postId)
  //         .get()
  //         .then((doc) {
  //       if (doc.exists) {
  //         doc.reference.delete();
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarHeader(title: 'Commnets'),
      body: Column(
        children: <Widget>[
          Expanded(
            child: commentsContainer(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                  // prefixIcon: Icon(
                  //   Icons.edit,
                  //   color: Colors.orange[800],
                  // ),
                  border: InputBorder.none,
                  labelText: 'Write a commnet...',
                  labelStyle: TextStyle(color: Colors.orange[800], fontSize: 14),
                  errorBorder: InputBorder.none),
            ),
            trailing: OutlineButton(
              
              color: Colors.lightBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textColor: Colors.lightBlue,
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text('Post', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
