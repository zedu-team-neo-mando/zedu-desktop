import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _SelectedOrg extends Notifier<String> {
  @override
  String build() => 'org-1';

  void select(String id) => state = id;
}

final _selectedOrgProvider = NotifierProvider<_SelectedOrg, String>(
  _SelectedOrg.new,
);

class _WorkspaceFilesRepository extends Fake implements FilesRepository {
  final String Function() currentOrg;
  final filesRequests = <String>[];
  final foldersRequests = <String>[];
  final pendingFiles = <String, Completer<Result<FilesPage>>>{};
  final pendingFolders = <String, Completer<Result<FoldersPage>>>{};
  bool deferResponses = false;

  _WorkspaceFilesRepository(this.currentOrg);

  @override
  Future<Result<FilesPage>> fetchFiles(FilesQuery query) async {
    final org = currentOrg();
    filesRequests.add(org);
    if (deferResponses) {
      return (pendingFiles[org] = Completer<Result<FilesPage>>()).future;
    }
    return Success(filesFor(org));
  }

  @override
  Future<Result<FoldersPage>> fetchFolders({
    required FilesScope view,
    String? parentId,
    int page = 1,
  }) async {
    final org = currentOrg();
    foldersRequests.add(org);
    if (deferResponses) {
      return (pendingFolders[org] = Completer<Result<FoldersPage>>()).future;
    }
    return Success(foldersFor(org));
  }

  FilesPage filesFor(String org) => FilesPage(
    files: [WorkspaceFile(id: '$org-file', name: '$org-file')],
  );

  FoldersPage foldersFor(String org) => FoldersPage(
    folders: [FileFolder(id: '$org-folder', name: '$org-folder')],
  );

  void complete(String org) {
    pendingFiles[org]!.complete(Success(filesFor(org)));
    pendingFolders[org]!.complete(Success(foldersFor(org)));
  }
}

void main() {
  late ProviderContainer container;
  late _WorkspaceFilesRepository repository;

  setUp(() {
    repository = _WorkspaceFilesRepository(
      () => container.read(_selectedOrgProvider),
    );
    container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWith(
          (ref) => ref.watch(_selectedOrgProvider),
        ),
        filesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  void listenToLists() {
    container.listen(filesListProvider, (_, _) {});
    container.listen(foldersListProvider, (_, _) {});
  }

  test(
    'loaded files and folders refetch even when the query stays equal',
    () async {
      listenToLists();
      await container.read(filesListProvider.future);
      await container.read(foldersListProvider.future);
      final query = container.read(filesProvider).query;
      expect(repository.filesRequests, ['org-1']);
      expect(repository.foldersRequests, ['org-1']);

      container.read(_selectedOrgProvider.notifier).select('org-2');
      final files = await container.read(filesListProvider.future);
      final folders = await container.read(foldersListProvider.future);

      expect(container.read(filesProvider).query, query);
      expect(repository.filesRequests, ['org-1', 'org-2']);
      expect(repository.foldersRequests, ['org-1', 'org-2']);
      expect(files.files.single.id, 'org-2-file');
      expect(folders.folders.single.id, 'org-2-folder');
    },
  );

  test(
    'late previous-workspace replies cannot replace the new lists',
    () async {
      repository.deferResponses = true;
      listenToLists();
      await pumpEventQueue();
      expect(repository.filesRequests, ['org-1']);
      expect(repository.foldersRequests, ['org-1']);

      container.read(_selectedOrgProvider.notifier).select('org-2');
      await pumpEventQueue();
      expect(repository.filesRequests, ['org-1', 'org-2']);
      expect(repository.foldersRequests, ['org-1', 'org-2']);
      repository.complete('org-2');
      await container.read(filesListProvider.future);
      await container.read(foldersListProvider.future);

      repository.complete('org-1');
      await pumpEventQueue();
      expect(
        container.read(filesListProvider).requireValue.files.single.id,
        'org-2-file',
      );
      expect(
        container.read(foldersListProvider).requireValue.folders.single.id,
        'org-2-folder',
      );
    },
  );
}
