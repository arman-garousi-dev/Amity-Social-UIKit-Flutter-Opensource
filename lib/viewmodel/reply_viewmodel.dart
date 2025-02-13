import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/viewmodel/post_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'configuration_viewmodel.dart';

class ReplyTo {
  ReplyTo(this._replyToComment, this._replyingToUser);
  AmityUser _replyingToUser;

  AmityUser get replyingToUser => _replyingToUser;

  set replyingToUser(AmityUser value) {
    _replyingToUser = value;
  }

  AmityComment _replyToComment;

  AmityComment get replyToComment => _replyToComment;

  set replyToComment(AmityComment value) {
    _replyToComment = value;
  }
}

class ReplyVM extends PostVM {
  // Maps a comment ID to a list of its replies
  final Map<String, List<AmityComment>> amityReplyCommentsMap = {};

  // Maps a comment ID to its corresponding paging controller
  late final Map<String, PagingController<AmityComment>> _controllersMap = {};

  final AmityCommentSortOption _sortOption =
      AmityCommentSortOption.FIRST_CREATED;

  ReplyTo? replyToObject;

  Future<void> initReplyComment(String postId, BuildContext context) async {
    _controllersMap.clear();
    amityReplyCommentsMap.clear();
    replyToObject = null;

    var comments = Provider.of<PostVM>(context, listen: false).amityComments;
    for (var comment in comments) {
      // Check if the comment ID does not exist in the amityReplyCommentsMap
      await listenForReplyComments(
          postID: postId, commentId: comment.commentId!);
    }
  }

  void selectReplyComment({required AmityComment comment}) {
    replyToObject = ReplyTo(comment, comment.user!);
    notifyListeners();
  }

  void clearReply() {
    replyToObject = null;
  }

  void clearReplyAndUpdateUI() {
    replyToObject = null;
    notifyListeners();
  }

// Listens for reply comments asynchronously and updates the UI upon receiving new data or an error.
  Future<void> listenForReplyComments({
    required String postID,
    required String commentId,
  }) async {
    // Check if the comments for the given commentId already exist to append new comments instead of clearing the list.
    final amityComments = amityReplyCommentsMap[commentId] ?? <AmityComment>[];

    _controllersMap[commentId] = PagingController(
      pageFuture: (token) async =>
          await AmitySocialClient.newCommentRepository()
              .getComments()
              .post(postID)
              .parentId(commentId)
              .sortBy(_sortOption)
              .includeDeleted(true)
              .getPagingData(token: token, limit: 5),
      pageSize: 5,
    )..addListener(
        () async {
          if (_controllersMap[commentId]!.error == null) {
            var loadedItems = _controllersMap[commentId]!.loadedItems;

            // Append only new comments by checking against existing ones.
            var currentIds = amityComments.map((e) => e.commentId).toSet();
            var newItems = loadedItems
                .where((item) => !currentIds.contains(item.commentId))
                .toList();
            if (newItems.isNotEmpty) {
              final newPost =
                  await AmityUIConfiguration.onCustomComment(newItems);
              amityComments.addAll(newPost);
              amityReplyCommentsMap[commentId] = amityComments;
            }
            notifyListeners();
          } else {
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!",
            //     message: _controllersMap[commentId]!.error.toString());
          }
        },
      );

    // Immediately fetch the next page of comments to start populating the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllersMap[commentId]!.fetchNextPage();
    });
  }

  bool replyHaveNextPage(String commentId) {
    if (_controllersMap[commentId] != null) {
      if (_controllersMap[commentId]!.isFetching) {
        return false;
      } else {
        if (_controllersMap[commentId]!.loadedItems.isNotEmpty) {
          return _controllersMap[commentId]!.hasMoreItems;
        } else {
          return false;
        }
      }
    } else {
      return false;
    }
  }

  void loadReplynextpage(
    String commentId,
  ) {
    if (_controllersMap[commentId] != null) {
      _controllersMap[commentId]!.fetchNextPage();
      notifyListeners();
    } else {}
  }

  @override
  Future<void> deleteComment(AmityComment comment) async {
    comment.delete().then((value) {
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> createReplyComment(
      {required String postId,
      required String commentId,
      required String text}) async {
    await AmitySocialClient.newCommentRepository()
        .createComment()
        .post(postId)
        .parentId(commentId)
        .create()
        .text(text)
        .send()
        .then((comment) async {
      // _controller.add(comment);
      // Clear existing comments and add newly loaded items.
      if (amityReplyCommentsMap[commentId] == null) {
        amityReplyCommentsMap[commentId] = [];
      }
      // Update the map of reply comments and notify listeners to update the UI.
      amityReplyCommentsMap[commentId]!.add(comment);
      notifyListeners();
      replyToObject = null;
      // Future.delayed(const Duration(milliseconds: 300)).then((value) {
      //   scrollcontroller.jumpTo(scrollcontroller.position.maxScrollExtent);
      // });
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }
}
