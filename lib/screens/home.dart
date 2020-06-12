import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gramyshare/screens/activity_feed_screen.dart';
import 'package:gramyshare/screens/create_user.dart';
import 'package:gramyshare/screens/profile_screen.dart';
import 'package:gramyshare/screens/search_screen.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/time_line_screen.dart';
import 'package:gramyshare/screens/upload_screen.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  PageController pageController;
  bool isAuth = false;
  int pageIndex = 0;
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: pageIndex);
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignin(account);
    }, onError: (error) {
      print('signin error : $error');
    });
    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) => handleSignin(account))
        .catchError((error) => print('signin error : $error'));
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  handleSignin(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      pushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  pushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiosPermission();
    _firebaseMessaging.getToken().then((token) {
      print('firebase token: $token\n');
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });
    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async{ },
      // onResume: (Map<String, dynamic> message) async{ },
      onMessage: (Map<String, dynamic> message) async {
        print('using app: $message\n');
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print('all done');
          SnackBar snackbar = SnackBar(
            content: Text(body, overflow: TextOverflow.ellipsis,),
          );
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print('not done');
      },
    );
  }

  getiosPermission() {
    _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(
        alert: true,
        badge: true,
        sound: true,
      ),
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("settings : $settings");
    });
  }

  googleLogin() {
    googleSignIn.signIn();
  }

  googleLogout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 250), curve: Curves.decelerate);
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateUserScreen(),
        ),
      );
      usersRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp
      });
      await followersRef
          .document(user.id)
          .collection('userFollower')
          .document(user.id)
          .setData({});
      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  Widget buildRegisterScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLineScreen(currentUser: currentUser),
          ActivityFeedScreen(),
          UploadScreen(currentUser: currentUser),
          SearchScreen(),
          ProfileScreen(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: Colors.white70,
        onTap: onTap,
        currentIndex: pageIndex,
        activeColor: Colors.lightBlueAccent[700],
        inactiveColor: Colors.grey[700],
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.whatshot,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
          ),
        ],
      ),
    );
  }

  Scaffold buildunRegisterScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'GramyShare',
              style: TextStyle(
                fontSize: 50,
                fontFamily: 'Signatra',
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: googleLogin,
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width / 1.5,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image:
                          AssetImage('assets/images/google_signin_button.png'),
                      fit: BoxFit.cover),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return !isAuth ? buildunRegisterScreen() : buildRegisterScreen();
  }
}
