import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../core/constants/api_constants.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/utils/platform_image.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _titleCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _selectedCategory = '';
  final List<String> _categories = [
    'Elektronik',
    'Giyim',
    'Ayakkabı & Çanta',
    'Aksesuar',
    'Ev & Yaşam',
    'Kozmetik',
  ];

  String? _imagePath;
  bool _isAnalyzing = false;
  bool _showAiSuggestions = false;
  Map<String, String> _aiSuggestions = {};
  Timer? _aiDebounce;

  bool get _hasImage => _imagePath != null;

  bool _canRunAI({bool showWarning = false}) {
    final hasTitle = _titleCtrl.text.trim().isNotEmpty;
    final hasWeight = _weightCtrl.text.trim().isNotEmpty;
    final missing = <String>[];

    if (!_hasImage) missing.add('resim');
    if (!hasTitle) missing.add('başlık');
    if (!hasWeight) missing.add('ağırlık');

    if (missing.isEmpty) return true;

    if (showWarning && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI analizi için ${missing.join(', ')} zorunlu.'),
        ),
      );
    }

    return false;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      _triggerAIIfReady();
    }
  }

  void _onTitleChanged() {
    final hasTitle = _titleCtrl.text.trim().isNotEmpty;
    if (!hasTitle) {
      if (_showAiSuggestions || _isAnalyzing) {
        setState(() {
          _showAiSuggestions = false;
          _isAnalyzing = false;
        });
      }
      return;
    }
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (!_isAnalyzing && _canRunAI(showWarning: true)) _startAIAnalysis();
    });
  }

  void _onWeightChanged() {
    if (_weightCtrl.text.trim().isEmpty) return;
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (!_isAnalyzing && _canRunAI(showWarning: true)) _startAIAnalysis();
    });
  }

  void _triggerAIIfReady() {
    if (!_isAnalyzing && _canRunAI(showWarning: true)) {
      _startAIAnalysis();
    }
  }

  Future<void> _startAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _showAiSuggestions = false;
    });

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiSuggest}');
      String? imageBase64;
      if (_imagePath != null) {
        try {
          final bytes = await File(_imagePath!).readAsBytes();
          imageBase64 = base64Encode(bytes);
        } catch (_) {
          imageBase64 = null;
        }
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleCtrl.text,
          'size': _weightCtrl.text.trim(),
          'imageBase64': imageBase64,
          'category': _selectedCategory.isEmpty ? null : _selectedCategory,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final suggestedTitle = (data['title'] ?? '').toString().trim();
        final brand = (data['brand'] ?? '').toString().trim();
        final sizeValue = _weightCtrl.text.trim();
        final category = (data['category'] ?? '').toString().trim();

        if (suggestedTitle.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI ürün başlığı çıkaramadı, fiyat analizi yapılamadı.')),
            );
          }
          setState(() {
            _aiSuggestions = {
              'description': (data['description'] ?? '').toString(),
              'price': (data['priceRange'] ?? '').toString(),
              'category': (data['category'] ?? '').toString(),
            };
            _showAiSuggestions = true;
          });
          if (mounted) {
            setState(() => _isAnalyzing = false);
          }
          return;
        }

        Map<String, dynamic>? scrapedPrice;
        try {
          final scrapeUri = Uri.parse('${ApiConstants.baseUrl}/api/ai/price-scrape');
          final priceQuery = _buildPriceQuery(
            brand: brand,
            title: suggestedTitle,
            adminSize: sizeValue,
            category: category.isNotEmpty ? category : _selectedCategory,
          );

          debugPrint("AI BRAND => $brand");
          debugPrint("AI TITLE => $suggestedTitle");
          debugPrint("ADMIN SIZE => $sizeValue");
          debugPrint("PRICE QUERY => $priceQuery");

          final scrapeResp = await http.post(
            scrapeUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': priceQuery,
              'category': category.isNotEmpty ? category : _selectedCategory,
              'weight': sizeValue,
              'brand': brand.isNotEmpty ? brand : null,
            }),
          );
          if (scrapeResp.statusCode >= 200 && scrapeResp.statusCode < 300) {
            scrapedPrice = jsonDecode(scrapeResp.body);
          }
        } catch (_) {
          scrapedPrice = null;
        }

        final suggested = scrapedPrice?['suggestedPrice'];
        final median = scrapedPrice?['medianPrice'];
        final mode = scrapedPrice?['modePrice'];

        final selectedPrice = suggested ?? median ?? mode;
        String priceStr = '';
        if (selectedPrice != null) {
          priceStr = (selectedPrice as num).toStringAsFixed(0);
        }

        setState(() {
          _aiSuggestions = {
            'description': (data['description'] ?? '').toString(),
            'price': priceStr.isNotEmpty ? priceStr : (data['priceRange'] ?? '').toString(),
            'category': (data['category'] ?? '').toString(),
          };
          _showAiSuggestions = true;
        });
      } else {
        _applyLocalAiSuggestions();
      }
    } catch (_) {
      _applyLocalAiSuggestions();
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
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

    if ((cleanBrand.isEmpty || cleanBrand.toLowerCase() == 'null') &&
        cleanTitle.toLowerCase().contains('bonnie')) {
      cleanBrand = 'Bonnie';
    }

    if (cleanBrand.isNotEmpty && cleanBrand.toLowerCase() != 'null') {
      final brandLower = cleanBrand.toLowerCase();
      if (cleanTitle.toLowerCase().startsWith(brandLower)) {
        cleanTitle = cleanTitle.substring(cleanBrand.length).trim();
      }
    }

    if (cleanCategory.isNotEmpty) {
      cleanTitle = _deduplicateSubstring(cleanTitle, cleanCategory);
    }

    if (cleanSize.isNotEmpty) {
      cleanTitle = _deduplicateSubstring(cleanTitle, cleanSize);
    }

    final parts = <String>[
      if (cleanBrand.isNotEmpty && cleanBrand.toLowerCase() != 'null') cleanBrand,
      if (cleanTitle.isNotEmpty) cleanTitle,
      if (cleanSize.isNotEmpty) cleanSize,
    ];

    var finalQuery = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

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

    return (firstPart + cleanedRemaining).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _applyLocalAiSuggestions() {
    final local = _buildLocalSuggestions();
    setState(() {
      _aiSuggestions = local;
      _showAiSuggestions = true;
    });
  }

  Map<String, String> _buildLocalSuggestions() {
    final title = _titleCtrl.text.toLowerCase();
    if (title.contains('ayakkabı') || title.contains('spor')) {
      return {
        'description':
            'Rahat ve şık tasarıma sahip, uzun süreli kullanım için dayanıklı spor ayakkabı. Günlük kullanım ve spor aktiviteleri için idealdir.',
        'price': '₺650 - ₺850',
        'category': 'Ayakkabı & Çanta',
      };
    }
    if (title.contains('kulaklık') || title.contains('elektronik')) {
      return {
        'description':
            'Yüksek kaliteli ses deneyimi sunan, kablosuz bağlantı özelliğine sahip kulaklık. Uzun pil ömrü ve konforlu kullanım.',
        'price': '₺350 - ₺550',
        'category': 'Elektronik',
      };
    }
    if (title.contains('tişört') || title.contains('gömlek')) {
      return {
        'description':
            'Kaliteli kumaştan üretilmiş, rahat kesime sahip günlük giyim ürünü. Farklı kombinlerle rahatlıkla kullanılabilir.',
        'price': '₺180 - ₺280',
        'category': 'Giyim',
      };
    }
    if (title.contains('çanta') || title.contains('cüzdan')) {
      return {
        'description':
            'Şık ve fonksiyonel tasarıma sahip, günlük kullanım için ideal aksesuar. Geniş iç hacmi ile tüm eşyalarınızı rahatlıkla taşıyabilirsiniz.',
        'price': '₺250 - ₺400',
        'category': 'Ayakkabı & Çanta',
      };
    }
    if (title.contains('saat') || title.contains('kolye')) {
      return {
        'description':
            'Zarif ve modern tasarıma sahip aksesuar. Her tarz kıyafete uyum sağlar. Kaliteli malzemeden üretilmiştir.',
        'price': '₺150 - ₺300',
        'category': 'Aksesuar',
      };
    }
    if (title.contains('parfüm') || title.contains('makyaj')) {
      return {
        'description':
            'Kaliteli içerik formülü ile cildinize özen gösterir. Uzun süreli kullanım için idealdir. Dermatolojik olarak test edilmiştir.',
        'price': '₺200 - ₺350',
        'category': 'Kozmetik',
      };
    }
    return {
      'description':
          '${_titleCtrl.text} ürünü, yüksek kalite standartlarında üretilmiştir. Günlük kullanım için idealdir ve uzun ömürlü kullanım sağlar.',
      'price': '₺200 - ₺500',
      'category': 'Ev & Yaşam',
    };
  }

  void _applySuggestion(String key) {
    setState(() {
      if (key == 'description') {
        _descriptionCtrl.text = _aiSuggestions['description']!;
      }
      if (key == 'price') _priceCtrl.text = _aiSuggestions['price']!;
      if (key == 'category') {
        final cat = _aiSuggestions['category']!;
        if (cat.isNotEmpty && !_categories.contains(cat)) {
          _categories.add(cat);
        }
        _selectedCategory = cat;
      }
    });
  }

  void _applyAllSuggestions() {
    setState(() {
      _descriptionCtrl.text = _aiSuggestions['description']!;
      _priceCtrl.text = _aiSuggestions['price']!;
      final cat = _aiSuggestions['category']!;
      if (cat.isNotEmpty && !_categories.contains(cat)) {
        _categories.add(cat);
      }
      _selectedCategory = cat;
    });
  }

  _saveProduct({required bool draft}) {
    final newProduct = Product(
      id: const Uuid().v4(),
      imageUrl: (_imagePath ?? ''),
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      priceRange: _priceCtrl.text,
      category: _selectedCategory,
      isDraft: draft,
      aiGenerated: _showAiSuggestions,
      webImageBytes: null,
    );
    Navigator.pop(context, newProduct);
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _titleCtrl.dispose();
    _weightCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid =
        _hasImage &&
        _titleCtrl.text.isNotEmpty &&
        _weightCtrl.text.isNotEmpty &&
        _descriptionCtrl.text.isNotEmpty &&
        _priceCtrl.text.isNotEmpty &&
        _selectedCategory.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            height: 120,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Yeni Ürün Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fotoğraf Yükleme
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2D9FF)),
                      ),
                      child:
                          _imagePath != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: buildFileImage(_imagePath!),
                                  ),
                                ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.cloud_upload,
                                    size: 40,
                                    color: Color(0xFFB658FF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Fotoğraf Yükle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Dokunarak resim seç',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık
                  const Text(
                    'Ürün Başlığı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    onChanged: (_) => _onTitleChanged(),
                    decoration: const InputDecoration(
                      hintText:
                          'Örn: Premium Spor Ayakkabı (Başlık Girmek Zorunlu )',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Ağırlık',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _weightCtrl,
                    onChanged: (_) => _onWeightChanged(),
                    decoration: const InputDecoration(
                      hintText: 'Örn: 10kg, 500g, 1 litre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Analiz
                  if (_isAnalyzing)
                    const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('AI analiz yapıyor...'),
                      subtitle: Text(
                        'Fotoğraf ve başlığa göre öneriler hazırlanıyor',
                      ),
                    ),

                  // AI Öneri Kutusu
                  if (_showAiSuggestions && !_isAnalyzing) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2D9FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFB658FF),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'AI Önerileri Hazır!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _suggestionTile(
                            'Açıklama',
                            _aiSuggestions['description']!,
                            'description',
                          ),
                          const SizedBox(height: 8),
                          _suggestionTile(
                            'Fiyat Aralığı',
                            _aiSuggestions['price']!,
                            'price',
                          ),
                          const SizedBox(height: 8),
                          _suggestionTile(
                            'Kategori',
                            _aiSuggestions['category']!,
                            'category',
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            text: 'Tümünü Uygula',
                            onPressed: _applyAllSuggestions,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Form Alanları
                  const Text(
                    'Açıklama',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ürünün özelliklerini anlat...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Fiyat Aralığı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      hintText: '₺500 - ₺700',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                    items:
                        _categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() => _selectedCategory = val!),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradientButton(
              text: 'Hemen Yayınla',
              onPressed: isValid ? () => _saveProduct(draft: false) : () {},
              enabled: isValid,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isValid ? () => _saveProduct(draft: true) : () {},
              child: const Text('Taslak Olarak Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionTile(String label, String value, String key) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('$label: $value')),
          TextButton(
            onPressed: () => _applySuggestion(key),
            child: const Text('Kullan'),
          ),
        ],
      ),
    );
  }
}
