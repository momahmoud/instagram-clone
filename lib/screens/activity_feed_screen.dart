import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramyshare/widget/activity_feed_item.dart';
import '../widget/appBar_haeder.dart';
import '../screens/home.dart';
import '../widget/loading.dart';
class ActivityFeedScreen extends StatefulWidget {
  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  getActivity() async {
    QuerySnapshot snapshot = await activityRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
        List<ActivityFeedItem> feedItems = [];
        snapshot.documents.forEach((doc) {
          feedItems.add(ActivityFeedItem.fromDoc(doc));
         });

    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarHeader(title: 'Activity Feed'),
      body: Container(
        child: FutureBuilder(
          future: getActivity(),
          builder: (context, snapshot){
            if(!snapshot.hasData){
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}
