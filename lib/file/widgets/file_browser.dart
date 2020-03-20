import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pedantic/pedantic.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/course/course.dart';

import '../bloc.dart';
import '../data.dart';
import 'app_bar.dart';
import 'file_tile.dart';
import 'upload_fab.dart';

class FileBrowser extends StatelessWidget {
  const FileBrowser(
    this.ownerId,
    this.parentId, {
    this.isEmbedded = false,
  })  : assert(ownerId != null),
        assert(isEmbedded != null);

  FileBrowser.myFiles(
    Id<File> parentId, {
    bool isEmbedded = false,
  }) : this(services.storage.userId, parentId, isEmbedded: isEmbedded);

  final Id<Entity> ownerId;
  bool get isOwnerCourse => ownerId is Id<Course>;
  bool get isOwnerMe => ownerId == services.storage.userId;
  final Id<File> parentId;

  /// Whether this widget is embedded into another screen. If true, doesn't
  /// show an app bar.
  final bool isEmbedded;

  void _openDirectory(BuildContext context, File file) {
    assert(file.isDirectory);

    if (isOwnerCourse) {
      context.navigator.pushNamed('/files/courses/$ownerId/${file.id}');
    } else if (isOwnerMe) {
      context.navigator.pushNamed('/files/my/${file.id}');
    } else {
      logger.e(
          'Unknown owner: $ownerId (type: ${ownerId.runtimeType}) while trying to open directory ${file.id}');
    }
  }

  Future<void> _downloadFile(BuildContext context, File file) async {
    assert(file.isActualFile);

    try {
      await services.get<FileBloc>().downloadFile(file);
      unawaited(services.snackBar
          .showMessage(context.s.file_fileBrowser_downloading(file.name)));
    } on PermissionNotGranted {
      context.scaffold.showSnackBar(SnackBar(
        content: Text(context.s.file_fileBrowser_download_storageAccess),
        action: SnackBarAction(
          label: context.s.file_fileBrowser_download_storageAccess_allow,
          onPressed: services.get<FileBloc>().ensureStoragePermissionGranted,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isEmbedded ? _buildEmbedded(context) : _buildStandalone(context);
  }

  Widget _buildEmbedded(BuildContext context) {
    return FancyCachedBuilder<List<File>>(
      controller: ownerId.files(parentId).controller,
      builder: (context, files, isFetching) {
        logger.w('Files were updated to $files');
        if (files?.isEmpty ?? true) {
          return _buildEmptyState(context);
        }
        return FileList(
          files: files,
          primary: false,
          onOpenDirectory: (directory) => _openDirectory(context, directory),
          onDownloadFile: (file) => _downloadFile(context, file),
        );
      },
    );
  }

  Widget _buildStandalone(BuildContext context) {
    FileBrowserAppBar buildLoadingErrorAppBar(
      dynamic error, [
      Color backgroundColor,
    ]) {
      return FileBrowserAppBar(
        title: error?.toString() ?? context.s.general_loading,
        backgroundColor: backgroundColor,
      );
    }

    Widget appBar;
    if (isOwnerCourse) {
      appBar = FancyCachedBuilder<Course>.handleLoading(
        controller: ownerId.controller,
        builder: (context, course, _) {
          if (parentId == null) {
            return FileBrowserAppBar(
              title: course.name,
              backgroundColor: course.color,
            );
          }

          return FancyCachedBuilder<File>.handleLoading(
            controller: parentId.controller,
            builder: (context, parentDirectory, _) {
              return FileBrowserAppBar(
                title: parentDirectory.name,
                backgroundColor: course.color,
              );
            },
          );
        },
      );
    } else if (parentId != null) {
      appBar = FancyCachedBuilder<File>.handleLoading(
        controller: parentId.controller,
        builder: (context, parent, _) => FileBrowserAppBar(title: parent.name),
      );
    } else if (isOwnerMe) {
      appBar = FileBrowserAppBar(title: context.s.file_files_my);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: AppBar().preferredSize,
        child: appBar,
      ),
      floatingActionButton: UploadFab(
        ownerId: ownerId,
        parentId: parentId,
      ),
      body: FancyCachedBuilder.list<File>(
        controller: ownerId.files(parentId).controller,
        emptyStateBuilder: (context, _) => _buildEmptyState(context),
        builder: (context, files, isFetching) {
          return FileList(
            files: files,
            onOpenDirectory: (directory) => _openDirectory(context, directory),
            onDownloadFile: (file) => _downloadFile(context, file),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateScreen(
      text: context.s.file_fileBrowser_empty,
      child: SizedBox(
        width: 100,
        height: 100,
        child: FlareActor(
          'assets/empty_states/files.flr',
          alignment: Alignment.center,
          fit: BoxFit.contain,
          animation: 'idle',
        ),
      ),
    );
  }
}

class FileList extends StatelessWidget {
  const FileList({
    Key key,
    @required this.files,
    @required this.onOpenDirectory,
    @required this.onDownloadFile,
    this.primary = true,
  })  : assert(files != null),
        assert(onOpenDirectory != null),
        assert(onDownloadFile != null),
        assert(primary != null),
        super(key: key);

  final List<File> files;
  final void Function(File directory) onOpenDirectory;
  final void Function(File file) onDownloadFile;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      primary: primary,
      shrinkWrap: !primary,
      itemBuilder: (context, index) {
        if (index < files.length) {
          final file = files[index];
          return FileTile(
            file: file,
            onOpen: file.isDirectory ? onOpenDirectory : onDownloadFile,
          );
        } else if (index == files.length) {
          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(16),
            child: Text(
              context.s.file_fileBrowser_totalCount(files.length),
              style: context.textTheme.caption,
            ),
          );
        }
        return null;
      },
    );
  }
}
