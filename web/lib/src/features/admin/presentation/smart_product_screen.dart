// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_service.dart';
import '../../../services/product_service.dart';

class SmartProductScreen extends StatefulWidget {
  const SmartProductScreen({super.key});

  @override
  State<SmartProductScreen> createState() => _SmartProductScreenState();
}

class _SmartProductScreenState extends State<SmartProductScreen> {
  static const double _minCategoryMatchScore = 0.45;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _sizeController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  List<String> _categoryOptions = const [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;

  String _status = 'Published';
  bool _isSaving = false;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  bool _lastAnalysisUsedImage = false;
  String? _generatedDescription;
  String? _uploadedImageUrl;
  String? _previewMimeType;
  Uint8List? _previewBytes;
  Map<String, dynamic>? _scrapedPriceDetails;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _petTypeController.dispose();
    _sizeController.dispose();
    _highlightsController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final auth = context.read<AuthService>();
      final categories = await CategoryService(auth).getCategories();
      final names =
          categories
              .map((c) => c.name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        _categoryOptions = names;
        _selectedCategory = names.isNotEmpty ? names.first : null;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryOptions = const [];
        _selectedCategory = null;
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategoriler alınamadı.')));
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _previewBytes = bytes;
      _previewMimeType = picked.mimeType ?? 'image/jpeg';
      _uploadedImageUrl = null;
      _isUploading = true;
    });

