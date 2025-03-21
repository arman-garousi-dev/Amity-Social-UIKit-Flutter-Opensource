import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:flutter/material.dart';

import 'configuration_viewmodel.dart';

class FollowerVM extends ChangeNotifier {
  var _followerList = <AmityFollowRelationship>[];
  List<AmityFollowRelationship> get getFollowerList => _followerList;

  var _followingList = <AmityFollowRelationship>[];
  List<AmityFollowRelationship> get getFollowingList => _followingList;

  ScrollController? followingScrollController;

  ScrollController? followerScrollController;

  late PagingController<AmityFollowRelationship> _followerController;

  late PagingController<AmityFollowRelationship> _followingController;

  Future<void> getFollowingListof({required String userId}) async {
    if (AmityCoreClient.getUserId() == userId) {
      _followingController = PagingController(
        pageFuture: (token) => AmityCoreClient.newUserRepository()
            .relationship()
            .getMyFollowers()
            .status(AmityFollowStatusFilter.ACCEPTED)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(listener);
    } else {
      _followingController = PagingController(
        pageFuture: (token) => AmityCoreClient.newUserRepository()
            .relationship()
            .getFollowings(userId)
            .status(AmityFollowStatusFilter.ACCEPTED)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(listener);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _followingController.fetchNextPage();
    });

    if (followingScrollController != null) {
      _followingController.addListener((() {
        if ((followingScrollController!.position.pixels ==
                followingScrollController!.position.maxScrollExtent) &&
            _followingController.hasMoreItems) {
          _followingController.fetchNextPage();
        }
      }));
    }

    //inititate the PagingController
    if (AmityCoreClient.getUserId() == userId) {
      await AmityCoreClient.newUserRepository()
          .relationship()
          .me()
          .getFollowings()
          .status(AmityFollowStatusFilter.ACCEPTED)
          .getPagingData()
          .then((value) async {
        var customFollowings =
            await AmityUIConfiguration.onCustomFollow(value.data);
        _followingList = customFollowings;
        // _followingList = value.data;
      }).onError((error, stackTrace) {
        AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    } else {
      await AmityCoreClient.newUserRepository()
          .relationship()
          .user(userId)
          .getFollowings()
          .status(AmityFollowStatusFilter.ACCEPTED)
          .getPagingData()
          .then((value) async {
        followingScrollController = ScrollController();
        var customFollowings =
            await AmityUIConfiguration.onCustomFollow(value.data);
        _followingList = customFollowings;
        // _followingList = value.data;
      }).onError((error, stackTrace) {
        AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    }
    notifyListeners();
  }

  Future<void> getFollowerListOf({
    required String userId,
  }) async {
    if (AmityCoreClient.getUserId() == userId) {
      _followerController = PagingController(
        pageFuture: (token) => AmityCoreClient.newUserRepository()
            .relationship()
            .me()
            .getFollowers()
            .status(AmityFollowStatusFilter.ACCEPTED)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(listener);
    } else {
      _followerController = PagingController(
        pageFuture: (token) => AmityCoreClient.newUserRepository()
            .relationship()
            .user(userId)
            .getFollowers()
            .status(AmityFollowStatusFilter.ACCEPTED)
            .getPagingData(token: token, limit: 20),
        pageSize: 20,
      )..addListener(listener);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _followerController.fetchNextPage();
    });

    if (followerScrollController != null) {
      _followerController.addListener((() {
        if ((followerScrollController!.position.pixels ==
                followerScrollController!.position.maxScrollExtent) &&
            _followerController.hasMoreItems) {
          _followerController.fetchNextPage();
        }
      }));
    }

    //inititate the PagingController
    if (AmityCoreClient.getUserId() == userId) {
      await AmityCoreClient.newUserRepository()
          .relationship()
          .me()
          .getFollowers()
          .status(AmityFollowStatusFilter.ACCEPTED)
          .getPagingData()
          .then((value) async {
        var customFollowers =
            await AmityUIConfiguration.onCustomFollower(value.data);
        _followerList = customFollowers;

        // _followerList = value.data;
      }).onError((error, stackTrace) {
        AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    } else {
      await AmityCoreClient.newUserRepository()
          .relationship()
          .user(userId)
          .getFollowers()
          .status(AmityFollowStatusFilter.ACCEPTED)
          .getPagingData()
          .then((value) async {
        followerScrollController = ScrollController();
        var customFollowers =
            await AmityUIConfiguration.onCustomFollower(value.data);
        _followerList = customFollowers;
        // _followerList = value.data;
      }).onError((error, stackTrace) {
        AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    }
    notifyListeners();
  }

  void followButtonAction(AmityUser user, AmityFollowStatus amityFollowStatus) {
    if (amityFollowStatus == AmityFollowStatus.NONE) {
      sendFollowRequest(user: user);
    } else if (amityFollowStatus == AmityFollowStatus.PENDING) {
      withdrawFollowRequest(user);
    } else if (amityFollowStatus == AmityFollowStatus.ACCEPTED) {
      withdrawFollowRequest(user);
    } else {
      AmityDialog().showAlertErrorDialog(
          title: "Error!",
          message: "followButtonAction: cant handle amityFollowStatus");
    }
  }

  Future<void> sendFollowRequest({required AmityUser user}) async {
    AmityCoreClient.newUserRepository()
        .relationship()
        .user(user.userId!)
        .follow()
        .then((AmityFollowStatus followStatus) {
      //success
      notifyListeners();
    }).onError((error, stackTrace) {
      //handle error
      AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void withdrawFollowRequest(AmityUser user) {
    AmityCoreClient.newUserRepository()
        .relationship()
        .me()
        .unfollow(user.userId!)
        .then((value) {
      notifyListeners();
    }).onError((error, stackTrace) {
      AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> getPendingRequest() async {}

  Future<void> acceptFollowRequest(
      {required AmityFollowRelationship amityFollowRelationship}) async {}

  Future<void> rejectFollowRequest(
      {required AmityFollowRelationship amityFollowRelationship}) async {}

  Function listener() {
    return () async {
      if (_followerController.error == null) {
        //handle _followerController, we suggest to clear the previous items
        //and add with the latest _controller.loadedItems
        var customFollowers =
            await AmityUIConfiguration.onCustomFollower(_followerList);
        _followerList = customFollowers;
        _followerList.clear();

        _followerList.addAll(customFollowers);
        //update widgets
      } else {
        //error on pagination controller
        //update widgets
      }
    };
  }
}
