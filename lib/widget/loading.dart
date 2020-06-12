import 'package:flutter/material.dart';

Container circularProgress(){
  return Container(
    padding: EdgeInsets.only(top: 12.0),
    alignment: Alignment.center,
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
      backgroundColor: Colors.teal,

    ),
  );
}

Container linearProgress(){
  return Container(
    height: 15,
    padding: EdgeInsets.only(bottom: 10),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
      backgroundColor: Colors.purpleAccent,

    ),
  );
}