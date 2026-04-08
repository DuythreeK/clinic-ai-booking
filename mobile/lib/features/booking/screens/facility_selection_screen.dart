import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../../facilities/models/booking_facility_item.dart';
import '../../facilities/services/facility_service.dart';

class FacilitySelectionScreen extends StatefulWidget {
  const FacilitySelectionScreen({
    super.key,
    required this.dioClient,
  });

  final DioClient dioClient;

  @override
  State<FacilitySelectionScreen> createState() =>
      _FacilitySelectionScreenState();
}

class _FacilitySelectionScreenState extends State<FacilitySelectionScreen> {
  late final FacilityService _facilityService;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _selectingFacility = false;

  bool _loading = true;
  String? _error;
  List<BookingFacilityItem> _facilities = <BookingFacilityItem>[];
  List<BookingFacilityItem> _filteredFacilities = <BookingFacilityItem>[];

  @override
  void initState() {
    super.initState();
    _facilityService = FacilityService(dioClient: widget.dioClient);
    _loadFacilities();
    _searchCtrl.addListener(_filterFacilities);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final facilities = await _facilityService.getFacilities();
      setState(() {
        _facilities = facilities;
        _filteredFacilities = facilities;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải danh sách cơ sở: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _filterFacilities() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFacilities = _facilities;
      } else {
        _filteredFacilities = _facilities
            .where((f) =>
                f.name.toLowerCase().contains(query) ||
                (f.address?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  void _selectFacility(BookingFacilityItem facility) {
    if (_selectingFacility) return;
    _selectingFacility = true;
    Navigator.of(context).pop(facility);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text('Chọn cơ sở y tế'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search field
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm cơ sở y tế...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFacilities,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredFacilities.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy cơ sở y tế'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: _filteredFacilities.length,
      itemBuilder: (context, index) {
        final facility = _filteredFacilities[index];
        return _FacilityCard(
          facility: facility,
          onTap: () => _selectFacility(facility),
        );
      },
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.onTap,
  });

  final BookingFacilityItem facility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final facilityType = facility.type ?? '';
    final isClinc = facilityType.toLowerCase().contains('clinic') ||
        facilityType.toLowerCase().contains('phòng khám');
    final icon = isClinc ? Icons.local_pharmacy : Icons.local_hospital;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon + name + type badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: const Color(0xFF1BC47D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              facility.type ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF667085),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        facility.address ?? 'Địa chỉ không có sẵn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
