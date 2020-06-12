import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/edit_profile.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/screens/post_page.dart';
import 'package:gramyshare/widget/appBar_haeder.dart';
import 'package:gramyshare/widget/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gramyshare/widget/post_tile.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;
  ProfileScreen({
    this.profileId,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String currentUserId = currentUser?.id;
  String postOreinted = 'grid';
  bool isLoading = false;
  bool isFollowing = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<PostScreen> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => PostScreen.fromDoc(doc)).toList();
    });
  }

  Column countColumn(String title, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  profileEditingButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return editingButton(
        text: 'Edit Profile',
        function: editProfile,
      );
    } else if (isFollowing) {
      return editingButton(text: 'Unfollow', function: unfollowUser);
    } else if (!isFollowing) {
      return editingButton(text: 'Follow', function: followUser);
    }
  }

  unfollowUser() {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    activityRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  followUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});
    activityRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  Container editingButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width / 1.7,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isFollowing ? Colors.white : Colors.lightBlue,
              border:
                  Border.all(color: isFollowing ? Colors.grey : Colors.blue),
              borderRadius: BorderRadius.circular(5)),
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.grey : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  profileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                    backgroundColor: Colors.grey,
                  ),
                  Expanded(
                      flex: 1,
                      child: Column(children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            countColumn('posts', postCount),
                            countColumn('followers', followersCount),
                            countColumn('following', followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            profileEditingButton(),
                          ],
                        ),
                      ]))
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username != null ? user.username : " ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  user.displayName != null ? user.displayName : "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  user.bio,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Container splashScreen() {
    final height = MediaQuery.of(context).size.height;
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      // color: Colors.pink[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/no_content.svg',
            height:
                orientation == Orientation.portrait ? height / 2.5 : height / 3,
          ),
          Padding(
            padding: EdgeInsets.only(top: 05),
            child: Text(
              'No Posts',
              style: TextStyle(
                  color: Colors.deepPurpleAccent[200],
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  profilePost() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return splashScreen();
    } else if (postOreinted == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(post),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOreinted == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  setOreintation(String postOreintation) {
    setState(() {
      this.postOreinted = postOreintation;
    });
  }

  toggleButtonPost() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          onPressed: () => setOreintation('grid'),
          color: postOreinted == 'grid' ? Colors.pink[700] : Colors.grey,
        ),
        IconButton(
          icon: Icon(Icons.list),
          onPressed: () => setOreintation('list'),
          color: postOreinted == 'list' ? Colors.pink[700] : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarHeader(
        title: 'Profile',
      ),
      body: ListView(
        children: <Widget>[
          profileHeader(),
          Divider(),
          toggleButtonPost(),
          Divider(
            height: 0,
          ),
          profilePost()
        ],
      ),
    );
  }
}
