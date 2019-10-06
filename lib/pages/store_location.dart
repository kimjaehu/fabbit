import 'dart:async';

import 'package:fabbit/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:fabbit/models/dropdown.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import '../credentials.dart';

class StoreLocation extends StatefulWidget {
  @override
  _StoreLocationState createState() => _StoreLocationState();
}

class ReturnedStoreLocation {
  String primaryText;
  String secondaryText;
  String placeId; 

  ReturnedStoreLocation(this.primaryText, this.secondaryText,this.placeId);
}

class _StoreLocationState extends State<StoreLocation> {
  TextEditingController locationController = TextEditingController();
  bool _locationValid = true;
  List<Dropdown> _placesList;
  String storeLocation;
  Position userLocation;
  String primaryText;
  String secondaryText;
  String placeId; 

  Future<Position> _getUserLocation() async {
    var position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((position) {
      userLocation = position;
      _placesList = [];
      storeLocation = "";
      primaryText="";
      secondaryText="";
      placeId="";
    });
  }

  submit() {
    setState(() {
      locationController.text.isEmpty
          ? _locationValid = false
          : _locationValid = true;
      storeLocation.isEmpty ? _locationValid = false : _locationValid = true;
    });

    if (_locationValid) {
      ReturnedStoreLocation returnedStoreLocation = new ReturnedStoreLocation(primaryText, secondaryText,placeId);
      Navigator.pop(context, returnedStoreLocation);
    }
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
    // String request = '$baseURL?input=$input&location=$latitude,$longitude&key=$PLACES_API_KEY&radius=$radius&strictbounds&sessiontoken=$postId';

    String request = '$baseURL?input=$input&location=$latitude,$longitude&key=$PLACES_API_KEY&radius=$radius&strictbounds';

    Response response = await Dio().get(request);
    print(response);
    final predictions = response.data['predictions'];

    return predictions;
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
        appBar: header(context, titleText: "Submit store location"),
        body: ListView(
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 25.0),
                    child: Center(
                      child: Text(
                        "Find the store",
                        style: TextStyle(fontSize: 25.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      child: TypeAheadField(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: this.locationController,
                          decoration: InputDecoration(
                            hintText: "Enter the store/store location",
                            errorText: _locationValid
                                ? null
                                : "Store location is invalid.",
                            border: InputBorder.none,
                          ),
                        ),
                        suggestionsCallback: (pattern) async {
                          return await getLocationResults(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion['structured_formatting']
                                ['main_text']),
                            subtitle: Text(suggestion['structured_formatting']
                                ['secondary_text']),
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          primaryText = suggestion['structured_formatting']['main_text'];
                          secondaryText = suggestion['structured_formatting']['secondary_text'];
                          placeId = suggestion['placeId'];
                        },
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
