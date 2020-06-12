import 'package:flutter/material.dart';
import 'package:gramyshare/screens/post_page.dart';
import 'package:gramyshare/widget/custom_image.dart';
import '../screens/post_overview.dart';

class PostTile extends StatelessWidget {
  final PostScreen post;
  PostTile(this.post);

showPost(context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => PostOverview(
          postId: post.postId,
          userId: post.ownerId,
        )));
  }

   
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}