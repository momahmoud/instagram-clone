import 'package:flutter/material.dart';

appBarHeader({
  String title,
  bool isTitle = false,
  bool removeBack = false,
}) {
  return AppBar(
     backgroundColor: Colors.white70,
    automaticallyImplyLeading: removeBack? false : true,
    centerTitle: true,
    title: Text(
      isTitle ? 'GramyShare' : title,
      style: TextStyle(
        color: Colors.lightBlue,
        fontFamily: 'Signatra',
        fontSize: isTitle ? 40 : 35,
        
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}
