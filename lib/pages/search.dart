// geohash length
// 1 <= 5000 km x 5000 km
// 2 <= 1250 km x 625km
// 3 <= 156 km x 156 km
// 4 <= 39.1 km x 19.5 km
// 5 <= 4.89 km x 4.89 km
// 6 <= 1.22 km x 0.61 km 
// 7 <= 153 m x 153 m
// 8 <= 38.2 m x 19.1 m
// 9 <= 4.77 m x 4.77 m
// 10 <= 1.19 m x 0.596 m
// 11 <= 149 mm x 149 mm
// 12 <= 37.2 mm x 18.6 mm


import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fabbit/models/user.dart';
import 'package:fabbit/pages/activity_feed.dart';
import 'package:fabbit/pages/home.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where("displayName", isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search for fab finds...",
          filled: true,
          prefixIcon: Icon(
            Icons.shop,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 200.0 : 100.0,
            ),
            Text(
              "Find something good",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 40.0,
              ),
            )
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
          // print(user);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(.6),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Divider(
            height: 2.0,color:Colors.white54)
        ],
      ),
    );
  }
}
