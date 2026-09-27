import 'package:neuro_app/core/widgets/messages/snackbars/snackbar_widget.dart';
import 'package:flutter/material.dart';
import '../../../resources/themes/extensions/success_colors.dart';

void showSuccessSnackbar({
  required BuildContext context,
  required String title,
  String? subtitle,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackbarWidget(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Theme.of(context).extension<SuccessColors>()!.success,
      icon: Icons.check_outlined,
    ).call(),
  );
}