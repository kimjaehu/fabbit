import 'package:fabbit/widgets/custom_image.dart';
import 'package:fabbit/widgets/post.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print('show full post'),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
