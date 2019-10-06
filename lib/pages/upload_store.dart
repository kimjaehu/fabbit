import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fabbit/pages/store_location.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as Im;
import 'package:fabbit/credentials.dart';
import 'package:dio/dio.dart';
import 'package:fabbit/pages/home.dart';
import 'package:fabbit/models/user.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:fabbit/models/dropdown.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

final Geoflutterfire geo = Geoflutterfire();

class UploadStore extends StatefulWidget {
  final User currentUser;

  UploadStore({this.currentUser});

  @override
  _UploadStoreState createState() => _UploadStoreState();
}

class _UploadStoreState extends State<UploadStore>
    with AutomaticKeepAliveClientMixin<UploadStore> {
  Geolocator geolocator = Geolocator();
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  bool isUploading = false;
  bool _locationValid = true;
  String postId = Uuid().v4();
  Position userLocation;
  String _placeId;
  List<Dropdown> _placesList;

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((position) {
      userLocation = position;
      _placesList = [];
      _placeId = "";
    });
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Take a photo"),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                "Upload Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              color: Colors.deepOrange,
              onPressed: () => selectImage(context),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 50));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl,
      String location,
      String description,
      double longitude,
      double latitude,
      GeoFirePoint userLocation}) {
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "position": userLocation.data,
      "timestamp": timestamp,
      "likes": {},
    });
    captionController.clear();
    locationController.clear();
    _placeId = "";
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  getStoreLocation() {
    // String baseURL =
    //     'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    // int radius = 10000;
    // double latitude = userLocation.latitude;
    // double longitude = userLocation.longitude;
    // String request = '$baseURL?input=$input&location=$latitude,$longitude&key=$PLACES_API_KEY&radius=$radius&strictbounds&sessiontoken=$postId';
    // // String request =
    // //     '$baseURL?input=$input&location=43.5890, -79.6441&key=$PLACES_API_KEY&radius=$radius&strictbounds&sessiontoken=$postId';

    // Response response = await Dio().get(request);
    // print(response);
    // final predictions = response.data['predictions'];
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
      locationController.text.isEmpty
          ? _locationValid = false
          : _locationValid = true;
      _placeId.isEmpty ? _locationValid = false : _locationValid = true;
    });

    if (_locationValid) {
      await getStoreLocation();
      await compressImage();
      GeoFirePoint userLocationPoint = geo.point(
          latitude: userLocation.latitude, longitude: userLocation.longitude);
      String mediaUrl = await uploadImage(file);
      createPostInFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text,
        userLocation: userLocationPoint,
      );
    }
    setState(() {
      isUploading = false;
    });
  }

  getLocationResults(String input) async {
    if (input.isEmpty) {
      setState(() {
        return;
      });
    }
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    int radius = 10000;
    double latitude = userLocation.latitude;
    double longitude = userLocation.longitude;
    // String request =
        // '$baseURL?input=$input&location=$latitude,$longitude&key=$PLACES_API_KEY&radius=$radius&strictbounds&sessiontoken=$postId';
    String request =
        '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$postId';

    Response response = await Dio().get(request);
    print(response);
    final predictions = response.data['predictions'];

    // List<Dropdown> _displayResults = [];

    // predictions.forEach((prediction) {
    //   String primaryText = prediction['structured_formatting']['main_text'];
    //   String secondaryText =
    //       prediction['structured_formatting']['secondary_text'];
    //   _displayResults.add(Dropdown(primaryText, secondaryText));
    // });
    // setState(() {
    //   _placesList = _displayResults;
    // });
    return predictions;
  }

  Widget buildSuggestedLocations(BuildContext context, int index) {
    return ListTile(
      title: Text(
        _placesList[index].primaryText,
      ),
      subtitle: Text(_placesList[index].secondaryText),
      dense: true,
      onTap: () {},
    );
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Text(
          "Post it",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: Icon(Icons.pin_drop, color: Colors.orange, size: 35.0),
            title: Container(
              width: 250.0,
              child: RaisedButton.icon(
                label: Text(
                  "Find the store",
                  style: TextStyle(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                color: Colors.blue,
                onPressed: () async {
                  final returnedStoreLocation = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => StoreLocation()));
                  locationController.text = returnedStoreLocation.primaryText;
                },
                icon: Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          locationController.text.isEmpty
              ? Text('')
              : ListTile(
                  leading:
                      Icon(Icons.pin_drop, color: Colors.orange, size: 35.0),
                  title: Container(
                    width: 250.0,
                    child: TextField(
                      controller: locationController,
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ),
          Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Description", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  Future<Position> _getUserLocation() async {
    var position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
