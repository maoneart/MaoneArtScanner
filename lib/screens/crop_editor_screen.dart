import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../utils/app_theme.dart';

enum CropAspectRatioPreset {
  free('Bebas', null),
  a4('A4', 1.0 / 1.414),
  idCard('KTP / ID', 85.6 / 53.98),
  square('1:1', 1.0),
  photo43('4:3', 4.0 / 3.0),
  wide169('16:9', 16.0 / 9.0);

  final String label;
  final double? ratio; // width / height
  const CropAspectRatioPreset(this.label, this.ratio);
}

class CropEditorScreen extends StatefulWidget {
  final String imagePath;
  final String? title;

  const CropEditorScreen({
    super.key,
    required this.imagePath,
    this.title,
  });

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  Uint8List? _imageBytes;
  int _imageWidth = 0;
  int _imageHeight = 0;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Transform states
  int _quarterTurns = 0; // 0, 1, 2, 3 (0°, 90°, 180°, 270°)
  double _fineAngle = 0.0; // -45.0 to +45.0 degrees
  CropAspectRatioPreset _selectedPreset = CropAspectRatioPreset.free;

  // Normalized crop rectangle (0.0 to 1.0 relative to display image)
  Rect _normalizedCrop = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);

  // Layout image render bounds in UI
  Rect _imageRenderBounds = Rect.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final baked = img.bakeOrientation(decoded);
        setState(() {
          _imageBytes = Uint8List.fromList(img.encodeJpg(baked, quality: 92));
          _imageWidth = baked.width;
          _imageHeight = baked.height;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _resetNormalizedCrop();
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1 + 4) % 4;
      _resetNormalizedCrop();
    });
  }

  void _resetTransforms() {
    setState(() {
      _quarterTurns = 0;
      _fineAngle = 0.0;
      _selectedPreset = CropAspectRatioPreset.free;
      _resetNormalizedCrop();
    });
  }

  void _resetNormalizedCrop() {
    if (_selectedPreset.ratio == null) {
      _normalizedCrop = const Rect.fromLTWH(0.04, 0.04, 0.92, 0.92);
    } else {
      _applyPresetRatio(_selectedPreset);
    }
  }

  void _applyPresetRatio(CropAspectRatioPreset preset) {
    _selectedPreset = preset;
    if (preset.ratio == null) {
      setState(() {
        _normalizedCrop = const Rect.fromLTWH(0.04, 0.04, 0.92, 0.92);
      });
      return;
    }

    final targetRatio = preset.ratio!;
    double currentW = 0.90;
    double currentH = 0.90;

    // Hitung dimensi efektif berdasarkan rotasi
    final bool isRotated = _quarterTurns % 2 != 0;
    final double effectiveImgW = isRotated ? _imageHeight.toDouble() : _imageWidth.toDouble();
    final double effectiveImgH = isRotated ? _imageWidth.toDouble() : _imageHeight.toDouble();
    final double effectiveAspect = effectiveImgW / effectiveImgH;

    // Normalisasi aspect ratio target ke dalam bounding box
    if (targetRatio > effectiveAspect) {
      currentW = 0.92;
      currentH = (currentW / targetRatio) * effectiveAspect;
    } else {
      currentH = 0.92;
      currentW = (currentH * targetRatio) / effectiveAspect;
    }

    currentW = currentW.clamp(0.1, 0.96);
    currentH = currentH.clamp(0.1, 0.96);

    final left = (1.0 - currentW) / 2.0;
    final top = (1.0 - currentH) / 2.0;

    setState(() {
      _normalizedCrop = Rect.fromLTWH(left, top, currentW, currentH);
    });
  }

  Future<void> _saveCroppedImage() async {
    if (_imageBytes == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Decode original image
      img.Image? image = img.decodeImage(_imageBytes!);
      if (image == null) throw Exception('Gagal membaca data gambar');

      // 2. Terapkan rotasi kuadran (90°, 180°, 270°)
      if (_quarterTurns == 1) {
        image = img.copyRotate(image, angle: 90);
      } else if (_quarterTurns == 2) {
        image = img.copyRotate(image, angle: 180);
      } else if (_quarterTurns == 3) {
        image = img.copyRotate(image, angle: 270);
      }

      // 3. Terapkan rotasi pelurus halus (fine angle)
      if (_fineAngle.abs() > 0.1) {
        image = img.copyRotate(
          image,
          angle: _fineAngle,
          interpolation: img.Interpolation.linear,
        );
      }

      // 4. Hitung pixel coordinates dari normalized crop
      final imgW = image.width;
      final imgH = image.height;

      int cropX = (_normalizedCrop.left * imgW).round().clamp(0, imgW - 10);
      int cropY = (_normalizedCrop.top * imgH).round().clamp(0, imgH - 10);
      int cropW = (_normalizedCrop.width * imgW).round().clamp(10, imgW - cropX);
      int cropH = (_normalizedCrop.height * imgH).round().clamp(10, imgH - cropY);

      // 5. Potong piksel secara presisi
      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      // 6. Tulis kembali ke file yang sama dengan kualitas tinggi
      final encodedJpg = img.encodeJpg(cropped, quality: 95);
      final file = File(widget.imagePath);
      await file.writeAsBytes(encodedJpg);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text('Gagal menyimpan hasil crop: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(
          widget.title ?? 'Luruskan & Potong',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted, size: 20),
            tooltip: 'Reset',
            onPressed: _resetTransforms,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveCroppedImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _isProcessing ? 'Memotong...' : 'Selesai',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : Column(
              children: [
                // Canvas Image Viewer with Crop Handles
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildCropCanvas(constraints);
                      },
                    ),
                  ),
                ),

                // Fine Angle Slider (Pelurus Dokumen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.bgCard,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 16, color: AppTheme.accentCyan),
                              const SizedBox(width: 8),
                              Text(
                                'Luruskan Dokumen (Sudut Derajat)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              '${_fineAngle >= 0 ? '+' : ''}${_fineAngle.toStringAsFixed(1)}°',
                              style: GoogleFonts.jetBrainsMono(
                                color: _fineAngle.abs() > 0.1 ? AppTheme.accentCyan : AppTheme.textDim,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.accentCyan,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.textMain,
                          overlayColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _fineAngle,
                          min: -30.0,
                          max: 30.0,
                          divisions: 120,
                          onChanged: (val) {
                            setState(() => _fineAngle = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Preset Ratio Selector & Quick Rotations
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  color: AppTheme.bgCard,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ratio Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: CropAspectRatioPreset.values.map((preset) {
                            final isSelected = _selectedPreset == preset;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(preset.label),
                                selected: isSelected,
                                selectedColor: AppTheme.accentCyan,
                                backgroundColor: AppTheme.bgSurface,
                                side: BorderSide(
                                  color: isSelected ? AppTheme.accentCyan : AppTheme.border,
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.black : AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (_) => _applyPresetRatio(preset),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rotate Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.rotate_left_rounded,
                            label: 'Putar -90°',
                            onTap: _rotateCounterClockwise,
                          ),
                          _buildActionButton(
                            icon: Icons.rotate_right_rounded,
                            label: 'Putar +90°',
                            onTap: _rotateClockwise,
                          ),
                          _buildActionButton(
                            icon: Icons.crop_free_rounded,
                            label: 'Penuh',
                            onTap: () {
                              setState(() {
                                _normalizedCrop = const Rect.fromLTWH(0.01, 0.01, 0.98, 0.98);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCanvas(BoxConstraints constraints) {
    if (_imageBytes == null) return const SizedBox.shrink();

    // Hitung aspect ratio gambar dengan rotasi kuadran
    final bool isRotated = _quarterTurns % 2 != 0;
    final double imgW = isRotated ? _imageHeight.toDouble() : _imageWidth.toDouble();
    final double imgH = isRotated ? _imageWidth.toDouble() : _imageHeight.toDouble();

    // Hitung posisi dan ukuran render gambar di dalam constraints
    final double containerW = constraints.maxWidth;
    final double containerH = constraints.maxHeight;

    final double scale = math.min(containerW / imgW, containerH / imgH);
    final double renderW = imgW * scale;
    final double renderH = imgH * scale;

    final double offsetX = (containerW - renderW) / 2.0;
    final double offsetY = (containerH - renderH) / 2.0;

    _imageRenderBounds = Rect.fromLTWH(offsetX, offsetY, renderW, renderH);

    // Hitung pixel bounds dari normalized crop
    final double cropLeft = _imageRenderBounds.left + (_normalizedCrop.left * renderW);
    final double cropTop = _imageRenderBounds.top + (_normalizedCrop.top * renderH);
    final double cropWidth = _normalizedCrop.width * renderW;
    final double cropHeight = _normalizedCrop.height * renderH;
    final Rect cropPixelRect = Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Gambar yang ditransformasikan
        Center(
          child: SizedBox(
            width: renderW,
            height: renderH,
            child: Transform.rotate(
              angle: _fineAngle * (math.pi / 180.0),
              child: RotatedBox(
                quarterTurns: _quarterTurns,
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),

        // Layer 2: Shading Overlay di luar kotak crop
        Positioned.fill(
          child: CustomPaint(
            painter: _CropOverlayPainter(
              cropRect: cropPixelRect,
              imageBounds: _imageRenderBounds,
            ),
          ),
        ),

        // Layer 3: Interactive Draggable Crop Box with 8 Touch Handles
        Positioned(
          left: cropLeft,
          top: cropTop,
          width: cropWidth,
          height: cropHeight,
          child: GestureDetector(
            onPanUpdate: (details) {
              _moveCropBox(details.delta, renderW, renderH);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentCyan, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Rule of thirds grid lines
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),

                  // 4 Corner Handles
                  _buildHandle(Alignment.topLeft, (delta) => _resizeCorner(delta, true, true, renderW, renderH)),
                  _buildHandle(Alignment.topRight, (delta) => _resizeCorner(delta, false, true, renderW, renderH)),
                  _buildHandle(Alignment.bottomLeft, (delta) => _resizeCorner(delta, true, false, renderW, renderH)),
                  _buildHandle(Alignment.bottomRight, (delta) => _resizeCorner(delta, false, false, renderW, renderH)),

                  // 4 Side Edge Handles
                  _buildEdgeHandle(Alignment.topCenter, (delta) => _resizeEdge(delta, top: true, renderW: renderW, renderH: renderH)),
                  _buildEdgeHandle(Alignment.bottomCenter, (delta) => _resizeEdge(delta, bottom: true, renderW: renderW, renderH: renderH)),
                  _buildEdgeHandle(Alignment.centerLeft, (delta) => _resizeEdge(delta, left: true, renderW: renderW, renderH: renderH)),
                  _buildEdgeHandle(Alignment.centerRight, (delta) => _resizeEdge(delta, right: true, renderW: renderW, renderH: renderH)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle(Alignment alignment, Function(Offset) onDrag) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.textMain,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle(Alignment alignment, Function(Offset) onDrag) {
    final bool isHorizontal = alignment == Alignment.topCenter || alignment == Alignment.bottomCenter;
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: isHorizontal ? 32 : 12,
          height: isHorizontal ? 12 : 32,
          decoration: BoxDecoration(
            color: AppTheme.accentCyan,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _moveCropBox(Offset delta, double renderW, double renderH) {
    if (renderW <= 0 || renderH <= 0) return;

    final dxNormalized = delta.dx / renderW;
    final dyNormalized = delta.dy / renderH;

    double newLeft = (_normalizedCrop.left + dxNormalized).clamp(0.0, 1.0 - _normalizedCrop.width);
    double newTop = (_normalizedCrop.top + dyNormalized).clamp(0.0, 1.0 - _normalizedCrop.height);

    setState(() {
      _normalizedCrop = Rect.fromLTWH(newLeft, newTop, _normalizedCrop.width, _normalizedCrop.height);
    });
  }

  void _resizeCorner(Offset delta, bool isLeft, bool isTop, double renderW, double renderH) {
    if (renderW <= 0 || renderH <= 0) return;

    final dx = delta.dx / renderW;
    final dy = delta.dy / renderH;

    double left = _normalizedCrop.left;
    double top = _normalizedCrop.top;
    double right = _normalizedCrop.right;
    double bottom = _normalizedCrop.bottom;

    if (isLeft) {
      left = (left + dx).clamp(0.0, right - 0.08);
    } else {
      right = (right + dx).clamp(left + 0.08, 1.0);
    }

    if (isTop) {
      top = (top + dy).clamp(0.0, bottom - 0.08);
    } else {
      bottom = (bottom + dy).clamp(top + 0.08, 1.0);
    }

    setState(() {
      _normalizedCrop = Rect.fromLTRB(left, top, right, bottom);
    });
  }

  void _resizeEdge(Offset delta, {bool top = false, bool bottom = false, bool left = false, bool right = false, required double renderW, required double renderH}) {
    if (renderW <= 0 || renderH <= 0) return;

    final dx = delta.dx / renderW;
    final dy = delta.dy / renderH;

    double cLeft = _normalizedCrop.left;
    double cTop = _normalizedCrop.top;
    double cRight = _normalizedCrop.right;
    double cBottom = _normalizedCrop.bottom;

    if (top) cTop = (cTop + dy).clamp(0.0, cBottom - 0.08);
    if (bottom) cBottom = (cBottom + dy).clamp(cTop + 0.08, 1.0);
    if (left) cLeft = (cLeft + dx).clamp(0.0, cRight - 0.08);
    if (right) cRight = (cRight + dx).clamp(cLeft + 0.08, 1.0);

    setState(() {
      _normalizedCrop = Rect.fromLTRB(cLeft, cTop, cRight, cBottom);
    });
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Rect imageBounds;

  _CropOverlayPainter({required this.cropRect, required this.imageBounds});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xB3000000); // 70% black

    // Clip out the crop rectangle
    canvas.save();
    canvas.clipRect(imageBounds);
    canvas.clipRect(cropRect, clipOp: ui.ClipOp.difference);
    canvas.drawRect(imageBounds, backgroundPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.imageBounds != imageBounds;
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;

    final wThird = size.width / 3.0;
    final hThird = size.height / 3.0;

    canvas.drawLine(Offset(wThird, 0), Offset(wThird, size.height), paint);
    canvas.drawLine(Offset(wThird * 2, 0), Offset(wThird * 2, size.height), paint);
    canvas.drawLine(Offset(0, hThird), Offset(size.width, hThird), paint);
    canvas.drawLine(Offset(0, hThird * 2), Offset(size.width, hThird * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
