import 'package:flutter/material.dart';

class FreedomDmPageBehavior {
  final TextCapitalization textCapitalization = TextCapitalization.none;

  String? Function(BuildContext context, String key)? phrase;

  Future<void> Function(
    BuildContext context,
    String? channelId,
    String? userId,
  )? onChatPageInit;
}
