import 'package:flutter/material.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/screens/post_page.dart';
import 'package:gramyshare/widget/appBar_haeder.dart';
import 'package:gramyshare/widget/loading.dart';

class PostOverview extends StatelessWidget {
  final String userId;
  final String postId;

  PostOverview({
    this.postId,
    this.userId
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.document(userId).collection('userPosts').document(postId).get(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        PostScreen post =  PostScreen.fromDoc(snapshot.data);
        return 
         Scaffold(
            appBar: appBarHeader(title: post.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                ),
              ],
            ),
          
        );
      },
    );
  }
}