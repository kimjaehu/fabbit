import 'dart:async';
import 'dart:ffi';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fabbit/models/user.dart';
import 'package:fabbit/pages/activity_feed.dart';
import 'package:fabbit/pages/comments.dart';
import 'package:fabbit/pages/home.dart';
import 'package:fabbit/widgets/custom_image.dart';
import 'package:fabbit/widgets/progress.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final List<String> mediaUrls;
  final String originalPrice;
  final String discountedPrice;
  final String category;
  final List<String> keywords;
  final dynamic likes;
  // final Position position;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrls,
    this.originalPrice,
    this.discountedPrice,
    this.category,
    this.keywords,
    // this.position,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrls: List.from(doc['mediaUrls']),
      originalPrice: doc['originalPrice'],
      discountedPrice: doc['discountedPrice'],
      category: doc['category'],
      keywords: List.from(doc['keywords']),
      // position: doc['position'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is set to true add 1 to count
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrls: this.mediaUrls,
        originalPrice: this.originalPrice,
        discountedPrice: this.discountedPrice,
        category: this.category,
        keywords: this.keywords,
        // position: this.position,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String originalPrice;
  final String discountedPrice;
  final String category;
  final List<String> keywords;
  final List<String> mediaUrls;
  // final Position position;
  bool showHeart = false;
  int likeCount;
  Map likes;
  bool isLiked;
  double _formattedOriginalPrices;
  double _formattedDiscountedPrices;
  double _discountPercentage;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrls,
    this.originalPrice,
    this.discountedPrice,
    this.likes,
    this.category,
    this.keywords,
    // this.position,
    this.likeCount,
  });

  @override
  void initState() { 
    super.initState();
    setState(() {
      if (originalPrice.isNotEmpty | discountedPrice.isNotEmpty) {
        _formattedOriginalPrices = double.parse(originalPrice);
        _formattedDiscountedPrices = double.parse(discountedPrice);
        _discountPercentage =
            (1 - (_formattedDiscountedPrices / _formattedOriginalPrices)) * 100;
      } else {
        _formattedOriginalPrices = null;
        _formattedDiscountedPrices = null;
        _discountPercentage = null;
      }
    });
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'),
              ),
            ],
          );
        });
  }

  // note: to delete a post , ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image from the storage
    storageRef.child("post_$postId.jpg").delete();
    // delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    // add a notification to the post owner's activity feed only if comment made by other user (to avoid notification from own)
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrls": mediaUrls,
        "originalPrice": originalPrice,
        "discountedPrice": discountedPrice,
        "category": category,
        "keywords": keywords,
        // "position": position,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // cachedNetworkImage(mediaUrls[0]),
          Stack(
            children: <Widget>[
              CarouselSlider(
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                height: 400.0,
                items: mediaUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(color: Colors.amber),
                        child: cachedNetworkImage(url),
                      );
                    },
                  );
                }).toList(),
              ),
              _discountPercentage == null || _discountPercentage < 40
                  ? Text('')
                  : Positioned(
                      top: 10.0,
                      left: 35.0,
                      child: Container(
                        color: Colors.redAccent,
                        padding: EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
                        child: Text(
                                'FAB DEAL!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                      ),
                    ),
            ],
          ),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red.withOpacity(0.6),
                    ),
                  ),
                )
              : Text("")
        ],
      ),
    );
  }

  buildPostFooter() {
    

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrls: mediaUrls,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            _discountPercentage == null
                ? Text('')
                : Row(
                    children: <Widget>[
                      Text('Price:',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Padding(padding: EdgeInsets.only(right: 5.0)),
                      Text(
                        '\$${_formattedDiscountedPrices.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Padding(padding: EdgeInsets.only(right: 5.0)),
                      Text(
                        '\$${_formattedOriginalPrices.toStringAsFixed(2)}',
                        style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red),
                      ),
                      Padding(padding: EdgeInsets.only(right: 10.0)),
                    ],
                  ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(description),
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, List<String> mediaUrls}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrls[0],
    );
  }));
}
