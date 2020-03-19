import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pedantic/pedantic.dart';
import 'package:schulcloud/app/app.dart';

import 'widgets/sign_in_screen.dart';

Future<bool> signOut(BuildContext context) async {
  logger.i('Signing out…');

  final s = context.s;
  final confirmed = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(s.app_signOut_title),
        content: Text(s.app_signOut_content),
        actions: <Widget>[
          FlatButton(
            onPressed: () => context.navigator.pop(false),
            child: Text(s.general_cancel),
          ),
          FlatButton(
            onPressed: () => context.navigator.pop(true),
            child: Text(s.general_signOut),
          ),
        ],
      );
    },
  );

  if (confirmed) {
    // Actually log out.

    await services.api.delete('authentication');
    await CookieManager().deleteAllCookies();
    // This should probably be awaited, but right now awaiting it
    // leads to the issue that logging out becomes impossible.
    await services.storage.clear();

    final navigator = context.rootNavigator..popUntil((route) => route.isFirst);
    unawaited(navigator.pushReplacement(TopLevelPageRoute(
      builder: (_) => SignInScreen(),
    )));
  }

  logger.i('Signed out!');
  return confirmed;
}
