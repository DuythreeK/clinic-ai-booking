import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_rooms_service.dart';
import '../domain/admin_room.dart';
import 'room_form_screen.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key, AdminRoomsService? roomsService})
    : _roomsService = roomsService;

  final AdminRoomsService? _roomsService;

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  late final AdminRoomsService _roomsService;

  List<AdminRoom> _rooms = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _roomsService = widget._roomsService ?? AdminRoomsService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await _roomsService.fetchRooms();

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải danh sách phòng khám.';
      });
    }
  }

  Future<void> _openForm({AdminRoom? room}) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => RoomFormScreen(room: room)));

    if (saved == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: AdminAppTheme.primary,
            onRefresh: _loadData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng làm việc',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 30),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_rooms.length} phòng',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        FloatingActionButton.small(
                          onPressed: () => _openForm(),
                          backgroundColor: AdminAppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _RoomsErrorState(
                      message: _errorMessage!,
                      onRetry: _loadData,
                    ),
                  )
                else if (_rooms.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _RoomsEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AdminAppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25344D).withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _rooms.asMap().entries.map((entry) {
                            final index = entry.key;
                            final room = entry.value;
                            final isLast = index == _rooms.length - 1;

                            return Column(
                              children: [
                                _RoomTile(
                                  room: room,
                                  onTap: () => _openForm(room: room),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: AdminAppTheme.border.withOpacity(
                                      0.95,
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onTap});

  final AdminRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F4FB),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 18,
                color: AdminAppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 16),
                        ),
                      ),
                      if (!room.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1D6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ẩn',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: const Color(0xFFE39B17)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${room.code} • Tầng ${room.floor} ${room.specialtyName != null ? '• ' + room.specialtyName! : '(Phòng đa năng)'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AdminAppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomsEmptyState extends StatelessWidget {
  const _RoomsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F4FB),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 30,
                color: AdminAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có phòng làm việc',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút cộng để thêm phòng khám mới vào hệ thống.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomsErrorState extends StatelessWidget {
  const _RoomsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminAppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEEF0),
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  color: Color(0xFFFF5E63),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tải được danh sách phòng',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminAppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
