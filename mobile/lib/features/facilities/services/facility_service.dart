import '../../../core/api/dio_client.dart';
import '../data/facility_seed_data.dart';
import '../models/booking_facility_item.dart';

/// Service lấy danh sách cơ sở y tế cho luồng booking.
class FacilityService {
  /// Tạo service với DioClient đã cấu hình sẵn.
  FacilityService({required this.dioClient});

  final DioClient dioClient;

  /// Lấy danh sách cơ sở từ backend, lỗi thì fallback seed.
  Future<List<BookingFacilityItem>> getFacilities({String? search}) async {
    try {
      // Gọi API ngoài qua DioClient.
      final response = await dioClient.get(
        '/facilities',
        queryParameters: {
          'page': 1,
          'limit': 50,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final items = _unwrapItems(response.data);
      final facilities = items
          .map((item) {
            return BookingFacilityItem(
              id: _toInt(item['id']) ?? 0,
              name: (item['name'] ?? '').toString(),
              type: item['facilityType']?.toString(),
              address: item['addressDetail']?.toString(),
            );
          })
          .where((e) => e.id > 0 && e.name.isNotEmpty)
          .toList();

      if (facilities.isEmpty) {
        return _seedFiltered(search);
      }
      return facilities;
    } catch (_) {
      return _seedFiltered(search);
    }
  }

  /// Lọc dữ liệu seed cục bộ khi API chưa sẵn sàng.
  List<BookingFacilityItem> _seedFiltered(String? search) {
    if (search == null || search.trim().isEmpty) {
      return seededFacilities;
    }

    final lower = search.toLowerCase();
    return seededFacilities
        .where(
          (e) =>
              e.name.toLowerCase().contains(lower) ||
              (e.address ?? '').toLowerCase().contains(lower) ||
              (e.type ?? '').toLowerCase().contains(lower),
        )
        .toList();
  }

  /// Bóc tách response từ nhiều dạng backend khác nhau.
  List<Map<String, dynamic>> _unwrapItems(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return <Map<String, dynamic>>[];
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Ép kiểu số linh hoạt từ `int`, `num` hoặc `String`.
  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
