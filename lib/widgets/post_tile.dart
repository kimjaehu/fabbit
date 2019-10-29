import 'package:fabbit/pages/post_screen.dart';
import 'package:fabbit/widgets/custom_image.dart';
import 'package:fabbit/widgets/post.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostScreen(
            postId: post.postId,
            userId: post.ownerId,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    

    // return GestureDetector(
    //     onTap: () => showPost(context),
    //     child: Stack(
    //       alignment: Alignment.center,
    //       children: <Widget>[
    //         Stack(
    //           children: <Widget>[
    //             cachedNetworkImage(post.mediaUrls[0]),
    //           ],
    //         ),
    //       ],
    //     ));
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrls[0]),
      
    );
  }
}
