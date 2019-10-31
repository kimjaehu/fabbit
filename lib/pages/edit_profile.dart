import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fabbit/models/user.dart';
import 'package:fabbit/widgets/progress.dart';
import "package:flutter/material.dart";
import 'package:fabbit/pages/home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;
  String username;
  String userEmail;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    username = user.username;
    userEmail = user.email;

    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Username",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
              hintText: "Update username",
              errorText: _displayNameValid ? null : "Username is too short."),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
              hintText: "Update Bio",
              errorText: _bioValid ? null : "Bio is too long."),
        )
      ],
    );
  }

  Column buildUsername() {}

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text,
      });
      SnackBar snackbar = SnackBar(
        content: Text("Profile updated."),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Options",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
          )
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      // Padding(
                      //   padding: EdgeInsets.only(
                      //     top: 16.0,
                      //     bottom: 8.0,
                      //   ),
                      //   child: CircleAvatar(
                      //     radius: 50.0,
                      //     backgroundImage:
                      //         CachedNetworkImageProvider(user.photoUrl),
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            // buildDisplayNameField(),
                            // buildBioField(),
                          ],
                        ),
                      ),
                      // RaisedButton(
                      //   onPressed: updateProfileData,
                      //   child: Text(
                      //     "Update Profile",
                      //     style: TextStyle(
                      //         color: Colors.grey[800],
                      //         fontSize: 20.0,
                      //         fontWeight: FontWeight.bold),
                      //   ),
                      // ),

                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(
                            Icons.undo,
                            color: Colors.red,
                          ),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.filter_none,
                            size: 15.0,
                            color: Colors.black,
                          ),
                          label: Text(
                            "Terms of Use",
                            style:
                                TextStyle(color: Colors.black, fontSize: 15.0),
                          ),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Container(
                            child: Text(
                              "These Terms of Use govern your use of Fabbit and provide information about Fabbit. When you use Fabbit, you agree to these terms. Fabbit is committed to provide a platform for Fab Finders to share their finds.\nFabbit accesses the information and content you provide which in turn is used for measurement, analytics and other business related services.\n\nCommitments:\nYou must be at the minimum legal age in your country to use Fabbit.\nYou cannot impersonate others or provide inaccurate information.\nYou cannot do anything unlawful, fraudulent or illegal.\nYou cannot violate these Terms.\nYou can't post illegal or content that violates intellectual property.\n\n Update to these Terms\nWe may change our service and policies. If you do not agree to these terms, you can delete your account by contacting us.",
                              style: TextStyle(fontSize: 12.0),
                            ),
                          )),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
