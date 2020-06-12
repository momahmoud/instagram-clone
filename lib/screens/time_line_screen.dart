import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/screens/post_page.dart';
import 'package:gramyshare/screens/search_screen.dart';
import 'package:gramyshare/widget/appBar_haeder.dart';
import 'package:gramyshare/widget/loading.dart';

class TimeLineScreen extends StatefulWidget {
  final User currentUser;

  TimeLineScreen({this.currentUser});

  @override
  _TimeLineScreenState createState() => _TimeLineScreenState();
}

class _TimeLineScreenState extends State<TimeLineScreen> {
  List<PostScreen> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<PostScreen> posts =
        snapshot.documents.map((doc) => PostScreen.fromDoc(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  timeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return usersToFollow();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  usersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach(
          (doc) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = currentUser.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            if (isAuthUser) {
              return;
            } else if (isFollowingUser) {
              return;
            } else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          },
        );
        return Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Colors.pink[700],
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Users to Follow',
                      style: TextStyle(
                        color: Colors.pink[700],
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: userResults,
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarHeader(
        isTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: timeline(),
      ),
    );
  }
}
