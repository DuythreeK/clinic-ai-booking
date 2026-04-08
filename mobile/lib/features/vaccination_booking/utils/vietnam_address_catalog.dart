import '../data/vietnam_address_data.dart';

class VietnamAddressCatalog {
  VietnamAddressCatalog._();

  static const String provincePlaceholder = 'Chọn Tỉnh/Thành phố';
  static const String districtPlaceholder = 'Chọn Quận/Huyện';
  static const String wardPlaceholder = 'Chọn Phường/Xã';

  static List<VietnamProvinceData> provinces() => vietnamAddressData;

  static VietnamProvinceData? provinceByName(String name) {
    final normalized = _normalizeProvinceQuery(name);
    if (normalized.isEmpty) return null;
    for (final province in vietnamAddressData) {
      if (_normalize(province.name) == normalized) return province;
    }
    return null;
  }

  static List<VietnamDistrictData> districtsByProvinceName(String provinceName) {
    final province = provinceByName(provinceName);
    return province?.districts ?? const [];
  }

  static VietnamDistrictData? districtByName(String provinceName, String districtName) {
    final normalized = _normalize(districtName);
    if (normalized.isEmpty) return null;
    for (final district in districtsByProvinceName(provinceName)) {
      if (_normalize(district.name) == normalized) return district;
    }
    return null;
  }

  static List<VietnamWardData> wardsBySelection(String provinceName, String districtName) {
    final district = districtByName(provinceName, districtName);
    return district?.wards ?? const [];
  }

  static String displayName(dynamic item) {
    if (item is VietnamProvinceData) return item.name;
    if (item is VietnamDistrictData) return item.name;
    if (item is VietnamWardData) return item.name;
    return item?.toString() ?? '';
  }

  static String _normalizeProvinceQuery(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return '';
    if (normalized == 'tp hcm' || normalized == 'tp.hcm' || normalized == 'hcm' || normalized == 'ho chi minh') {
      return _normalize('Thành phố Hồ Chí Minh');
    }
    if (normalized == 'tp ha noi' || normalized == 'hanoi') {
      return _normalize('Thành phố Hà Nội');
    }
    if (normalized == 'can tho') {
      return _normalize('Thành phố Cần Thơ');
    }
    return normalized;
  }

  static String _normalize(String input) {
    var text = input.trim().toLowerCase();
    const replacements = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a', 'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o', 'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u', 'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
