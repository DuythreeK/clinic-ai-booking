import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/dio_client.dart';
import 'clinic_detail_screen.dart';
class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  // Thêm dòng này

  final TextEditingController _searchController = TextEditingController();
  // Cập nhật lại đoạn này ở đầu class _ClinicListScreenState
  final Map<String, List<String>> locationData = {
    "Hà Nội": ["Đống Đa", "Hoàn Kiếm", "Hà Đông", "Long Biên", "Ba Đình", "Hai Bà Trưng", "Tây Hồ", "Cầu Giấy"],
    "Hồ Chí Minh": ["Quận 1", "Quận 3", "Quận 5", "Bình Thạnh", "Tân Bình", "Thủ Đức"],
  };
  String selectedCategory = "Tất cả"; // Biến lưu category đang chọn
  String searchQuery = ""; // Biến lưu nội dung tìm kiếm
  List<dynamic> clinics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClinics();
  }

  // Sử dụng DioClient của nhóm để gọi API từ NestJS
  Future<void> fetchClinics() async {
    try {
      final dioClient = DioClient(secureStorage: const FlutterSecureStorage());
      // Gọi đến endpoint /clinics (NestJS)
      final response = await dioClient.dio.get('/clinics');

      setState(() {
        clinics = response.data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu từ Backend: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClinics = clinics.where((clinic) {
      // Lấy Tên và Địa chỉ từ DB ra, ép kiểu về String và viết thường để so sánh
      final name = (clinic['name'] ?? "").toString().toLowerCase();
      final address = (clinic['address'] ?? "").toString().toLowerCase();
      final city = (clinic['city'] ?? "").toString().toLowerCase();

      final query = searchQuery.toLowerCase();

      // 1. Lọc theo Tab (Bệnh viện/Phòng khám) - Giữ nguyên logic cũ của bạn
      bool matchesCategory = true;
      if (selectedCategory == "Bệnh viện") {
        matchesCategory = name.contains("bệnh viện");
      } else if (selectedCategory == "Phòng khám") {
        matchesCategory = name.contains("phòng khám");
      }

      // 2. Lọc theo Search Query (Chấp nhận khớp Tên HOẶC Địa chỉ HOẶC Thành phố)
      // Việc này giúp khi bạn chọn "Cầu Giấy", nó sẽ khớp với "123 Cầu Giấy" trong address
      bool matchesSearch = name.contains(query) || address.contains(query) || city.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Màu nền nhạt chuẩn Design
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          "Chọn cơ sở y tế",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategories(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED)))
                : clinics.isEmpty
                ? const Center(child: Text("Không có phòng khám nào trong DB"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredClinics.length, // Dùng danh sách đã qua bộ lọc
              itemBuilder: (context, index) => _buildClinicCard(filteredClinics[index]),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Thanh tìm kiếm và nút Lọc
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController, // Gắn bộ điều khiển vào
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Tìm kiếm...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  // LOGIC HIỆN NÚT X:
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchController.clear(); // Xóa chữ trong ô nhập
                        searchQuery = "";         // Reset biến lọc về rỗng
                        selectedCategory = "Tất cả"; // (Tùy chọn) Reset luôn category
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút 3 gạch (Filter) giữ nguyên của bạn
          GestureDetector(
            onTap: () => _showFilterLocation(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Các nút phân loại (Tất cả, Bệnh viện...)
  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        children: [
          _categoryChip("Tất cả"),
          _categoryChip("Bệnh viện"),
          _categoryChip("Phòng khám"),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final isSelected = selectedCategory == label; // Kiểm tra xem có đang chọn nút này không
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label; // Cập nhật trạng thái khi nhấn
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 3. Card hiển thị thông tin Phòng khám lấy từ DB
  Widget _buildClinicCard(dynamic clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Placeholder
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital, color: Color(0xFF2F80ED), size: 35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? 'Tên phòng khám',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic['address'] ?? 'Địa chỉ đang cập nhật',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("(4) ", style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ...List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < 4 ? Colors.orange : Colors.grey[300])),
                      ],
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
                child: OutlinedButton(
                  onPressed: () {
                    // In ra console để kiểm tra xem nút có ăn lệnh không
                    debugPrint("Đang nhấn vào clinic: ${clinic['name']}");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClinicDetailScreen(clinic: clinic),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F80ED),
                    side: const BorderSide(color: Color(0xFF56CCF2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF56CCF2).withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Xem chi tiết", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Sẽ code logic Đặt khám (chọn Slot) sau
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text("Đặt khám ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  void _showFilterLocation(BuildContext context) {
    String tempCity = "Hà Nội";
    String? tempDistrict; // Quận đang được chọn tạm thời
    bool isSelectingCity = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> currentList = isSelectingCity
                ? locationData.keys.toList()
                : locationData[tempCity]!;

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header (Nút X và Tiêu đề) - Giữ nguyên như cũ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      const Text("Lọc theo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 40),
                    ],
                  ),
                  // Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _filterTab("Tỉnh/Thành phố", isSelectingCity, () => setModalState(() => isSelectingCity = true)),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                      _filterTab("Quận/Huyện", !isSelectingCity, () => setModalState(() => isSelectingCity = false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // List View
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        String item = currentList[index];

                        // LOGIC QUAN TRỌNG: Kiểm tra xem dòng này có đang được chọn không để tô xanh
                        bool isSelected = isSelectingCity
                            ? (item == tempCity)
                            : (item == tempDistrict);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelectingCity) {
                                tempCity = item;
                                tempDistrict = null; // Reset quận khi đổi tỉnh
                                isSelectingCity = false; // Tự nhảy sang tab Quận
                              } else {
                                tempDistrict = item; // Tô xanh quận vừa chọn
                                // Đợi 200ms cho người dùng thấy màu xanh rồi mới đóng
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  setState(() {
                                    searchQuery = item; // 1. Gán giá trị để lọc danh sách phòng khám
                                    _searchController.text = item; // 2. Hiển thị chữ lên thanh Search (nếu bạn có dùng Controller)
                                  });
                                  Navigator.pop(context);
                                });
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // NẾU CHỌN THÌ XANH, KHÔNG THÌ TRẮNG
                              color: isSelected ? const Color(0xFF2F80ED) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFF2F80ED) : Colors.grey[300]!),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Widget phụ trợ cho cái Tab xanh xanh ở trên
  Widget _filterTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F80ED) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black54, fontSize: 12)),
      ),
    );
  }
}