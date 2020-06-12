import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/widget/activity_feed_item.dart';
import 'package:gramyshare/widget/loading.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> usersResult;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isLessThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      usersResult = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar searchingField() {
    return AppBar(
      elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      backgroundColor: Colors.transparent,
      title: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: TextFormField(
          controller: searchController,
          enableSuggestions: true,
          decoration: InputDecoration(
            
            border: InputBorder.none,
            hintText: 'Search for a user',
            filled: true,
            fillColor: Colors.lightBlueAccent[50],
            prefixIcon: Icon(
              Icons.account_box,
              size: 27,
              color: Colors.lightBlue,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: clearSearch,
              color: Colors.lightBlue,
            ),
          ),
          onFieldSubmitted: handleSearch,
          onChanged: handleSearch,
        ),
      ),
    );
  }

  Container bodyNoContent() {
    final height = MediaQuery.of(context).size.height;
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height:
                  orientation == Orientation.portrait ? height / 2 : height / 3,
            ),
            Text(
              'Find users',
              style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  fontFamily: 'Signatra'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  searchResult() {
    return FutureBuilder(
      future: usersResult,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        } else if (snapshot.hasError) {
          return Text('Try again!');
        }
        List<UserResult> searchRes = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult userResult = UserResult(user);
          searchRes.add(userResult);
        });
        return ListView(
          children: searchRes,
        );
      },
    );
  }
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: searchingField(),
      body: usersResult == null ? bodyNoContent() : searchResult(),
    );
  }

  

}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black45,
                ),
              ),
            ),
          ),
          Divider(
            height: 1.5,
            endIndent: 30,
            indent: 30,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}
