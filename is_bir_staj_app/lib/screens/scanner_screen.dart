import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'detail_screen.dart';

class _AppColors {
  static const primaryRed = Color(0xFFD32F2F);
  static const darkRed = Color(0xFF8E0000);
  static const accentRed = Color(0xFFFF5252);
  static const pureWhite = Colors.white;
  static const softWhite = Color(0xFFFDF7F7);
}

class TextScannerScreen extends StatefulWidget {
  const TextScannerScreen({super.key});

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // İşlem sırasında butonu kilitlemek için

  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  // Cihazın arka kamerasını bul ve başlat
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false, // Sese ihtiyacımız yok
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _scanTextFromImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String foundNumber = "";

      // Bulunan metinler içinde regex (sadece rakam) taraması yap
      // \b\d+\b kuralı: Kelime sınırları içinde sadece rakamlardan oluşan yapıları yakalar
      RegExp regExp = RegExp(r'\b\d+\b');

      for (TextBlock block in recognizedText.blocks) {
        final match = regExp.firstMatch(block.text);
        if (match != null) {
          foundNumber = match.group(0)!;
          break;
        }
      }

      textRecognizer.close();

      if (foundNumber.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(enNo: foundNumber),
          ),
        );
      } else {
        if (!mounted) return;
        _showModernSnackBar(
          "Geçerli bir cihaz numarası okunamadı, biraz daha yaklaştırın.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("OCR Hatası: $e");
      if (mounted) {
        _showModernSnackBar("Bir hata oluştu, lütfen tekrar deneyin.",
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showModernSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _AppColors.darkRed : _AppColors.primaryRed,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Cihaz Numarası Oku',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        foregroundColor: _AppColors.pureWhite,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC8E0000), // koyu kırmızı, yarı saydam
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Kamera önizlemesi
                CameraPreview(_cameraController!),

                // Üst ve alt karartma gradyanları (okunabilirlik için)
                const _TopBottomShade(),

                // Yönlendirme metni
                Positioned(
                  top: kToolbarHeight + 48,
                  left: 32,
                  right: 32,
                  child: _InstructionPill(),
                ),

                // Tarama çerçevesi (kırmızı köşe aksanları + hareketli çizgi)
                Center(
                  child: _ScannerFrame(animation: _scanLineController),
                ),

                // İşlem sırasında overlay
                if (_isProcessing) const _ProcessingOverlay(),

                // Alt tarama butonu
                Positioned(
                  bottom: 40,
                  left: 32,
                  right: 32,
                  child: _CaptureButton(
                    isProcessing: _isProcessing,
                    onPressed: _scanTextFromImage,
                  ),
                ),
              ],
            )
          : const _LoadingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AppColors.darkRed, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: _AppColors.pureWhite,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              "Kamera hazırlanıyor...",
              style: TextStyle(
                color: _AppColors.pureWhite.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBottomShade extends StatelessWidget {
  const _TopBottomShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _AppColors.accentRed.withOpacity(0.6)),
      ),
      child: const Text(
        "Cihaz etiketini kırmızı çerçeve içine hizalayın",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarama çerçevesi: köşe aksanlı + hareketli tarama çizgisi
// ---------------------------------------------------------------------------
class _ScannerFrame extends StatelessWidget {
  final Animation<double> animation;
  const _ScannerFrame({required this.animation});

  static const double _width = 270;
  static const double _height = 110;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hafif beyaz iç dolgu (fokus alanı hissi)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              color: Colors.white.withOpacity(0.03),
            ),
          ),

          // Hareketli tarama çizgisi
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Positioned(
                top: 6 + animation.value * (_height - 12),
                left: 12,
                right: 12,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _AppColors.accentRed,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.accentRed.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Dört köşe aksanı
          const _CornerAccent(alignment: Alignment.topLeft),
          const _CornerAccent(alignment: Alignment.topRight),
          const _CornerAccent(alignment: Alignment.bottomLeft),
          const _CornerAccent(alignment: Alignment.bottomRight),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Alignment alignment;
  const _CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: _AppColors.accentRed, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: _AppColors.accentRed, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: _AppColors.accentRed, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: _AppColors.accentRed, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(14) : Radius.zero,
            topRight:
                isTop && !isLeft ? const Radius.circular(14) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(14) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(14) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OCR işlerken gösterilen overlay
// ---------------------------------------------------------------------------
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: _AppColors.softWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: _AppColors.primaryRed,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                "Etiket okunuyor...",
                style: TextStyle(
                  color: _AppColors.darkRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alt tarama / çekim butonu
// ---------------------------------------------------------------------------
class _CaptureButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;

  const _CaptureButton({
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primaryRed.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : onPressed,
        icon: Icon(
          isProcessing ? Icons.hourglass_top : Icons.document_scanner,
          size: 26,
        ),
        label: Text(
          isProcessing ? "Okunuyor..." : "Etiketi Oku",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: _AppColors.primaryRed,
          disabledBackgroundColor: _AppColors.primaryRed.withOpacity(0.6),
          foregroundColor: _AppColors.pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}