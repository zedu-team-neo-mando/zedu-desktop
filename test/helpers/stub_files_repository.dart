import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A [FilesRepository] whose every method throws until a test overrides the
/// ones it needs.
///
/// The interface grows as the files feature does, and a fake that lists only
/// the methods one test uses stops compiling every time it does. Extending
/// this keeps each test fake to the methods it actually calls.
class StubFilesRepository implements FilesRepository {
  const StubFilesRepository();

  Never _unimplemented(String method) =>
      throw UnimplementedError('$method is not used by this test');

  @override
  Future<Result<FilesPage>> fetchFiles(FilesQuery query) =>
      _unimplemented('fetchFiles');

  @override
  Future<Result<FoldersPage>> fetchFolders({
    required FilesScope view,
    String? parentId,
    int page = 1,
  }) => _unimplemented('fetchFolders');

  @override
  Future<Result<WorkspaceFile>> uploadFile(XFile file) =>
      _unimplemented('uploadFile');

  @override
  Future<Result<void>> createFolder({
    required String name,
    required String orgId,
    String? parentId,
  }) => _unimplemented('createFolder');

  @override
  Future<Result<void>> downloadFile({
    required WorkspaceFile file,
    required String savePath,
    void Function(double? progress)? onProgress,
  }) => _unimplemented('downloadFile');

  @override
  Future<Result<void>> deleteFile(String fileId, {bool permanent = false}) =>
      _unimplemented('deleteFile');

  @override
  Future<Result<void>> renameFile(String fileId, String name) =>
      _unimplemented('renameFile');

  @override
  Future<Result<void>> moveFile(String fileId, String folderId) =>
      _unimplemented('moveFile');

  @override
  Future<Result<FileShareResult>> shareFile({
    required String fileId,
    required List<String> recipientIds,
    required FileSharePermission permission,
    required FileShareAccess access,
    String note = '',
  }) => _unimplemented('shareFile');

  @override
  Future<Result<Uint8List>> fetchFilePreview(
    WorkspaceFile file,
    FilePreviewKind kind,
  ) => _unimplemented('fetchFilePreview');

  @override
  Future<Result<WorkspaceFile>> fetchFileDetails(String fileId) =>
      _unimplemented('fetchFileDetails');

  @override
  Future<Result<Set<String>>> fetchPinnedFileIds() =>
      _unimplemented('fetchPinnedFileIds');

  @override
  Future<Result<void>> pinFile(String fileId) => _unimplemented('pinFile');

  @override
  Future<Result<void>> unpinFile(String fileId) => _unimplemented('unpinFile');

  @override
  Future<Result<void>> deleteFolder(String id) => _unimplemented('deleteFolder');
}
