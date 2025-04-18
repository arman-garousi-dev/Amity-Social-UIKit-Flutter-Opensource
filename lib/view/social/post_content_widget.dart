import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/link_preview.dart';
import 'package:amity_uikit_beta_service/components/video_player.dart';
import 'package:amity_uikit_beta_service/view/social/global_feed.dart';
import 'package:amity_uikit_beta_service/view/social/imag_viewer.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:http/http.dart' as http;
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'image_viewer.dart';

class AmityPostWidget extends StatefulWidget {
  final List<AmityPost> posts;
  final bool isChildrenPost;
  final bool isCornerRadiusEnabled;
  final bool haveChildrenPost;
  final bool shouldShowTextPost;
  final FeedType feedType;

  const AmityPostWidget(
    this.posts,
    this.isChildrenPost,
    this.isCornerRadiusEnabled,
    this.feedType, {
    super.key,
    this.haveChildrenPost = false,
    this.shouldShowTextPost = true,
  });

  @override
  AmityPostWidgetState createState() => AmityPostWidgetState();
}

class AmityPostWidgetState extends State<AmityPostWidget> {
  List<String> imageURLs = [];
  String? videoUrl;
  bool isLoading = true;
  Map<String, PreviewData> datas = {};

  @override
  void initState() {
    super.initState();
    if (!widget.isChildrenPost) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      checkPostType();
    }
  }

  Future<void> checkPostType() async {
    switch (widget.posts[0].type) {
      case AmityDataType.IMAGE:
        await getImagePost();
        break;
      case AmityDataType.VIDEO:
        await getVideoPost();
        break;
      default:
        break;
    }
  }

  Future<void> getVideoPost() async {
    // final videoData = widget.posts[0].data as VideoData;

    // await videoData.getVideo(AmityVideoQuality.HIGH).then((AmityVideo video) {
    //   if (this.mounted) {
    //     setState(() {
    //       isLoading = false;
    //       videoUrl = video.fileUrl;
    //       log(">>>>>>>>>>>>>>>>>>>>>>>>${videoUrl}");
    //     });
    //   }
    // });
  }

  Future<void> getImagePost() async {
    List<String> imageUrlList = [];

    for (var post in widget.posts) {
      final imageData = post.data as ImageData;
      final largeImageUrl = imageData.getUrl(AmityImageSize.LARGE);

      imageUrlList.add(largeImageUrl);
    }
    if (mounted) {
      setState(() {
        isLoading = false;
        imageURLs = imageUrlList;
      });
    }
  }

  bool urlValidation(AmityPost post) {
    final url = extractLink(post); //urlExtraction(post);

    return AnyLinkPreview.isValidLink(url);
  }

  String extractLink(AmityPost post) {
    final textdata = post.data as TextData;
    final text = textdata.text ?? "";
    var elements = linkify(text,
        options: const LinkifyOptions(
          humanize: false,
          defaultToHttps: true,
        ));
    for (var e in elements) {
      if (e is LinkableElement) {
        return e.url;
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isChildrenPost) {
      if (widget.posts[0].children != null && urlValidation(widget.posts[0])) {
        return TextPost(post: widget.posts[0], feedType: widget.feedType);
      } else {
        String url =
            extractLink(widget.posts[0]); //urlExtraction(widget.posts[0]);

        return Column(
          children: [
            // Text(url),
            widget.shouldShowTextPost
                ? TextPost(post: widget.posts[0], feedType: widget.feedType)
                : Container(),

            !urlValidation(widget.posts[0])
                ? const SizedBox()
                : CustomLinkPreview(
                    url: url.toLowerCase(),
                  )
          ],
        );
      }
    } else {
      switch (widget.posts[0].type) {
        case AmityDataType.IMAGE:
          return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0), // Add border radius
              ),
              child: _buildMediaGrid(widget.posts));
        case AmityDataType.VIDEO:
          return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0), // Add border radius
              ),
              child: _buildVideoGrid(widget.posts));

        case AmityDataType.FILE:
          return _listMediaGrid(widget.posts);
        default:
          return Container();
      }
    }
  }

  Widget _buildVideoGrid(List<AmityPost> files) {
    if (files.isEmpty) return Container();

    Widget backgroundThumbnail(String fileUrl, int index,
        {BorderRadius? borderRadius}) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                image: DecorationImage(
                  image: NetworkImage(fileUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow,
                size: 70.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    String getURL(AmityPostData postData) {
      if (postData is VideoData) {
        var data = postData;

        return data.thumbnail?.getUrl(AmityImageSize.LARGE) ?? "";
      } else if (postData is ImageData) {
        var data = postData;
        return data.image?.getUrl(AmityImageSize.LARGE) ?? "";
      } else {
        return "";
      }
    }

    switch (files.length) {
      case 1:
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  files: files,
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: backgroundThumbnail(getURL(files[0].data!), 0,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8))),
          ),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      files: files,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: backgroundThumbnail(getURL(files[0].data!), 0,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8))),
            )),
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      files: files,
                      initialIndex: 1,
                    ),
                  ),
                );
              },
              child: backgroundThumbnail(getURL(files[1].data!), 1,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )),
            ))
          ]),
        );

      case 3:
        return AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          files: files,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: backgroundThumbnail(getURL(files[0].data!), 0,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                        child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: backgroundThumbnail(getURL(files[1].data!), 1,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          )),
                    )),
                    Expanded(
                        child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 2,
                            ),
                          ),
                        );
                      },
                      child: backgroundThumbnail(getURL(files[2].data!), 2,
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(8))),
                    )),
                  ],
                ),
              ),
            ],
          ),
        );

      case 4:
        return AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        files: files,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: backgroundThumbnail(getURL(files[0].data!), 0,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                    )),
              )),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundThumbnail(getURL(files[1].data!), 1,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 2,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundThumbnail(getURL(files[2].data!), 2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 3,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundThumbnail(getURL(files[3].data!), 3,
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        return AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        files: files,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: backgroundThumbnail(getURL(files[0].data!), 0,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    )),
              )),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundThumbnail(getURL(files[1].data!), 1,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 2,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundThumbnail(getURL(files[2].data!), 2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              files: files,
                              initialIndex: 3,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            backgroundThumbnail(getURL(files[3].data!), 3,
                                borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(8))),
                            // Black filter overlay
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(0.3), // Semi-transparent black
                              ),
                            ),
                            // Centered Text "6+"
                            Center(
                              child: Text(
                                "${files.length - 3}+",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      24, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMediaGrid(List<AmityPost> files) {
    if (files.isEmpty) return Container();

    Widget backgroundImage(String fileUrl, int index,
        {BorderRadius? borderRadius}) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            image: DecorationImage(
              image: NetworkImage(fileUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    String getURL(AmityPostData postData) {
      if (postData is VideoData) {
        var data = postData;
        return data.thumbnail?.getUrl(AmityImageSize.MEDIUM) ?? "";
      } else if (postData is ImageData) {
        var data = postData;
        return data.image?.getUrl(AmityImageSize.MEDIUM) ?? "";
      } else {
        return "";
      }
    }

    Widget buildSingleImage(List<AmityPost> files) {
      return AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(
                  files: files,
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: backgroundImage(getURL(files[0].data!), 0,
              borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    Widget buildTwoImages(List<AmityPost> files) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(
                    files: files,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: backgroundImage(getURL(files[0].data!), 0,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8))),
          )),
          Expanded(
              child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(
                    files: files,
                    initialIndex: 1,
                  ),
                ),
              );
            },
            child: backgroundImage(getURL(files[1].data!), 1,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8))),
          ))
        ]),
      );
    }

    Widget buildThreeImages(List<AmityPost> files) {
      return AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      files: files,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: backgroundImage(getURL(files[0].data!), 0,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))),
            )),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            files: files,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: backgroundImage(getURL(files[1].data!), 1,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8))),
                  )),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            files: files,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: backgroundImage(getURL(files[2].data!), 2,
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8))),
                  )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFourImages(List<AmityPost> files) {
      return AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      files: files,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: backgroundImage(getURL(files[0].data!), 0,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))),
            )),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            files: files,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(files[1].data!), 1,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            files: files,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(files[2].data!), 2),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            files: files,
                            initialIndex: 3,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(files[3].data!), 3,
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(8))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildDefaultImage(List<AmityPost> files) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(8.0), // Border radius for the entire grid
            // Add other properties like a border or shadow if needed
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        files: files,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: backgroundImage(getURL(files[0].data!), 0,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8))),
              )),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              files: files,
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundImage(getURL(files[1].data!), 1,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              files: files,
                              initialIndex: 2,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundImage(getURL(files[2].data!), 2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              files: files,
                              initialIndex: 3,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            backgroundImage(getURL(files[3].data!), 3,
                                borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(8))),
                            // Black filter overlay
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(0.3), // Semi-transparent black
                              ),
                            ),
                            // Centered Text "6+"
                            Center(
                              child: Text(
                                "${files.length - 3}+",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      24, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    switch (files.length) {
      case 1:
        return buildSingleImage(files);
      case 2:
        return buildTwoImages(files);
      case 3:
        return buildThreeImages(files);
      case 4:
        return buildFourImages(files);
      default:
        return buildDefaultImage(files);
    }
  }
}