    await _uploadToBackend(bytes, picked.name);
  }

  Future<void> _uploadToBackend(Uint8List bytes, String fileName) async {
    try {
      final auth = context.read<AuthService>();
      final service = ProductService(auth);
      final url = await service.uploadImage(bytes: bytes, fileName: fileName);
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim başarıyla yüklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resim yüklenemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCategories = _categoryOptions.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: AppSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.1),
                            AppTheme.accent.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akıllı Ürün Stüdyosu',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Görseli seç, gramaj/adedi gir ve AI ile başlık ile kategoriyi otomatik doldur.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Ürün başlığı',
                        hintText: 'AI analizinden sonra otomatik dolacak',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          (_selectedCategory != null &&
                                  _categoryOptions.contains(_selectedCategory))
                              ? _selectedCategory
                              : null,
                      items:
                          _categoryOptions
                              .map(
                                (name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _isLoadingCategories
                              ? null
                              : (value) {
                                setState(() => _selectedCategory = value);
                              },
                      decoration: InputDecoration(
                        labelText: 'Kategori *',
                        helperText:
                            _isLoadingCategories
                                ? 'Kategoriler yükleniyor...'
                                : hasCategories
                                ? null
                                : 'Önce Kategori Yönetimi ekranından kategori ekleyin.',
                      ),
                      validator: (_) {
                        if (_isLoadingCategories) {
                          return 'Kategoriler yükleniyor';
                        }
                        if (_selectedCategory == null ||
                            _selectedCategory!.trim().isEmpty) {
                          return 'Kategori seçmek zorunlu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _petTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Hayvan türü (örn: kedi, köpek)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sizeController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Gramaj / Adet *',
                        hintText: 'Örn: 10kg, 500g, 1 adet, 2 adet, 1 litre',
                        helperText:
                            'Kg/gram varsa yazın, gramajlı değilse adet girin (örn: 1 adet).',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Gramaj / adet zorunlu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeWithAi,
                        icon: const Icon(Icons.psychology),
                        label: Text(
                          _isAnalyzing
                              ? 'AI analiz ediyor...'
                              : 'AI önerisi al ve doldur',
                        ),
                      ),
                    ),
                    if (_generatedDescription != null && _lastAnalysisUsedImage)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Görsel ile analiz edildi',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            // marka gösterimi UI'den kaldırıldı; arka planda kullanılacak
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _highlightsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Öne çıkan özellikler',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Resim Yükle ────────────────────────────────────────
                    Text(
                      'Ürün Resmi',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Satış Fiyatı (TL)',
                        hintText: 'Piyasaya göre otomatik doldurulur',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                    ),
                    if (_scrapedPriceDetails != null) ...[
                      const SizedBox(height: 12),
                      _buildPriceDetailsWidget(context, cs),
                    ],
                    const SizedBox(height: 12),
                    if (_generatedDescription != null &&
                        _generatedDescription!.trim().isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Açıklama Önizleme',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _generatedDescription!,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'Draft', child: Text('Taslak')),
                        DropdownMenuItem(
                          value: 'Published',
                          child: Text('Yayında'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _status = value);
                      },
                      decoration: const InputDecoration(labelText: 'Durum'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isSaving ||
                                    _isUploading ||
                                    _isLoadingCategories ||
                                    !hasCategories)
                                ? null
                                : _save,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          _isSaving
                              ? 'Kaydediliyor...'
                              : _isUploading
                              ? 'Resim yükleniyor...'
                              : 'Akıllı Ürün Oluştur',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Resim seçici widget ─────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_previewBytes != null) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.memory(
                _previewBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: Text(
                    _isUploading
                        ? 'Yükleniyor...'
                        : _uploadedImageUrl != null
                        ? '✓ Resim yüklendi'
                        : 'Resim seçilmedi',
                    style: TextStyle(
                      color:
                          _uploadedImageUrl != null
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      _previewBytes != null ? 'Değiştir' : 'Galeriden Seç',
                    ),
                  ),
              ],
            ),
          ),
          if (_uploadedImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _uploadedImageUrl!,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI başlığı oluşmadan kayıt yapılamaz.')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategori seçmek zorunlu.')));
      return;
    }

    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ürün resmi yükleyin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AuthService>();
    final service = ProductService(auth);

    final error = await service.createSmartProduct(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      petType: _emptyToNull(_petTypeController.text),
      highlights: _emptyToNull(_highlightsController.text),
      generatedDescription: _generatedDescription,
      minPrice: double.tryParse(_maxPriceController.text.trim()),
      maxPrice: double.tryParse(_maxPriceController.text.trim()),
      imageUrl: _uploadedImageUrl,
      status: _status,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Akıllı ürün başarıyla eklendi.')),
    );

    if (error == null) {
      _formKey.currentState?.reset();
      _titleController.clear();
      _petTypeController.clear();
      _sizeController.clear();
      _highlightsController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      setState(() {
        _status = 'Published';
        _selectedCategory =
            _categoryOptions.isNotEmpty ? _categoryOptions.first : null;
        _generatedDescription = null;
        _lastAnalysisUsedImage = false;
        _uploadedImageUrl = null;
        _previewMimeType = null;
        _previewBytes = null;
        _scrapedPriceDetails = null;
      });
    }
  }

  Future<void> _analyzeWithAi() async {
    final sizeValue = _sizeController.text.trim();
    if (sizeValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analiz için Gramaj / Adet zorunlu.')),
      );
      return;
    }

    if (_previewBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analiz için önce ürün resmi seçin.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _scrapedPriceDetails = null;
    });

    try {
      final auth = context.read<AuthService>();
      final service = ProductService(auth);
      final imageBase64 = base64Encode(_previewBytes!);
      final data = await service.getAiSuggestion(
        title: '',
        category: _selectedCategory,
        size: sizeValue,
        imageUrl: _uploadedImageUrl,
        imageBase64: imageBase64,
        imageMimeType: _previewMimeType,
      );

      final category = (data['category'] ?? '').toString().trim();
      final suggestedTitle = (data['title'] ?? '').toString().trim();
      final description = (data['description'] ?? '').toString().trim();
      final petType = (data['petType'] ?? '').toString().trim();

      var brand = (data['brand'] ?? '').toString().trim();
      final aiTitle = suggestedTitle;

      // Bonnie fallback if brand missing but title mentions Bonnie
      if ((brand.isEmpty || brand.toLowerCase() == 'null') &&
          aiTitle.toLowerCase().contains('bonnie')) {
        brand = 'Bonnie';
      }

      // Always populate UI title from AI (read-only), but DO NOT use UI title for price queries
      if (aiTitle.isNotEmpty) {
        _titleController.text = aiTitle;
      }

      // If AI could not produce a title, abort price scraping
      if (aiTitle.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI ürün başlığı çıkaramadı, fiyat analizi yapılamadı.')),
          );
        }
        if (mounted) setState(() => _isAnalyzing = false);
        return;
      }

      // Reject very generic AI titles like plain "mama" to avoid broad scraping
      final lowerTitle = aiTitle.toLowerCase();
      final genericTitles = <String>{'mama', 'kedi maması', 'köpek maması', 'kedi mama', 'köpek mama'};
      if (genericTitles.contains(lowerTitle) || lowerTitle.trim().split(' ').every((t) => t.length <= 3 && genericTitles.contains(t))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI ürün başlığı çok genel, fiyat analizi yapılamadı.')),
          );
        }
        if (mounted) setState(() => _isAnalyzing = false);
        return;
      }

      if (category.isNotEmpty) {
        final suggested = _findClosestCategory(category);
        if (suggested.isNotEmpty) {
          _selectedCategory = suggested;
        } else {
          await _createAndSelectAiCategory(category);
        }
      }

      Map<String, dynamic>? scrapedPrice;
      try {
        final priceQuery = _buildPriceQuery(
          brand: brand,
          title: aiTitle,
          adminSize: sizeValue,
        );

        scrapedPrice = await service.getScrapedPriceSuggestion(
          query: priceQuery,
          category: null,
          weight: sizeValue,
          brand: brand.isNotEmpty ? brand : null,
        );
      } catch (_) {
        scrapedPrice = null;
      }

      final aiMin = data['minPrice'];
      final aiMax = data['maxPrice'];
      final aiMinD = (aiMin as num?)?.toDouble();
      final aiMaxD = (aiMax as num?)?.toDouble();

      if (scrapedPrice == null || (scrapedPrice['sampleCount'] ?? 0) == 0) {
        if (aiMinD != null || aiMaxD != null) {
          final aiSuggested = (aiMinD != null && aiMaxD != null)
              ? ((aiMinD + aiMaxD) / 2)
              : (aiMaxD ?? aiMinD);
          scrapedPrice = {
            'minPrice': aiMinD,
            'maxPrice': aiMaxD,
            'medianPrice': aiSuggested,
            'suggestedPrice': aiSuggested,
            'quickSalePrice': aiMinD,
            'premiumPrice': aiMaxD,
            'confidence': 0.5,
            'sampleCount': 0,
            'note': 'AI heuristic tahmini (Google Shopping verisi bulunamadı)',
          };
        }
      }

      final bestPrice = scrapedPrice?['suggestedPrice'] ??
          scrapedPrice?['medianPrice'] ??
          scrapedPrice?['modePrice'];
      final minPriceVal = scrapedPrice?['minPrice'] ?? aiMinD;
      final maxPriceVal = scrapedPrice?['maxPrice'] ?? aiMaxD;
      final singlePrice = bestPrice ?? maxPriceVal ?? minPriceVal;

      if (singlePrice != null) {
        _maxPriceController.text = (singlePrice as num).toStringAsFixed(0);
      }
      if (minPriceVal != null) {
        _minPriceController.text = (minPriceVal as num).toStringAsFixed(0);
      }

      if (petType.isNotEmpty) {
        _petTypeController.text = petType;
      }

      if (description.isNotEmpty) {
        _highlightsController.text = description;
        _generatedDescription = description;
        _lastAnalysisUsedImage = true;
      }

      if (mounted) {
        setState(() {
          _scrapedPriceDetails = scrapedPrice;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI önerileri uygulandı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI hatası: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _buildPriceQuery({
    required String brand,
    required String title,
    required String adminSize,
    String? category,
  }) {
    var cleanBrand = brand.trim();
    var cleanTitle = title.trim();
    var cleanSize = adminSize.trim();
    var cleanCategory = category?.trim() ?? '';

    // Eğer brand null ama title içinde Bonnie geçiyorsa brand = Bonnie olarak set edilsin.
    if ((cleanBrand.isEmpty || cleanBrand.toLowerCase() == 'null') &&
        cleanTitle.toLowerCase().contains('bonnie')) {
      cleanBrand = 'Bonnie';
    }

    // Deduplicate Brand inside Title if prepended
    if (cleanBrand.isNotEmpty && cleanBrand.toLowerCase() != 'null') {
      final brandLower = cleanBrand.toLowerCase();
      if (cleanTitle.toLowerCase().startsWith(brandLower)) {
        cleanTitle = cleanTitle.substring(cleanBrand.length).trim();
      }
    }

    // Deduplicate Category inside Title to avoid category repetitions
    if (cleanCategory.isNotEmpty) {
      cleanTitle = _deduplicateSubstring(cleanTitle, cleanCategory);
    }

    // Deduplicate Size inside Title to ensure it is added only once
    if (cleanSize.isNotEmpty) {
      cleanTitle = _deduplicateSubstring(cleanTitle, cleanSize);
    }

    // Format: brand + title + size
    final parts = <String>[
      if (cleanBrand.isNotEmpty && cleanBrand.toLowerCase() != 'null')
        cleanBrand,
      if (cleanTitle.isNotEmpty) cleanTitle,
      if (cleanSize.isNotEmpty) cleanSize,
    ];

    var finalQuery = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Final safety deduplications on the concatenated query
    if (cleanSize.isNotEmpty) {
      finalQuery = _deduplicateSubstring(finalQuery, cleanSize);
    }
    if (cleanCategory.isNotEmpty) {
      finalQuery = _deduplicateSubstring(finalQuery, cleanCategory);
    }

    return finalQuery;
  }

  String _deduplicateSubstring(String text, String sub) {
    if (sub.isEmpty || text.isEmpty) return text;
    final subLower = sub.toLowerCase();
    int firstIdx = text.toLowerCase().indexOf(subLower);
    if (firstIdx == -1) return text;

    final keepEnd = firstIdx + sub.length;
    String firstPart = text.substring(0, keepEnd);
    String remainingPart = text.substring(keepEnd);

    String cleanedRemaining = remainingPart.replaceAllMapped(
      RegExp(RegExp.escape(sub), caseSensitive: false),
      (match) => '',
    );

    return (firstPart + cleanedRemaining)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _createAndSelectAiCategory(String aiCategory) async {
    final normalizedName = aiCategory.trim();
    if (normalizedName.isEmpty) return;

    final auth = context.read<AuthService>();
    final categoryService = CategoryService(auth);
    final createError = await categoryService.createCategory(
      name: normalizedName,
      description: 'AI tarafindan otomatik eklendi.',
    );

    if (!mounted) return;

    if (createError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI kategori onerisi eslesmedi. Yeni kategori olusturulamadi: $createError',
          ),
        ),
      );
      return;
    }

    await _loadCategories();
    if (!mounted) return;

    if (_categoryOptions.contains(normalizedName)) {
      setState(() => _selectedCategory = normalizedName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni kategori eklendi: $normalizedName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yeni kategori eklendi fakat secim icin listede bulunamadi, lutfen manuel secin.',
          ),
        ),
      );
    }
  }

  String _findClosestCategory(String suggestion) {
    if (_categoryOptions.isEmpty) return '';

    final normalizedSuggestion = _normalizeText(suggestion);
    if (normalizedSuggestion.isEmpty) return '';

    String best = '';
    double bestScore = -1;

    for (final option in _categoryOptions) {
      final normalizedOption = _normalizeText(option);
      if (normalizedOption.isEmpty) continue;

      final score = _categorySimilarity(normalizedSuggestion, normalizedOption);
      if (score > bestScore) {
        bestScore = score;
        best = option;
      }
    }

    if (bestScore < _minCategoryMatchScore) {
      return '';
    }

    return best;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _categorySimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.contains(b) || b.contains(a)) return 0.92;

    final aTokens = a.split(' ').where((t) => t.isNotEmpty).toSet();
    final bTokens = b.split(' ').where((t) => t.isNotEmpty).toSet();
    final union = aTokens.union(bTokens).length;
    final intersect = aTokens.intersection(bTokens).length;
    final tokenScore = union == 0 ? 0.0 : intersect / union;

    final distance = _levenshteinDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final distanceScore = maxLen == 0 ? 1.0 : 1.0 - (distance / maxLen);

    return (tokenScore * 0.6) + (distanceScore * 0.4);
  }

  int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        final deletion = v0[j + 1] + 1;
        final insertion = v1[j] + 1;
        final substitution = v0[j] + cost;
        var min = deletion < insertion ? deletion : insertion;
        if (substitution < min) min = substitution;
        v1[j + 1] = min;
      }
      for (var j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[t.length];
  }

  Widget _buildPriceDetailsWidget(BuildContext context, ColorScheme cs) {
    if (_scrapedPriceDetails == null) return const SizedBox.shrink();

    final minPrice = _scrapedPriceDetails!['minPrice'];
    final maxPrice = _scrapedPriceDetails!['maxPrice'];
    final medianPrice = _scrapedPriceDetails!['medianPrice'];
    final suggestedPrice = _scrapedPriceDetails!['suggestedPrice'];
    final quickSalePrice = _scrapedPriceDetails!['quickSalePrice'];
    final premiumPrice = _scrapedPriceDetails!['premiumPrice'];
    final confidence = _scrapedPriceDetails!['confidence'];
    final sampleCount = _scrapedPriceDetails!['sampleCount'];

    String formatPrice(dynamic value) {
      if (value == null) return '-';
      if (value is num) {
        return '${value.toStringAsFixed(0)} TL';
      }
      return '$value TL';
    }

    String formatConfidence(dynamic value) {
      if (value == null) return '-';
      if (value is num) {
        if (value <= 1.0) {
          return '${(value * 100).toStringAsFixed(0)}%';
        }
        return '${value.toStringAsFixed(0)}%';
      }
      return value.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.secondaryContainer.withValues(alpha: 0.1),
            cs.tertiaryContainer.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Piyasa Fiyat Analizi Detayları',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                childAspectRatio: isWide ? 2.0 : 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildPriceItem(
                    label: 'Önerilen Fiyat',
                    value: formatPrice(suggestedPrice),
                    icon: Icons.auto_awesome,
                    color: cs.primary,
                    isHighlighted: true,
                  ),
                  _buildPriceItem(
                    label: 'Medyan Fiyat',
                    value: formatPrice(medianPrice),
                    icon: Icons.star_border,
                    color: Colors.amber.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Minimum Fiyat',
                    value: formatPrice(minPrice),
                    icon: Icons.trending_down,
                    color: Colors.red.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Maksimum Fiyat',
                    value: formatPrice(maxPrice),
                    icon: Icons.trending_up,
                    color: Colors.green.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Hızlı Satış',
                    value: formatPrice(quickSalePrice),
                    icon: Icons.bolt,
                    color: Colors.orange.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Üst Fiyat',
                    value: formatPrice(premiumPrice),
                    icon: Icons.diamond_outlined,
                    color: Colors.purple.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Güven Derecesi',
                    value: formatConfidence(confidence),
                    icon: Icons.verified_user_outlined,
                    color: Colors.teal.shade700,
                  ),
                  _buildPriceItem(
                    label: 'Kaynak Sayısı',
                    value: sampleCount?.toString() ?? '-',
                    icon: Icons.tag,
                    color: Colors.blueGrey.shade700,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? color.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isHighlighted
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 14 : 13,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
                color: isHighlighted ? color : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
