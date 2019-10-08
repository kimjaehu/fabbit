import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'dart:async';
import 'package:multi_image_picker/multi_image_picker.dart';

final Geoflutterfire geo = Geoflutterfire();

class MultiUpload extends StatefulWidget {
  final User currentUser;

  MultiUpload({this.currentUser});

  @override
  _MultiUploadState createState() => _MultiUploadState();
}

class _MultiUploadState extends State<MultiUpload>
    with AutomaticKeepAliveClientMixin<MultiUpload> {
  Geolocator geolocator = Geolocator();
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _captionController = new TextEditingController();
  TextEditingController _originalPriceController = new TextEditingController();
  TextEditingController _discountedPriceController =
      new TextEditingController();
  Timer _throttle;
  File file;
  bool isUploading = false;
  bool _locationValid = true;
  bool _placeIdValid = false;
  String postId = Uuid().v4();
  String sessionToken = Uuid().v4();
  Position userLocation;
  GeoFirePoint storeLocation;
  String _placeId;
  List<Dropdown> _placesList;
  List<Asset> images = List<Asset>();
  String _error;

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((position) {
      userLocation = position;
    });
    _placesList = [];
    _placeId = "";
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
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

  // handleChooseFromGallery() async {
  //   Navigator.pop(context);
  //   File file = await ImagePicker.pickImage(source: ImageSource.gallery);
  //   setState(() {
  //     this.file = file;
  //   });
  // }

  Future<void> handleChooseFromGallery() async {
    Navigator.pop(context);
    setState(() {
      images = List<Asset>();
    });

    List<Asset> resultList;
    String error;

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
      );
    } on Exception catch (e) {
      error = '$e';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    print('resultList $resultList');
    setState(() {
      resultList == null ? images = [] : images = resultList;
      if (error == null) _error = 'No Error Dectected';
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
      images = [];
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

  Future<List<String>> uploadImages() async {
    List<String> uploadUrls = [];
    print('upload images started ${images.length}');
    await Future.wait(images.map((Asset image) async {
      print('image: $image');
      ByteData byteData = await image.getByteData(quality: 50);
      List<int> imageData = byteData.buffer.asUint8List();
      String fileName = 'post_${postId}_${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
      StorageUploadTask uploadTask =
        storageRef.child(fileName).putData(imageData);
      // StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
      // String downloadUrl = await storageSnap.ref.getDownloadURL();
      // print('downloadUrl $downloadUrl');
      // uploadUrls.add(downloadUrl);
      StorageTaskSnapshot storageTaskSnapshot;
      StorageTaskSnapshot snapshot = await uploadTask.onComplete;
      if (snapshot.error == null) {
        storageTaskSnapshot = snapshot;
        final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
        uploadUrls.add(downloadUrl);
        print('uploadUrls = ${uploadUrls.length}');
        print('Upload success');
      } else {
        print('Error from image repo ${snapshot.error.toString()}');
        throw ('This file is not an image');
      }
    }));
    print('uploadUrls at the end = ${uploadUrls.length}');
    return uploadUrls;
  }

  createPostInFirestore(
      {List<String> mediaUrls,
      String location,
      String description,
      String originalPrice,
      String discountedPrice,
      GeoFirePoint storeLocation}) {
        print('post start $mediaUrls');
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrls": mediaUrls,
      "description": description,
      "location": location,
      "position": storeLocation.data,
      "originalPrice": originalPrice,
      "discountedPrice": discountedPrice,
      "timestamp": timestamp,
      "likes": {},
    });
    print('post finished $mediaUrls');
    _captionController.clear();
    _locationController.clear();
    _originalPriceController.clear();
    _discountedPriceController.clear();
    _placeId = "";
    setState(() {
      file = null;
      images = [];
      isUploading = false;
      postId = Uuid().v4();
      sessionToken = Uuid().v4();
      _placeId = "";
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
      _locationController.text.isEmpty
          ? _locationValid = false
          : _locationValid = true;
    });
    print('handle submit');
    if (_locationValid && _placeIdValid) {
      print('uploading started');
      List<String> mediaUrls = await uploadImages();
      print(mediaUrls.length);
      GeoFirePoint storeLocation = await getStoreLocation();
      
      // await compressImage();
      // String mediaUrl = await uploadImage(file);

      createPostInFirestore(
          mediaUrls: mediaUrls,
          location: _locationController.text,
          description: _captionController.text,
          originalPrice: _originalPriceController.text,
          discountedPrice: _discountedPriceController.text,
          storeLocation: storeLocation);
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
    int radius = 30000;
    double latitude = userLocation.latitude;
    double longitude = userLocation.longitude;
    String request =
        '$baseURL?input=$input&location=$latitude,$longitude&key=$PLACES_API_KEY&radius=$radius&strictbounds&sessiontoken=$sessionToken';
    // String request =
    //     '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$sessionToken';
    print('session token in autocomplete $sessionToken');
    Response response = await Dio().get(request);
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

  getStoreLocation() async {
    String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    String request =
        '$baseURL?&key=$PLACES_API_KEY&place_id=$_placeId&sessiontoken=$sessionToken';
    print('session token in places detail $sessionToken');
    Response response = await Dio().get(request);
    final storeInfo = response.data['result']['geometry']['location'];

    GeoFirePoint storeLocationPoint =
        geo.point(latitude: storeInfo['lat'], longitude: storeInfo['lng']);

    print('store location point $storeLocationPoint');

    return storeLocationPoint;
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
          // Container(
          //   height: 220.0,
          //   width: MediaQuery.of(context).size.width * 0.8,
          //   child: Center(
          //     child: AspectRatio(
          //       aspectRatio: 16 / 9,
          //       child: Container(
          //         decoration: BoxDecoration(
          //           image: DecorationImage(
          //             fit: BoxFit.cover,
          //             image: FileImage(file),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: Icon(Icons.pin_drop, color: Colors.orange, size: 35.0),
            trailing: _placeIdValid
                ? Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 35.0)
                : Icon(Icons.highlight_off, color: Colors.red, size: 35.0),
            title: Container(
              width: 250.0,
              child: TypeAheadField(
                debounceDuration: Duration(milliseconds: 500),
                direction: AxisDirection.up,
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: "Store name & location",
                    errorText: _locationValid || _placeIdValid
                        ? null
                        : "Store location is invalid.",
                    border: InputBorder.none,
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  setState(() {
                    _placeIdValid = false;
                  });
                  return await getLocationResults(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title:
                        Text(suggestion['structured_formatting']['main_text']),
                    subtitle: Text(
                        suggestion['structured_formatting']['secondary_text']),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _locationController.text =
                      '${suggestion['structured_formatting']['main_text']}, ${suggestion['structured_formatting']['secondary_text']}';

                  setState(() {
                    _placeIdValid = true;
                    _placeId = suggestion['place_id'];
                  });
                },
              ),
            ),
          ),
          
          Divider(),
          ListTile(
            leading: Icon(Icons.attach_money, color: Colors.orange, size: 35.0),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: _originalPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: "Original Price", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.attach_money, color: Colors.orange, size: 35.0),
            title: Container(
              width: 250.0,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _discountedPriceController,
                decoration: InputDecoration(
                    hintText: "Discounted Price", border: InputBorder.none),
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
                controller: _captionController,
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

    return images.isEmpty ? buildSplashScreen() : buildUploadForm();
  }
}
