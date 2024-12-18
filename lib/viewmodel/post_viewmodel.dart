import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/utils/navigation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/alert_dialog.dart';
import 'configuration_viewmodel.dart';

class PostVM extends ChangeNotifier {
  late AmityPost amityPost;
  late PagingController<AmityComment> controller;
  final amityComments = <AmityComment>[];

  final scrollcontroller = ScrollController();

  final AmityCommentSortOption _sortOption =
      AmityCommentSortOption.LAST_CREATED;

  void getPost(String postId, AmityPost initialPostData) {
    amityPost = initialPostData;
    AmitySocialClient.newPostRepository()
        .getPostStream(postId)
        .stream
        .asyncMap((event) async {
      final newPost = await AmityUIConfiguration.onCustomPost([event]);
      return newPost.first;
    }).listen((event) async {
      amityPost = event;
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void listenForComments(
      {required String postID, Function? successCallback, bool? refresh}) {
    if (refresh != null) {
      if (refresh) {
        amityComments.clear();
      }
    }
    controller = PagingController(
      pageFuture: (token) => AmitySocialClient.newCommentRepository()
          .getComments()
          .post(postID)
          .sortBy(_sortOption)
          .parentId(null)
          .includeDeleted(true)
          .getPagingData(token: token, limit: 20),
      pageSize: 20,
    )..addListener(
        () async {
          if (controller.error == null) {
            // Instead of clearing and re-adding all items, directly append new items
            // This assumes `amityComments` is a List that can be compared with controller.loadedItems for duplicates
            var newComments = controller.loadedItems;
            // Append only new comments
            var currentIds = amityComments.map((e) => e.commentId).toSet();
            var newItems = newComments
                .where((item) => !currentIds.contains(item.commentId))
                .toList();
            if (newItems.isNotEmpty) {
              final customComments =
                  await AmityUIConfiguration.onCustomComment(newItems);

              amityComments.addAll(customComments);
              successCallback?.call();
              notifyListeners(); // Uncomment if you are using a listener-based state management
            }
          } else {
            // Error on pagination controller
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: controller.error.toString());
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.fetchNextPage();
    });

    scrollcontroller.addListener(loadnextpage);
  }

  void loadnextpage() {
    if ((scrollcontroller.position.pixels ==
            scrollcontroller.position.maxScrollExtent) &&
        controller.hasMoreItems) {
      controller.fetchNextPage();
    }
  }

  Future<void> createComment(String postId, String text) async {
    // Dismiss the keyboard by removing focus from the current text field
    FocusScope.of(NavigationService.navigatorKey.currentContext!).unfocus();
    await AmitySocialClient.newCommentRepository()
        .createComment()
        .post(postId)
        .create()
        .text(text)
        .send()
        .then((comment) async {
      final customComments =
          await AmityUIConfiguration.onCustomComment([comment]);
      amityComments.insert(0, customComments.first);
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        scrollcontroller.jumpTo(0);
      });
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void flagComment(AmityComment comment, BuildContext context) {
    comment.report().flag().then((value) {
      AmitySuccessDialog.showTimedDialog("Success", context: context);
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void unFlagComment(AmityComment comment, BuildContext context) {
    comment.report().unflag().then((value) {
      AmitySuccessDialog.showTimedDialog("Success", context: context);
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> deleteComment(AmityComment comment) async {
    comment.delete().then((value) {
      // amityComments
      //     .removeWhere((element) => element.commentId == comment.commentId);
      getPost(amityPost.postId!, amityPost);
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void addCommentReaction(AmityComment comment) {
    HapticFeedback.heavyImpact();
    comment.react().addReaction('like').then((value) {});
  }

  void addPostReaction(AmityPost post) {
    HapticFeedback.heavyImpact();
    post.react().addReaction('like').then((value) => {
          //success
        });
  }

  void flagPost(AmityPost post) {
    post.report().flag().then((value) {
      AmitySuccessDialog.showTimedDialog("Report success");
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void unflagPost(AmityPost post) {
    post.report().unflag().then((value) {
      //success
      AmitySuccessDialog.showTimedDialog("Undo report success");
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void removePostReaction(AmityPost post) {
    HapticFeedback.heavyImpact();

    post.react().removeReaction('like').then((value) {
      // Handle success
    }).catchError((error) {
      // Handle error
    });
  }

  void removeCommentReaction(AmityComment comment) {
    HapticFeedback.heavyImpact();
    comment.react().removeReaction('like').then((value) => {
          //success
        });
  }

  bool isliked(AmityComment comment) {
    return comment.myReactions?.isNotEmpty ?? false;
  }

  void updateComment(AmityComment comment, String text) async {
    comment.edit().text(text).build().update().then((value) {
      //handle result
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }
}