String _getFileImage(String filePath) {
  String extension = filePath.split('.').last;
  switch (extension) {
    case 'audio':
      return 'assets/images/fileType/audio_large.png';
    case 'avi':
      return 'assets/images/fileType/avi_large.png';
    case 'csv':
      return 'assets/images/fileType/csv_large.png';
    case 'doc':
      return 'assets/images/fileType/doc_large.png';
    case 'exe':
      return 'assets/images/fileType/exe_large.png';
    case 'html':
      return 'assets/images/fileType/html_large.png';
    case 'img':
      return 'assets/images/fileType/img_large.png';
    case 'mov':
      return 'assets/images/fileType/mov_large.png';
    case 'mp3':
      return 'assets/images/fileType/mp3_large.png';
    case 'mp4':
      return 'assets/images/fileType/mp4_large.png';
    case 'pdf':
      return 'assets/images/fileType/pdf_large.png';
    case 'ppx':
      return 'assets/images/fileType/ppx_large.png';
    case 'rar':
      return 'assets/images/fileType/rar_large.png';
    case 'txt':
      return 'assets/images/fileType/txt_large.png';
    case 'xls':
      return 'assets/images/fileType/xls_large.png';
    case 'zip':
      return 'assets/images/fileType/zip_large.png';
    default:
      return 'assets/images/fileType/default.png';
  }
}

