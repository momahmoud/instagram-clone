import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/comments.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/widget/activity_feed_item.dart';
import 'package:gramyshare/widget/custom_image.dart';
import 'package:gramyshare/widget/loading.dart';

class PostScreen extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  PostScreen({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory PostScreen.fromDoc(DocumentSnapshot doc) {
    return PostScreen(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikesCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((value) {
      if (value == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostScreenState createState() => _PostScreenState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikesCount(this.likes),
      );
}

class _PostScreenState extends State<PostScreen> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  bool showHeart = false;
  bool isLiked;
  bool isPostOwner;
  int likeCount;
  Map likes;

  _PostScreenState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });
  postHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.amber,
          ),
          title: GestureDetector(
              onTap: () => showProfile(context, profileId: user.id),
              child: Text(
                user.displayName,
                style: TextStyle(
                    color: Colors.deepPurpleAccent[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              )),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => deletePostDialog(context),
                )
              : Text(''),
        );
      },
    );
  }

  deletePostDialog(BuildContext pcontext) {
    return showDialog(
      context: pcontext,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          elevation: 3,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Delete this Post?',
            style: TextStyle(
              color: Colors.teal,
              fontSize: 15,
            ),
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                removePost();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.pink[700],
                ),
              ),
            ),
            Divider(
              height: 0,
              endIndent: 30,
              indent: 25,
              thickness: .5,
              color: Colors.teal,
            ),
            SimpleDialogOption(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.pink[700],
                ),
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  removePost() async {
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    storageRef.child('post_$postId.jpg').delete();

    QuerySnapshot feedSnapshot = await activityRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();
    feedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    QuerySnapshot commentSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  postImage() {
    return GestureDetector(
      onDoubleTap: handleLikesPost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 14,
                child: Container(
                  child: cachedNetworkImage(mediaUrl),
                ),
              ),
            ),
          ),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 500),
                  tween: Tween(begin: .0, end: 1.9),
                  curve: Curves.decelerate,
                  cycles: 5,
                  builder: (context, anim, _) => Transform.scale(
                    scale: anim.value,
                    transformHitTests: true,
                    child: Icon(
                      Icons.favorite,
                      size: anim.value + 70,
                      color: Colors.pink[700],
                    ),
                  ),
                )
              : Text(''),
        ],
      ),
    );
  }

  postFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40, left: 15),
            ),
            GestureDetector(
              onTap: handleLikesPost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink[700],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.lightBlue,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$likeCount likes',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$username  ',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(description),
            )
          ],
        )
      ],
    );
  }

  handleLikesPost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivity();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToAcivity();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 400), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromActivity() {
    bool isNotOwner = currentUserId != ownerId;
    // if (isNotOwner) {
      activityRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    // }
  }

  addLikeToAcivity() {
    bool isNotOwner = currentUserId != ownerId;
    // if (isNotOwner) {
      activityRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    // }
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        postHeader(),
        postImage(),
        postFooter(),
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Comments(
                postId: postId,
                postOwnerId: ownerId,
                postMediaUrl: mediaUrl,
              )));
}
