import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final filesRemoteDataSourceProvider = Provider<FilesRemoteDataSource>(
  (ref) => FilesRemoteDataSourceImpl(apiBaseService: locator<ApiBaseService>()),
);

final filesRepositoryProvider = Provider<FilesRepository>(
  (ref) => FilesRepositoryImpl(
    remoteDataSource: ref.watch(filesRemoteDataSourceProvider),
  ),
);

final filesProvider = NotifierProvider<FilesNotifier, FilesState>(
  FilesNotifier.new,
);

final filesListProvider = AsyncNotifierProvider<FilesListNotifier, FilesPage>(
  FilesListNotifier.new,
);

final foldersListProvider =
    AsyncNotifierProvider<FoldersListNotifier, FoldersPage>(
      FoldersListNotifier.new,
    );

final filesActionsProvider =
    NotifierProvider<FilesActionsNotifier, FilesActionsState>(
      FilesActionsNotifier.new,
    );

/// What the server knows about a file beyond its list entry, such as the
/// channels it was shared in. The list endpoint leaves that out.
final fileInfoProvider = FutureProvider.autoDispose
    .family<WorkspaceFileInfo, String>((ref, fileId) async {
      final result = await ref
          .watch(filesRepositoryProvider)
          .fetchFileInfo(fileId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw error,
      };
    });
