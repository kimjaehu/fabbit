import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle = false, String titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "Fabbit" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? "Playfair" : "",
        fontSize: isAppTitle ? 30.0 : 20,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: isAppTitle ? false : true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