Widget _listMediaGrid(List<AmityPost> files) {
  return ListView.builder(
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: files.length,
    shrinkWrap: true,
    itemBuilder: (context, index) {
      String fileImage = _getFileImage(files[index].data!.fileInfo.fileName!);

      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color:
                Provider.of<AmityUIConfiguration>(context).appColors.baseShade4,
            width: 1.0,
          ),
        ),
        margin: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            ListTile(
              onTap: () {
                _launchUrl(
                  files[index].data!.fileInfo.fileUrl!,
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              // Reduced padding
              tileColor: Colors.white.withOpacity(0.0),
              leading: Container(
                height: 100, // Reduced height to make it slimmer
                width: 40, // Added width to align the image
                alignment:
                    Alignment.centerLeft, // Center alignment for the image
                child: Image(
                  image: AssetImage(fileImage,
                      package: 'amity_uikit_beta_service'),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Reduce extra space
                children: [
                  Text(
                    "${files[index].data!.fileInfo.fileName}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${(files[index].data!.fileInfo.fileSize)} KB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}

class TextPost extends StatefulWidget {
  final AmityPost post;
  final FeedType feedType;

  const TextPost({Key? key, required this.post, required this.feedType})
      : super(key: key);

  @override
  _TextPostState createState() => _TextPostState();
}

class _TextPostState extends State<TextPost> {
  bool isExpanded = false;

  Future<void> _onOpenLink(LinkableElement link) async {
    if (await canLaunchUrl(Uri.parse(link.url))) {
      await launchUrl(Uri.parse(link.url));
    } else {
      throw 'Could not launch $link';
    }
  }

  List<TextSpan> _buildTextSpans(
      String text, TextStyle textStyle, TextStyle linkStyle) {
    final elements = linkify(text);

    return elements.map((element) {
      if (element is LinkableElement) {
        return TextSpan(
          text: element.text,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _onOpenLink(element),
        );
      } else {
        return TextSpan(
          text: element.text,
          style: textStyle,
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textData = widget.post.data as TextData;
    final String text = textData.text ?? "";
    final bool shouldShorten = text.length > 180 && !isExpanded;

    TextStyle textStyle = TextStyle(
      color: Provider.of<AmityUIConfiguration>(context).appColors.base,
      fontSize: 12,
    );
    TextStyle linkStyle = TextStyle(
      color: Provider.of<AmityUIConfiguration>(context, listen: false)
          .appColors
          .primary,
      fontSize: 12,
      height: 45 / 12,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                children: [
                  widget.post.type == AmityDataType.TEXT && text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: shouldShorten
                              ? RichText(
                                  text: TextSpan(
                                    children: [
                                      ..._buildTextSpans(
                                        text.substring(0, 180),
                                        textStyle,
                                        linkStyle,
                                      ),
                                      TextSpan(
                                        text: " ... Load more",
                                        style: linkStyle,
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            setState(() {
                                              isExpanded = true;
                                            });
                                          },
                                      ),
                                    ],
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    if (text.length > 180) {
                                      setState(() {
                                        isExpanded = false;
                                      });
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: _buildTextSpans(
                                        text,
                                        textStyle,
                                        linkStyle,
                                      ),
                                    ),
                                  ),
                                ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ImagePost extends StatelessWidget {
  final List<AmityPost> posts;
  final List<String> imageURLs;
  final bool isCornerRadiusEnabled;

  const ImagePost({
    Key? key,
    required this.posts,
    required this.imageURLs,
    required this.isCornerRadiusEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 250.0,
        disableCenter: false,
        enableInfiniteScroll: imageURLs.length > 1,
        viewportFraction: imageURLs.length > 1 ? 0.9 : 1.0,
      ),
      items: imageURLs.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(_goToImageViewer(url));
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(
                    horizontal: imageURLs.length > 1 ? 5.0 : 0.0),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(isCornerRadiusEnabled ? 10 : 0),
                    child: FadeInImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                      placeholder: const AssetImage(
                          'assets/images/placeholder.png'), // Local asset for placeholder
                    )),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Route _goToImageViewer(String url) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ImageViewer(
          imageURLs: imageURLs, initialIndex: imageURLs.indexOf(url)),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

Future<Uint8List?> downloadFile(String url) async {
  try {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
