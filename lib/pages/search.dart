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
import 'package:fabbit/widgets/post.dart';
import 'package:fabbit/widgets/post_tile.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:auto_size_text/auto_size_text.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  List<Post> posts = [];

  bool isLoading = false;

  final categories = [
    {"text":"All","color": Colors.cyanAccent[700]},
    {"text":"Electronics & Office","color":Colors.grey[800]},
    {"text":"Fashion","color":Colors.orange},
    {"text":"Home & Appliances","color":Colors.grey[800]},
    {"text":"Movies, Music & Books","color":Colors.grey[800]},
    {"text":"Baby","color":Colors.grey[800]},
    {"text":"Toys and Video Games","color":Colors.grey[800]},
    {"text":"Food & Household","color":Colors.grey[800]},
    {"text":"Pets","color":Colors.grey[800]},
    {"text":"Health & Beauty","color":Colors.red},
    {"text":"Sports & Outdoors","color":Colors.grey[800]},
    {"text":"Automotive & Industrial","color":Colors.grey[800]},
    {"text":"Art & Craft","color":Colors.grey[800]},
    {"text":"Misc.","color":Colors.grey[800]},
  ];

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

  Widget buildCategoriesButtons() {
    return GridView.count(
      crossAxisCount: 4,
      scrollDirection: Axis.vertical,
      childAspectRatio: 1.0,
      children: List.generate(categories.length, (index) {
        return Card(
          color: categories[index]["color"],
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: InkWell(
              onTap: getCategoryPosts,
              child: Center(
                child: AutoSizeText(
                  categories[index]["text"],
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }),
      // children: <Widget>[
      // Card(
      //   color: Colors.grey[800],
      //   child: Padding(
      //     padding: EdgeInsets.all(8.0),
      //     child: InkWell(
      //       onTap: () {},
      //       child: Center(
      //         child: AutoSizeText(
      //           "All",
      //           style: TextStyle(
      //             fontSize: 30,
      //             color: Colors.white,
      //             fontWeight: FontWeight.bold,
      //           ),
      //           maxLines: 2,
      //           textAlign: TextAlign.center,
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      // ],
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

  getCategoryPosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsGroupRef
        // .where("category", "==", category)
        // .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildCategoryPosts() {
    if (isLoading) {
      return circularProgress();
    }
    List<GridTile> gridTiles = [];
    posts.forEach((post) {
      gridTiles.add(GridTile(child: PostTile(post)));
    });

    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: Card(
            color: Colors.grey[800],
            child: Padding(
              padding: EdgeInsets.only(left: 4.0, right: 4.0),
              child: InkWell(
                onTap: () {setState(() {
                  posts = [];
                });},
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(left:6.0, right: 6.0),
                          child: Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: Colors.white,
                          )),
                      Padding(
                        padding: EdgeInsets.only(left:6.0, right: 6.0),
                        child: AutoSizeText(
                          "Go Back to Choose Category",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
        GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            mainAxisSpacing: 1.5,
            crossAxisSpacing: 1.5,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: gridTiles)
      ],
    );
  }

  buildSearchResults() {
    if (isLoading) {
      return circularProgress();
    }
    // return FutureBuilder(
    //   future: searchResultsFuture,
    //   builder: (context, snapshot) {
    //     if (!snapshot.hasData) {
    //       return circularProgress();
    //     }
    //     List<UserResult> searchResults = [];
    //     snapshot.data.documents.forEach((doc) {
    //       User user = User.fromDocument(doc);
    //       UserResult searchResult = UserResult(user);
    //       searchResults.add(searchResult);
    //       // print(user);
    //     });
    //     return ListView(
    //       children: searchResults,
    //     );
    //   },
    // );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      // backgroundColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      appBar: buildSearchField(),
      body: posts.isEmpty ? buildCategoriesButtons() : buildCategoryPosts(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
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
          Divider(height: 2.0, color: Colors.white54)
        ],
      ),
    );
  }
}
