import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import 'clinic_detail_screen.dart';

class ClinicListScreen extends StatefulWidget {
  /// Màn danh sách cơ sở y tế.
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  /// Controller của ô tìm kiếm.
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<String>> locationData = {
    "Hà Nội": ["Đống Đa", "Hoàn Kiếm", "Hà Đông", "Long Biên", "Ba Đình", "Hai Bà Trưng", "Tây Hồ", "Cầu Giấy"],
    "Hồ Chí Minh": ["Quận 1", "Quận 3", "Quận 5", "Bình Thạnh", "Tân Bình", "Thủ Đức"],
  };

  String selectedCategory = "Tất cả";
  String searchQuery = "";
  List<dynamic> clinics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu ngay khi màn hình được tạo.
    fetchClinics();
  }

  /// Gọi API lấy danh sách cơ sở y tế.
  Future<void> fetchClinics() async {
    try {
      setState(() => isLoading = true);
      final dioClient = DioClient(secureStorage: const FlutterSecureStorage());

      // Gọi API ngoài bằng đường dẫn tuyệt đối để Dio ghép đúng baseUrl.
      final response = await dioClient.dio.get('/facilities');

      debugPrint("--- CLINIC LIST DEBUG ---");
      debugPrint("Raw Response Data: ${response.data}");

      setState(() {
        final resData = response.data;

        // Hỗ trợ nhiều dạng response để tránh phụ thuộc cứng vào một schema.
        if (resData is Map) {
          final dataWrapper = resData['data'];
          if (dataWrapper != null && dataWrapper is Map && dataWrapper['items'] != null) {
            clinics = dataWrapper['items'];
          }
          else if (resData['items'] != null) {
            clinics = resData['items'];
          }
          else if (dataWrapper != null && dataWrapper is List) {
            clinics = dataWrapper;
          } else {
            clinics = [];
          }
        } else if (resData is List) {
          clinics = resData;
        }

        debugPrint("Parsed Clinics Count: ${clinics.length}");
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu từ Backend: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách theo tab và từ khóa tìm kiếm ngay trên client.
    final filteredClinics = clinics.where((clinic) {
      final name = (clinic['name'] ?? "").toString().toLowerCase();
      final address = (clinic['addressDetail'] ?? clinic['address'] ?? "").toString().toLowerCase();
      final type = (clinic['facilityType'] ?? "").toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      // Lọc theo tab dựa trên `facilityType` từ backend.
      bool matchesCategory = true;
      if (selectedCategory == "Bệnh viện") {
        matchesCategory = type == 'hospital';
      } else if (selectedCategory == "Phòng khám") {
        matchesCategory = type == 'clinic' || type == 'vaccination_center';
      }

      // Lọc thêm theo tên hoặc địa chỉ.
      bool matchesSearch = name.contains(query) || address.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Chọn cơ sở y tế",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: fetchClinics,
        color: const Color(0xFF2DC7C4),
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildCategories(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DC7C4)))
                  : filteredClinics.isEmpty
                  ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          clinics.isEmpty
                              ? "Chưa có dữ liệu. Hãy thêm vào DB bằng Prisma Studio."
                              : "Không tìm thấy kết quả phù hợp",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: fetchClinics,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Tải lại dữ liệu"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DC7C4),
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredClinics.length,
                itemBuilder: (context, index) => _buildClinicCard(filteredClinics[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Tìm tên hoặc địa chỉ...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        searchQuery = "";
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
          GestureDetector(
            onTap: () => _showFilterLocation(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.tune, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ["Tất cả", "Bệnh viện", "Phòng khám"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, bottom: 10),
        itemCount: categories.length,
        itemBuilder: (ctx, i) => _categoryChip(categories[i]),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2DC7C4) : Colors.grey[200],
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

  Widget _buildClinicCard(dynamic clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF2DC7C4), size: 35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? 'Tên cơ sở y tế',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic['addressDetail'] ?? 'Địa chỉ đang cập nhật',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  onPressed: () => context.push('/clinic-detail', extra: clinic),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2DC7C4),
                    side: const BorderSide(color: Color(0xFF2DC7C4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Xem chi tiết", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Chuyển sang màn đặt lịch khám.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DC7C4),
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
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      const Text("Lọc địa điểm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        String item = currentList[index];
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            if (isSelectingCity) {
                              setModalState(() {
                                tempCity = item;
                                isSelectingCity = false;
                              });
                            } else {
                              setState(() {
                                searchQuery = item;
                                _searchController.text = item;
                              });
                              Navigator.pop(context);
                            }
                          },
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
}