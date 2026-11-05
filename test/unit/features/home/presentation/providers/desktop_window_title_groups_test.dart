import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

const _active = GroupDM(
  id: 'active',
  name: ' Launch team ',
  members: [],
  unreadCount: 7,
);
const _other = GroupDM(
  id: 'other',
  name: 'Design team',
  members: [],
  unreadCount: 3,
);

Future<ProviderContainer> _container({
  List<GroupDM> groups = const [_active, _other],
  ActiveChatType type = ActiveChatType.groupDm,
  String id = 'active',
}) async {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_Auth.new),
      workspaceProvider.overrideWith(_Workspace.new),
      activeChatProvider.overrideWith(() => _Active(type, id)),
      channelProvider.overrideWith(_Channels.new),
      dmListProvider.overrideWith(_Dms.new),
      groupDmProvider.overrideWith(() => _Groups(groups)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(desktopWindowTitleProvider, (_, _) {});
  await container.read(channelProvider.future);
  await container.read(dmListProvider.future);
  return container;
}

void main() {
  test(
    'named active group uses its trimmed name and excludes its own unread',
    () async {
      final container = await _container();
      expect(
        container.read(desktopWindowTitleProvider),
        '(3) Launch team · Zedu',
      );
    },
  );

  test('blank group name retains Group Chat fallback', () async {
    final container = await _container(groups: [_active.copyWith(name: '   ')]);
    expect(container.read(desktopWindowTitleProvider), 'Group Chat · Zedu');
  });

  test(
    'missing active group retains fallback and counts remaining groups',
    () async {
      final container = await _container(groups: const [_other]);
      expect(
        container.read(desktopWindowTitleProvider),
        '(3) Group Chat · Zedu',
      );
    },
  );

  test(
    'channel title includes unread messages from every inactive group',
    () async {
      final container = await _container(
        type: ActiveChatType.channel,
        id: 'general',
      );
      expect(container.read(desktopWindowTitleProvider), '(10) General · Zedu');
    },
  );

  test('direct message title also includes group unread counts', () async {
    final container = await _container(
      type: ActiveChatType.directMessage,
      id: 'friend',
    );
    expect(container.read(desktopWindowTitleProvider), '(10) Friend · Zedu');
  });

  test(
    'renaming the active group updates the title without switching chat',
    () async {
      final container = await _container();
      container
          .read(groupDmProvider.notifier)
          .renameGroupDm('active', 'Release team');
      expect(
        container.read(desktopWindowTitleProvider),
        '(3) Release team · Zedu',
      );
    },
  );

  test(
    'other-group unread changes update the prefix and zero removes it',
    () async {
      final container = await _container();
      final groups = container.read(groupDmProvider.notifier) as _Groups;
      groups.replace([_active, _other.copyWith(unreadCount: 5)]);
      expect(
        container.read(desktopWindowTitleProvider),
        '(5) Launch team · Zedu',
      );
      groups.replace([_active, _other.copyWith(unreadCount: 0)]);
      expect(container.read(desktopWindowTitleProvider), 'Launch team · Zedu');
    },
  );
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _Workspace extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(
      id: 'workspace',
      name: 'Acme',
      avatar: '',
      channelsCount: 0,
    ),
  );
}

class _Active extends ActiveChatNotifier {
  _Active(this.type, this.id);
  final ActiveChatType type;
  final String id;
  @override
  ActiveChatState build() => ActiveChatState(type: type, id: id);
}

class _Channels extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => const [];
}

class _Dms extends DmListNotifier {
  @override
  Future<List<DmConversation>> build() async => [
    DmConversation(
      channelId: 'dm',
      username: 'Friend',
      participantId: 'friend',
      previewMessage: '',
      unreadCount: 0,
    ),
  ];
}

class _Groups extends GroupDmNotifier {
  _Groups(this.initial);
  final List<GroupDM> initial;
  @override
  List<GroupDM> build() => initial;
  void replace(List<GroupDM> groups) => state = groups;
}
