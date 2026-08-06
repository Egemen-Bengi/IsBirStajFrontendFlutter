import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/donanim_model.dart';

// ---------------------------------------------------------------------------
// Tema renkleri (scanner_screen.dart ile aynı palet)
// ---------------------------------------------------------------------------
class _AppColors {
  static const primaryRed = Color(0xFFD32F2F);
  static const darkRed = Color(0xFF8E0000);
  static const pureWhite = Colors.white;
  static const softWhite = Color(0xFFFDF7F7);
  static const bg = Color(0xFFF7F1F1);
  static const textGrey = Color(0xFF7A7373);
}

class DetailScreen extends StatefulWidget {
  final String enNo;

  const DetailScreen({super.key, required this.enNo});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _apiService = ApiService();

  bool isLoading = true;
  bool isUpdating = false;
  DonanimModel? donanimData;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final data = await _apiService.getDonanim(widget.enNo);
      setState(() {
        donanimData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
        isLoading = false;
      });
    }
  }

  Future<void> _updateData(String? yeniKullanici, String? yeniDurum) async {
    setState(() {
      isUpdating = true;
    });

    try {
      final success =
          await _apiService.updateDonanim(widget.enNo, yeniKullanici, yeniDurum);

      if (success) {
        await _fetchData();
        if (mounted) {
          _showModernSnackBar("Bilgiler başarıyla güncellendi!",
              isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar("Güncelleme başarısız oldu.", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void _showModernSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _AppColors.darkRed : const Color(0xFF2E7D32),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: _AppColors.pureWhite,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _AppColors.pureWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showUpdateDialog() {
    final TextEditingController kullaniciController =
        TextEditingController(text: donanimData?.kullanicisi);
    final TextEditingController durumController =
        TextEditingController(text: donanimData?.durumu);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note,
                          color: _AppColors.primaryRed, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Cihaz Bilgilerini Güncelle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.darkRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ModernTextField(
                  controller: kullaniciController,
                  label: "Zimmetli Kullanıcı",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _ModernTextField(
                  controller: durumController,
                  label: "Cihaz Durumu",
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _AppColors.textGrey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text("İptal",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateData(
                            kullaniciController.text, durumController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.primaryRed,
                        foregroundColor: _AppColors.pureWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Kaydet",
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'EN: ${widget.enNo}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: _AppColors.pureWhite,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AppColors.primaryRed, _AppColors.darkRed],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _fetchData,
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
          ),
        ],
      ),
      body: isLoading
          ? const _LoadingState()
          : errorMessage.isNotEmpty
              ? _ErrorState(message: errorMessage, onRetry: _fetchData)
              : buildDataCard(),
      floatingActionButton: (!isLoading && errorMessage.isEmpty)
          ? FloatingActionButton.extended(
              onPressed: isUpdating ? null : showUpdateDialog,
              icon: isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.edit),
              label: Text(isUpdating ? "Güncelleniyor..." : "Düzenle"),
              backgroundColor: _AppColors.primaryRed,
              foregroundColor: _AppColors.pureWhite,
              elevation: 3,
            )
          : null,
    );
  }

  Widget buildDataCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // Üst "hero" özet bandı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_AppColors.primaryRed, _AppColors.darkRed],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: _AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.devices_other,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 14),
                Text(
                  donanimData?.en ?? widget.enNo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Envanter Numarası",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Bilgi listesi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: _AppColors.pureWhite,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.desktop_windows,
                  label: "Bilgisayar Adı",
                  value: donanimData?.bilgisayarAdi ?? 'Bağımsız Cihaz',
                ),
                const _ThinDivider(),
                _InfoTile(
                  icon: Icons.devices,
                  label: "Cihaz Bilgisi",
                  value:
                      "${donanimData?.cinsi ?? ''} - ${donanimData?.marka ?? ''} ${donanimData?.model ?? ''}"
                          .trim(),
                ),
                const _ThinDivider(),
                _InfoTile(
                  icon: Icons.person,
                  label: "Kullanıcı",
                  value: donanimData?.kullanicisi ?? 'Bilinmiyor',
                ),
                const _ThinDivider(),
                _InfoTile(
                  icon: Icons.fact_check_outlined,
                  label: "Durum",
                  value: donanimData?.durumu ?? 'Arızalı değil',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilgi satırı — ikon rozeti + başlık + değer
// ---------------------------------------------------------------------------
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _AppColors.primaryRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _AppColors.primaryRed, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2626),
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

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF0E4E4)),
    );
  }
}

// ---------------------------------------------------------------------------
// Yükleniyor durumu
// ---------------------------------------------------------------------------
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: _AppColors.primaryRed,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            "Cihaz bilgileri yükleniyor...",
            style: TextStyle(
              color: _AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hata durumu
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _AppColors.primaryRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: _AppColors.primaryRed, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AppColors.darkRed,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar Dene"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primaryRed,
                foregroundColor: _AppColors.pureWhite,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diyalog içindeki metin alanları
// ---------------------------------------------------------------------------
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _AppColors.primaryRed, size: 20),
        filled: true,
        fillColor: _AppColors.softWhite,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF0E4E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.primaryRed, width: 1.6),
        ),
      ),
    );
  }
}