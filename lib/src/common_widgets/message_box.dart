import 'package:flutter/material.dart';

/// Shows a simple alert dialog instead of using window.alert() or alert().
/// This function is used to display messages/errors/success notices to the user.
void showMessageBox(BuildContext context, {required String title, required String content}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}