import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/reading_group.dart';
import '../../domain/entities/reading_progress.dart';
import '../providers/auth_providers.dart';
import '../providers/challenge_providers.dart';
import '../providers/core_providers.dart';
import '../providers/reading_progress_providers.dart';
import '../widgets/common_views.dart';
import 'group_detail_page.dart';

class ChallengePage extends ConsumerStatefulWidget {
  const ChallengePage({super.key});

  @override
  ConsumerState<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends ConsumerState<ChallengePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tantangan'),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              tooltip: 'Akun',
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (value) => _onAccountAction(value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'name', child: Text('Ubah nama tampilan')),
                PopupMenuItem(value: 'signout', child: Text('Keluar')),
              ],
            ),
        ],
      ),
      body: !firebaseReady
          ? const EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Firebase belum aktif',
              message:
                  'Jalankan `flutterfire configure` lalu mulai ulang aplikasi '
                  'untuk memakai tantangan bacaan bersama.',
            )
          : authState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(authStateProvider),
              ),
              data: (user) => user == null
                  ? const _SignInView()
                  : _ChallengeBody(
                      user: user,
                      busy: _busy,
                      onCreate: _createGroup,
                      onJoin: _joinGroup,
                    ),
            ),
    );
  }

  Future<void> _onAccountAction(String value) async {
    if (value == 'signout') {
      try {
        await ref.read(authControllerProvider.notifier).signOut();
      } catch (error) {
        _showError(error);
      }
      return;
    }

    final controller = TextEditingController(
      text: ref.read(currentUserProvider)?.displayName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nama tampilan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama',
            hintText: 'Nama yang tampil di papan peringkat',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(authControllerProvider.notifier).updateDisplayName(name);
      await ref.read(readingProgressProvider.notifier).syncNow();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buat grup bacaan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama grup',
            hintText: 'Mis. One Day One Juz',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      final group = await ref
          .read(challengeControllerProvider.notifier)
          .createGroup(name);
      if (!mounted) return;
      await _openGroup(group);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinGroup([String? initialCode]) async {
    final controller = TextEditingController(text: initialCode ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gabung grup'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            labelText: 'Kode undangan',
            hintText: 'ABC123',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Gabung'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      final group = await ref
          .read(challengeControllerProvider.notifier)
          .joinGroup(code);
      if (!mounted) return;
      await _openGroup(group);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openGroup(ReadingGroup group) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailPage(groupId: group.id, initialGroup: group),
      ),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _ChallengeBody extends ConsumerWidget {
  const _ChallengeBody({
    required this.user,
    required this.busy,
    required this.onCreate,
    required this.onJoin,
  });

  final AppUser user;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(myGroupsProvider);
    final progress = ref.watch(readingProgressProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myGroupsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _GreetingCard(user: user, progress: progress),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onCreate,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Buat grup'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onJoin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Gabung'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'GRUP SAYA',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          groupsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            data: (groups) => groups.isEmpty
                ? _NoGroups(onJoin: busy ? null : onJoin)
                : Column(
                    children: [
                      for (final group in groups)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _GroupTile(
                            group: group,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GroupDetailPage(
                                  groupId: group.id,
                                  initialGroup: group,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.user, required this.progress});

  final AppUser user;
  final ReadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = progress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    user.initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.isAnonymous
                            ? 'Masuk sebagai tamu'
                            : user.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    current == null
                        ? 'Belum ada progres bacaan'
                        : 'Progres Anda • ${current.reference}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${current?.percent ?? 0}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: current?.ratio ?? 0,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Progres tersimpan di perangkat dan dikirim otomatis ke setiap '
              'grup yang Anda ikuti.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final ReadingGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.groups_2_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Kode ${group.code} • ${group.memberCount} anggota',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _NoGroups extends StatelessWidget {
  const _NoGroups({required this.onJoin});

  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada grup',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Buat tantangan baru atau masukkan kode undangan dari teman.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.key_outlined),
              label: const Text('Punya kode undangan?'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInView extends ConsumerStatefulWidget {
  const _SignInView();

  @override
  ConsumerState<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<_SignInView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();

  bool _emailMode = false;
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Icon(Icons.groups_rounded, size: 58, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          'Baca bersama teman',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buat grup tantangan, bagikan kode 6 karakter, lalu lihat siapa yang '
          'paling jauh membaca — diperbarui secara langsung.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _busy ? null : _signInAnonymously,
          icon: _busy && !_emailMode
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_outline),
          label: const Text('Masuk sebagai tamu'),
        ),
        const SizedBox(height: 6),
        Text(
          'Cukup untuk bergabung ke grup. Tanpa email atau kata sandi.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'atau',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 18),
        if (!_emailMode)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => setState(() => _emailMode = true),
            icon: const Icon(Icons.alternate_email),
            label: const Text('Masuk dengan email'),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_register) ...[
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama tampilan',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitEmail(),
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submitEmail,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? 'Daftar' : 'Masuk'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _emailMode = true;
                          }),
                    child: Text(
                      _register
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).signInAnonymously();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      _showError('Masukkan alamat email yang valid.');
      return;
    }
    if (password.length < 6) {
      _showError('Kata sandi minimal 6 karakter.');
      return;
    }

    setState(() => _busy = true);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (_register) {
        final name = _name.text.trim().isEmpty
            ? email.split('@').first
            : _name.text.trim();
        await controller.register(
          email: email,
          password: password,
          displayName: name,
        );
      } else {
        await controller.signIn(email: email, password: password);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
