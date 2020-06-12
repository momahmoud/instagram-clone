import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
class CommentItem extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  CommentItem({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp
  });

  factory CommentItem.fromDoc(DocumentSnapshot doc){
    return CommentItem(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      avatarUrl: doc['avatarUrl'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(

          title: Text(comment,),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(height: 2,)
      ],
    );
  }
}