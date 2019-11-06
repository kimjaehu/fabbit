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
import 'package:fabbit/widgets/header.dart';
import 'package:fabbit/widgets/post.dart';
import 'package:fabbit/widgets/post_tile.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';

class Search extends StatefulWidget {
  final User currentUser;

  Search({this.currentUser});
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  List<Post> posts = [];

  Position _userLocation;
  bool isLoading = false;

  final categories = [
    {"text": "All", "color": Colors.cyanAccent[700]},
    {"text": "Electronics & Office", "color": Colors.grey[800]},
    {"text": "Fashion", "color": Colors.orange},
    {"text": "Home & Appliances", "color": Colors.grey[800]},
    {"text": "Movies, Music & Books", "color": Colors.grey[800]},
    {"text": "Baby", "color": Colors.lightGreen},
    {"text": "Toys and Video Games", "color": Colors.grey[800]},
    {"text": "Food & Household", "color": Colors.grey[800]},
    {"text": "Pets", "color": Colors.grey[800]},
    {"text": "Health & Beauty", "color": Colors.purpleAccent},
    {"text": "Sports & Outdoors", "color": Colors.grey[800]},
    {"text": "Automotive & Industrial", "color": Colors.grey[800]},
    {"text": "Art & Craft", "color": Colors.grey[800]},
    {"text": "Misc.", "color": Colors.grey[800]},
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((position) {
      _userLocation = position;
      getCategoryPosts(categories[0]["text"]);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // handleSearch(String query) {
  //   Future<QuerySnapshot> users = usersRef
  //       .where("displayName", isGreaterThanOrEqualTo: query)
  //       .getDocuments();
  //   setState(() {
  //     searchResultsFuture = users;
  //   });
  // }

  handleSearch(String query) {
    setState(() {
      isLoading = true;
    });
    GeoFirePoint center = geo.point(
        latitude: _userLocation.latitude, longitude: _userLocation.longitude);
    double radius = 35;
    String field = 'position';

    var collectionReference =
        postsGroupRef.where("keywords", arrayContains: query);
    Stream<List<DocumentSnapshot>> stream = geo
        .collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: field);
    stream.listen((List<DocumentSnapshot> documentList) {
      setState(() {
        isLoading = false;
        posts = documentList.map((doc) => Post.fromDocument(doc)).toList();
      });
    });

    setState(() {
      isLoading = false;
      // posts = postsList;
      // posts =
      //     snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
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
        inputFormatters: [
          BlacklistingTextInputFormatter(new RegExp('[\\-|\\ ]'))
        ],
        decoration: InputDecoration(
          hintText: "fab finds one keyword at a time...",
          filled: true,
          prefixIcon: Icon(
            Icons.search,
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

  Widget buildCategoriesRow() {
    return ListView.builder(
      itemCount: categories.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: categories[index]["color"],
          child: Padding(
            padding: EdgeInsets.only(left: 6.0, right: 6.0),
            child: InkWell(
              onTap: () => getCategoryPosts(categories[index]["text"]),
              child: Center(
                child: AutoSizeText(
                  categories[index]["text"],
                  style: TextStyle(
                    fontSize: 8,
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
      },
    );
  }

  Widget buildCategoriesButtons() {
    return Padding(
      padding: EdgeInsets.only(top: 10.0),
      child: GridView.count(
        crossAxisCount: 4,
        scrollDirection: Axis.vertical,
        childAspectRatio: 1.0,
        children: List.generate(categories.length, (index) {
          return Card(
            color: categories[index]["color"],
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => getCategoryPosts(categories[index]["text"]),
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
            Icon(
              Icons.texture,
              size: 120,
            ),
            Text(
              "No Fab Finds Yet!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),
            )
            // SvgPicture.asset(
            //   'assets/images/search.svg',
            //   height: orientation == Orientation.portrait ? 200.0 : 100.0,
            // ),
            // Text(
            //   "Find something good",
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontStyle: FontStyle.italic,
            //     fontWeight: FontWeight.w600,
            //     fontSize: 40.0,
            //   ),
          ],
        ),
      ),
    );
  }

  Future<Position> _getUserLocation() async {
    var position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  getCategoryPosts(category) async {
    setState(() {
      isLoading = true;
    });
    GeoFirePoint center = geo.point(
        latitude: _userLocation.latitude, longitude: _userLocation.longitude);
    double radius = 35;
    String field = 'position';
    if (category == "All") {
      // QuerySnapshot snapshot = await postsGroupRef
      //     .orderBy('timestamp', descending: true)
      //     .getDocuments();

      var collectionReference = postsGroupRef;
      Stream<List<DocumentSnapshot>> stream = geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: radius, field: field);
      stream.listen((List<DocumentSnapshot> documentList) {
        setState(() {
          isLoading = false;
          posts = documentList.map((doc) => Post.fromDocument(doc)).toList();
        });
      });

      setState(() {
        isLoading = false;
        // posts = postsList;
        // posts =
        //     snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
      });
    } else {
      var collectionReference =
          postsGroupRef.where("category", isEqualTo: category);
      Stream<List<DocumentSnapshot>> stream = geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: radius, field: field);
      stream.listen((List<DocumentSnapshot> documentList) {
        setState(() {
          isLoading = false;
          posts = documentList.map((doc) => Post.fromDocument(doc)).toList();
        });
      });

      setState(() {
        isLoading = false;
        // posts = postsList;
        // posts =
        //     snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
      });

      // QuerySnapshot snapshot = await postsGroupRef
      //     .where("category", isEqualTo: category)
      //     .orderBy('timestamp', descending: true)
      //     .getDocuments();
      // setState(() {
      //   isLoading = false;
      //   posts =
      //       snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
      // });
    }
  }

  buildCategoryPosts() {
    if (isLoading) {
      return circularProgress();
    }
    List<GridTile> gridTiles = [];
    posts.forEach((post) {
      bool fabDeal = false;
      if (post.originalPrice.isNotEmpty ||
          post.discountedPrice.isNotEmpty ||
          double.parse(post.originalPrice) >
              double.parse(post.discountedPrice)) {
        double _originalPrices = double.parse(post.originalPrice);
        double _discountedPrices = double.parse(post.discountedPrice);
        double _percentage = (1 - (_discountedPrices / _originalPrices)) * 100;
        if (_percentage >= 50) {
          fabDeal = true;
        }
      }
      gridTiles.add(fabDeal
          ? GridTile(
              header: 
              // Container(
              //   color: Colors.redAccent,
              //   padding: EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
              //   child: 
                Padding(
                  padding: EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
                    child: Text(
                    'FAB DEAL!',
                    style: TextStyle(
                        fontSize: 10.0,
                        color: Colors.white,
                        backgroundColor: Colors.redAccent,
                        fontWeight: FontWeight.bold),
                    // textAlign: TextAlign.center,
                  ),
                ),
              // ),
              child: PostTile(post),
            )
          : GridTile(
              child: PostTile(post),
            ));
    });

    return ListView(
      children: <Widget>[
        // Padding(
        //   padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
        //   child: Card(
        //     color: Colors.grey[700],
        //     child: Padding(
        //       padding: EdgeInsets.only(left: 4.0, right: 4.0),
        //       child: InkWell(
        //         onTap: () {
        //           setState(() {
        //             posts = [];
        //           });
        //         },
        //         child: Padding(
        //           padding: EdgeInsets.all(8.0),
        //           child: Center(
        //               child: Row(
        //             mainAxisAlignment: MainAxisAlignment.center,
        //             children: <Widget>[
        //               Padding(
        //                   padding: EdgeInsets.only(left: 6.0, right: 6.0),
        //                   child: Icon(
        //                     Icons.arrow_back,
        //                     size: 28,
        //                     color: Colors.white,
        //                   )),
        //               Padding(
        //                 padding: EdgeInsets.only(left: 6.0, right: 6.0),
        //                 child: AutoSizeText(
        //                   "Go Back to Choose Category",
        //                   style: TextStyle(
        //                     fontSize: 20,
        //                     color: Colors.white,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                   maxLines: 1,
        //                   textAlign: TextAlign.center,
        //                 ),
        //               ),
        //             ],
        //           )),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: gridTiles,
        )
      ],
    );
  }

  // buildSearchResults() {
  //   if (isLoading) {
  //     return circularProgress();
  //   }
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
  //     });
  //     return ListView(
  //       children: searchResults,
  //     );
  //   },
  // );
  // }

  Widget buildContent() {
    return Column(
      children: <Widget>[],
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        backgroundColor: Colors.white,
        // backgroundColor: Theme.of(context).primaryColor,
        appBar: header(context, isAppTitle: true),
        // appBar: buildSearchField(),
        body: Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(
                    top: 5.0, bottom: 5.0, right: 10.0, left: 10.0),
                child: SizedBox(
                  height: 30.0,
                  child: buildCategoriesRow(),
                )),
            Expanded(
              child: posts.isEmpty ? buildNoContent() : buildCategoryPosts(),
            )
          ],
        ));
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
