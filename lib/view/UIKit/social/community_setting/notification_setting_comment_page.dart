import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/theme_config.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum NotificationSetting { everyone, onlyModerator, off }

class CommentsNotificationSettingPage extends StatefulWidget {
  final AmityCommunity community;

  const CommentsNotificationSettingPage({Key? key, required this.community})
      : super(key: key);

  @override
  _CommentsNotificationSettingPageState createState() =>
      _CommentsNotificationSettingPageState();
}

class _CommentsNotificationSettingPageState
    extends State<CommentsNotificationSettingPage> {
  NotificationSetting _reactCommentsSetting = NotificationSetting.everyone;
  NotificationSetting _newCommentsSetting = NotificationSetting.everyone;
  NotificationSetting _repliesSetting = NotificationSetting.everyone;

  @override
  Widget build(BuildContext context) {
    return ThemeConfig(
      child: Scaffold(
        backgroundColor:
            Provider.of<AmityUIConfiguration>(context).appColors.baseBackground,
        appBar: AppBar(
          title: Text(
            'Comments',
            style: TextStyle(
              color: Provider.of<AmityUIConfiguration>(context).appColors.base,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: ListView(
          children: [
            // Section 1: React Comments
            _buildSectionHeader('React Comments'),
            _buildDescriptionTile(
                'Receive notifications when someone likes your comment in this community'),
            _buildRadioTile<NotificationSetting>(
              title: 'Everyone',
              value: NotificationSetting.everyone,
              groupValue: _reactCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _reactCommentsSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Only Moderator',
              value: NotificationSetting.onlyModerator,
              groupValue: _reactCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _reactCommentsSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Off',
              value: NotificationSetting.off,
              groupValue: _reactCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _reactCommentsSetting = value!;
                });
              },
            ),
            const Divider(),

            // Section 2: New Comments
            _buildSectionHeader('New Comments'),
            _buildDescriptionTile(
                'Receive notifications when someone comments on your posts in this community'),
            _buildRadioTile<NotificationSetting>(
              title: 'Everyone',
              value: NotificationSetting.everyone,
              groupValue: _newCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _newCommentsSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Only Moderator',
              value: NotificationSetting.onlyModerator,
              groupValue: _newCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _newCommentsSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Off',
              value: NotificationSetting.off,
              groupValue: _newCommentsSetting,
              onChanged: (value) {
                setState(() {
                  _newCommentsSetting = value!;
                });
              },
            ),
            const Divider(),

            // Section 3: Replies
            _buildSectionHeader('Replies'),
            _buildDescriptionTile(
                'Receive notifications when someone replies to your comments in this community'),
            _buildRadioTile<NotificationSetting>(
              title: 'Everyone',
              value: NotificationSetting.everyone,
              groupValue: _repliesSetting,
              onChanged: (value) {
                setState(() {
                  _repliesSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Only Moderator',
              value: NotificationSetting.onlyModerator,
              groupValue: _repliesSetting,
              onChanged: (value) {
                setState(() {
                  _repliesSetting = value!;
                });
              },
            ),
            _buildRadioTile<NotificationSetting>(
              title: 'Off',
              value: NotificationSetting.off,
              groupValue: _repliesSetting,
              onChanged: (value) {
                setState(() {
                  _repliesSetting = value!;
                });
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Provider.of<AmityUIConfiguration>(context).appColors.base),
      ),
    );
  }

  Widget _buildDescriptionTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 16, right: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xff636878),
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>(
      {required String title,
      required T value,
      required T groupValue,
      required void Function(T?) onChanged}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            color: Provider.of<AmityUIConfiguration>(context).appColors.base),
      ),
      trailing: Radio<T>(
        focusColor: Provider.of<AmityUIConfiguration>(context).primaryColor,
        activeColor: Provider.of<AmityUIConfiguration>(context).primaryColor,
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
    );
  }
}
