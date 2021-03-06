import 'package:flutter_deep_linking/flutter_deep_linking.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';

import 'data.dart';
import 'widgets/file_browser.dart';
import 'widgets/files_screen.dart';
import 'widgets/page_route.dart';

Route _buildSubdirRoute(Id<Entity> Function(RouteResult result) ownerGetter) {
  return Route(
    matcher: Matcher.path('{parentId}'),
    builder: (result) => FileBrowserPageRoute(
      builder: (_) => FileBrowser(FilePath(
        ownerGetter(result),
        Id<File>(result['parentId']),
      )),
      settings: result.settings,
    ),
  );
}

final fileRoutes = Route(
  matcher: Matcher.path('files'),
  materialBuilder: (_, __) => FilesScreen(),
  routes: [
    Route(
      matcher: Matcher.path('my'),
      builder: (result) => FileBrowserPageRoute(
        builder: (_) => FileBrowser(FilePath(services.storage.userId)),
        settings: result.settings,
      ),
      routes: [
        _buildSubdirRoute((_) => services.storage.userId),
      ],
    ),
    Route(
      matcher: Matcher.path('courses'),
      materialBuilder: (_, __) => FilesScreen(),
      routes: [
        Route(
          matcher: Matcher.path('{courseId}'),
          builder: (result) => FileBrowserPageRoute(
            builder: (_) =>
                FileBrowser(FilePath(Id<Course>(result['courseId']))),
            settings: result.settings,
          ),
          routes: [
            _buildSubdirRoute((result) => Id<Course>(result['courseId'])),
          ],
        ),
      ],
    ),
  ],
);
