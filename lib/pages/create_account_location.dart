import 'dart:async';
import 'package:fabbit/widgets/header.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CreateAccountLocation extends StatefulWidget {
  @override
  CreateAccountLocationState createState() => CreateAccountLocationState();
}

class UserData {
  String username;
  String userLocation;
  double latitude;
  double longitude;

  UserData(this.username, this.userLocation, this.latitude, this.longitude);
}

class CreateAccountLocationState extends State<CreateAccountLocation> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController userLocationController = TextEditingController();
  bool isLoading = false;
  bool _usernameValid = true;
  bool _userLocationValid = true;
  bool _addressValid = true;
  String location;
  double latitude;
  double longitude;

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
    _addressValid = true;
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        'subthroughfare: ${placemark.subThoroughfare} throughfare: ${placemark.thoroughfare}, sublocality: ${placemark.subLocality} locality: ${placemark.locality}, subAdministrativeArea:${placemark.subAdministrativeArea},administrativeArea: ${placemark.administrativeArea} postalCode:${placemark.postalCode}, country:${placemark.country}';
    print(completeAddress);
    String formattedAddress =
        "${placemark.locality}, ${placemark.administrativeArea}";
    userLocationController.text = formattedAddress;
    location = formattedAddress;
    latitude = position.latitude;
    longitude = position.longitude;
  }

  convertUserLocationToCoordinates(String userLocationText) async {
    _addressValid = true;
    print('previous $_addressValid, $userLocationText');
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromAddress(userLocationText)
        .catchError((onError) {
      _addressValid = false;
    });

    print('after $_addressValid');
    if (_addressValid) {
      Placemark placemark = placemarks[0];
      latitude = placemark.position.latitude;
      longitude = placemark.position.longitude;
    }
  }

  clearLocation() {
    userLocationController.clear();
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
          inputFormatters: [
            WhitelistingTextInputFormatter(
                new RegExp('^[A-Za-z0-9 _]*[A-Za-z0-9][A-Za-z0-9 _]*')),
          ],
          maxLength: 20,
          decoration: InputDecoration(
            hintText: "Create a username",
            errorText: _usernameValid ? null : "Display Name is too short.",
            prefixIcon: Icon(
              Icons.account_box,
              size: 28.0,
            ),
          ),
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
            "Set Your Location",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: userLocationController,
          decoration: InputDecoration(
            hintText: "Set your location (city, state/province)",
            errorText: _userLocationValid ? null : "Location is invalid.",
            prefixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: clearLocation,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.my_location,
                color: Theme.of(context).accentColor,
              ),
              onPressed: getUserLocation,
            ),
          ),
        ),
      ],
    );
  }

  submit() async {
    setState(() {
      usernameController.text.trim().length < 3 ||
              usernameController.text.isEmpty
          ? _usernameValid = false
          : _usernameValid = true;
      userLocationController.text.trim().length > 30
          ? _userLocationValid = false
          : _userLocationValid = true;
    });

    if (_usernameValid && _userLocationValid) {
      setState(() {
        isLoading = true;
      });
      await convertUserLocationToCoordinates(userLocationController.text);
      if (_addressValid) {
        location = usernameController.text;
      }
      print('latitude: $latitude, longitude: $longitude');
      SnackBar snackbar = SnackBar(
        content: Text("Welcome ${usernameController.text}."),
      );
      _scaffoldKey.currentState.showSnackBar(snackbar);
      UserData userData =
          new UserData(usernameController.text, location, latitude, longitude);
      print('userData $userData');
      Timer(Duration(seconds: 2), () {
        setState(() {
        isLoading = false;
        });
        Navigator.of(context).pop(userData);
      });
    }
    // usersRef.document(widget.currentUserId).updateData({
    //   "displayName": displayNameController.text,
    //   "bio": bioController.text,
    // });
    // SnackBar snackbar = SnackBar(content: Text("Profile updated."),);
    // _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: header(context,
            titleText: "Setup your profile", removeBackButton: true),
        body: 
        
        isLoading ? circularProgress() :
        ListView(
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
