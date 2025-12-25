import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../Providers/FileTransferProvider.dart';
import '../Providers/SelectionProvider.dart';
import '../components/AppDrawer.dart';
import '../routes/file_transfer.dart';
import '../utils.dart';

/// Sort options for file listing
enum SortBy { name, size, date, type }

/// Controller for managing file explorer state
class FileExplorerController extends ChangeNotifier {
  Directory _currentDirectory;
  SortBy _sortBy = SortBy.name;
  bool _sortAscending = true;

  FileExplorerController(String initialPath)
      : _currentDirectory = Directory(initialPath);

  Directory get currentDirectory => _currentDirectory;
  String get currentPath => _currentDirectory.path;
  String get title => p.basename(_currentDirectory.path).isEmpty
      ? _currentDirectory.path
      : p.basename(_currentDirectory.path);

  Future<void> openDirectory(FileSystemEntity entity) async {
    if (entity is Directory) {
      _currentDirectory = entity;
      notifyListeners();
    }
  }

  Future<bool> goToParentDirectory() async {
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      _currentDirectory = parent;
      notifyListeners();
      return true;
    }
    return false;
  }

  void sortBy(SortBy sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    notifyListeners();
  }

  Future<List<FileSystemEntity>> listEntities() async {
    try {
      final entities = await _currentDirectory.list().toList();
      return _sortEntities(entities);
    } catch (e) {
      return [];
    }
  }

  List<FileSystemEntity> _sortEntities(List<FileSystemEntity> entities) {
    entities.sort((a, b) {
      // Directories first
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;

      int result;
      switch (_sortBy) {
        case SortBy.name:
          result = p.basename(a.path).toLowerCase().compareTo(
                p.basename(b.path).toLowerCase(),
              );
          break;
        case SortBy.type:
          result = p.extension(a.path).compareTo(p.extension(b.path));
          break;
        case SortBy.size:
        case SortBy.date:
          // These require async stat, so just sort by name
          result = p.basename(a.path).toLowerCase().compareTo(
                p.basename(b.path).toLowerCase(),
              );
          break;
      }
      return _sortAscending ? result : -result;
    });
    return entities;
  }
}

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  late FileExplorerController _controller;
  List<FileSystemEntity> _entities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    String initialPath;
    if (Platform.isAndroid) {
      initialPath = '/storage/emulated/0';
    } else if (Platform.isLinux || Platform.isMacOS) {
      initialPath = Platform.environment['HOME'] ?? '/';
    } else if (Platform.isWindows) {
      initialPath = Platform.environment['USERPROFILE'] ?? 'C:\\';
    } else {
      initialPath = '/';
    }

    _controller = FileExplorerController(initialPath);
    _controller.addListener(_refresh);
    await _loadEntities();
  }

  void _refresh() {
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entities = await _controller.listEntities();
      if (mounted) {
        setState(() {
          _entities = entities;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return !await _controller.goToParentDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        endDrawerEnableOpenDragGesture: true,
        appBar: _buildAppBar(context),
        floatingActionButton: _buildFAB(context),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(_controller.title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _controller.goToParentDirectory(),
      ),
      actions: [
        IconButton(
          onPressed: () => _showSortDialog(context),
          icon: const Icon(Icons.sort_rounded),
          tooltip: 'Sort',
        ),
        IconButton(
          onPressed: () => _showStorageDialog(context),
          icon: const Icon(Icons.sd_storage_rounded),
          tooltip: 'Storage',
        ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Consumer2<FileTransferProvider, SelectionProvider>(
      builder: (context, fileTransferProvider, selectionProvider, child) {
        if (selectionProvider.selectedFiles.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () {
            final files = selectionProvider.selectedFiles
                .map((path) => File(path))
                .toList();
            selectionProvider.clearSelection();

            if (files.isNotEmpty) {
              FileTransfer.instance.sendFiles(
                files,
                fileTransferProvider,
              );
            }
          },
          child: const Icon(Icons.send),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEntities,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_entities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('This folder is empty'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      itemCount: _entities.length,
      itemBuilder: (context, index) {
        final entity = _entities[index];
        return _FileListTile(
          entity: entity,
          onTap: () => _handleEntityTap(entity),
          onLongPress: () => _handleEntityLongPress(entity),
        );
      },
    );
  }

  void _handleEntityTap(FileSystemEntity entity) {
    final selectionProvider =
        Provider.of<SelectionProvider>(context, listen: false);

    if (entity is Directory) {
      if (selectionProvider.selectedFiles.isEmpty) {
        _controller.openDirectory(entity);
      } else {
        selectionProvider.toggleFileSelection(entity.path);
      }
    } else {
      selectionProvider.toggleFileSelection(entity.path);
    }
  }

  void _handleEntityLongPress(FileSystemEntity entity) {
    final selectionProvider =
        Provider.of<SelectionProvider>(context, listen: false);
    selectionProvider.toggleFileSelection(entity.path);
  }

  Future<void> _showSortDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort by'),
        children: [
          _sortOption('Name', SortBy.name),
          _sortOption('Size', SortBy.size),
          _sortOption('Date', SortBy.date),
          _sortOption('Type', SortBy.type),
        ],
      ),
    );
  }

  Widget _sortOption(String title, SortBy sortBy) {
    return SimpleDialogOption(
      onPressed: () {
        _controller.sortBy(sortBy);
        Navigator.pop(context);
      },
      child: Text(title),
    );
  }

  Future<void> _showStorageDialog(BuildContext context) async {
    final storageList = await _getStorageList();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Storage'),
        children: storageList.map((dir) {
          return SimpleDialogOption(
            onPressed: () {
              _controller.openDirectory(dir);
              Navigator.pop(context);
            },
            child: ListTile(
              leading: const Icon(Icons.sd_storage),
              title: Text(p.basename(dir.path).isEmpty ? dir.path : p.basename(dir.path)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<List<Directory>> _getStorageList() async {
    final List<Directory> storageList = [];

    if (Platform.isAndroid) {
      final primary = Directory('/storage/emulated/0');
      if (await primary.exists()) {
        storageList.add(primary);
      }
      // Try to find SD card
      final storage = Directory('/storage');
      if (await storage.exists()) {
        await for (var entity in storage.list()) {
          if (entity is Directory &&
              !entity.path.contains('emulated') &&
              !entity.path.contains('self')) {
            storageList.add(entity);
          }
        }
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        storageList.add(Directory(home));
      }
      storageList.add(Directory('/'));
    } else if (Platform.isWindows) {
      // Add common Windows drives
      for (var letter in ['C', 'D', 'E', 'F']) {
        final drive = Directory('$letter:\\');
        if (await drive.exists()) {
          storageList.add(drive);
        }
      }
    }

    return storageList;
  }
}

class _FileListTile extends StatelessWidget {
  final FileSystemEntity entity;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileListTile({
    required this.entity,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionProvider>(
      builder: (context, selectionProvider, child) {
        final isSelected = selectionProvider.isFileSelected(entity.path);
        final isDirectory = entity is Directory;
        final fileName = p.basename(entity.path);

        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: isSelected
                ? Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary, size: 40)
                : Icon(
                    isDirectory ? Icons.folder : _getFileIcon(fileName),
                    size: 40,
                    color: isDirectory ? Colors.amber : null,
                  ),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _FileSubtitle(entity: entity),
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mkv':
      case '.mov':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
        return Icons.audio_file;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      case '.apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _FileSubtitle extends StatelessWidget {
  final FileSystemEntity entity;

  const _FileSubtitle({required this.entity});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('');

        final stat = snapshot.data!;
        if (entity is File) {
          return Text(getFormattedFileSize(stat.size));
        }
        return Text(
          '${stat.modified.year}-${stat.modified.month.toString().padLeft(2, '0')}-${stat.modified.day.toString().padLeft(2, '0')}',
        );
      },
    );
  }
}
