import 'dart:async';
import 'dart:typed_data';
import 'package:fabbit/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CreateAccountLocation extends StatefulWidget {
  @override
  CreateAccountLocationState createState() => CreateAccountLocationState();
}

class UserData{
  String username;
  String userLocation;

  UserData(
    this.username, this.userLocation,
  );
}

class CreateAccountLocationState extends State<CreateAccountLocation> {


  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController userLocationController = TextEditingController();
  bool isLoading = false;
  bool _usernameValid = true;
  bool _userLocationValid = true;

  @override
  void initState() { 
    super.initState();
    getUserLocation();
  }
  // submit() {
  //   final form = _formKey.currentState;

  //   if (form.validate()) {}
  //   form.save();
  //   SnackBar snackbar = SnackBar(
  //     content: Text("Welcome $username."),
  //   );
  //   _scaffoldKey.currentState.showSnackBar(snackbar);
  //   Timer(Duration(seconds: 1), () {
  //     Navigator.pop(context, username);
  //   });
  // }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        'subthroughfare: ${placemark.subThoroughfare} throughfare: ${placemark.thoroughfare}, sublocality: ${placemark.subLocality} locality: ${placemark.locality}, subAdministrativeArea:${placemark.subAdministrativeArea},administrativeArea: ${placemark.administrativeArea} postalCode:${placemark.postalCode}, country:${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.administrativeArea}";
    // setState(() {
    //   location = formattedAddress;
    // });
    userLocationController.text = formattedAddress;
  }

  Column buildUsernameField() {
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
          controller: usernameController,
          decoration: InputDecoration(
              hintText: "Create a username",
              errorText: _usernameValid ? null : "Display Name is too short."),
        )
      ],
    );
  }

  Column buildUserLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Your Location",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: userLocationController,
          decoration: InputDecoration(
              hintText: "Enter your location (city, state)",
              errorText: _userLocationValid ? null : "Location is invalid."),
        )
      ],
    );
  }

  submit() {
    setState(() {
      usernameController.text.trim().length < 3 ||
              usernameController.text.isEmpty
          ? _usernameValid = false
          : _usernameValid = true;
      userLocationController.text.trim().length > 100
          ? _userLocationValid = false
          : _userLocationValid = true;
    });

    if (_usernameValid && _userLocationValid) {
      // usersRef.document(widget.currentUserId).updateData({
      //   "displayName": displayNameController.text,
      //   "bio": bioController.text,
      // });
      // SnackBar snackbar = SnackBar(content: Text("Profile updated."),);
      // _scaffoldKey.currentState.showSnackBar(snackbar);
      SnackBar snackbar = SnackBar(
        content: Text("Welcome ${usernameController.text}."),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
      UserData userData = new UserData(usernameController.text, userLocationController.text);
      print('userData $userData');
      Timer(Duration(seconds: 1), () {
        Navigator.of(context).pop(userData);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: header(context,
            titleText: "Setup your profile", removeBackButton: true),
        body: ListView(
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        buildUsernameField(),
                        buildUserLocationField(),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: submit,
                    child: Container(
                      height: 50.0,
                      width: 350.0,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
