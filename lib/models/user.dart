import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String location;
  // final double latitude;
  // final double longitude;
  final dynamic position;

User({
  this.id,
  this.username,
  this.email,
  this.photoUrl,
  this.displayName,
  this.bio,
  this.location,
  // this.latitude,
  // this.longitude,
  this.position,
});

factory User.fromDocument(DocumentSnapshot doc) {
  return User(
    id: doc['id'],
    email: doc['email'],
    username: doc['username'],
    photoUrl: doc['photoUrl'],
    displayName: doc['displayName'],
    bio: doc['bio'],
    location: doc['location'],
    // latitude: doc['latitude'],
    // longitude: doc['longitude'],
    position: doc['position'],
  );
}

}
