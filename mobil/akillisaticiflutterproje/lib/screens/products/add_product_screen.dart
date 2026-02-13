import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../core/constants/api_constants.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/utils/platform_image.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _titleCtrl = TextEditingController();
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

  Uint8List? _webImageBytes;
  String? _imagePath;
  bool _isAnalyzing = false;
  bool _showAiSuggestions = false;
  Map<String, String> _aiSuggestions = {};
  Timer? _aiDebounce;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imagePath = null;
        });
      } else {
        setState(() {
          _imagePath = pickedFile.path;
          _webImageBytes = null;
        });
      }
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
      if (!_isAnalyzing) _startAIAnalysis();
    });
  }

  void _triggerAIIfReady() {
    final hasImage = _imagePath != null || _webImageBytes != null;
    final hasTitle = _titleCtrl.text.trim().isNotEmpty;
    if ((hasImage || hasTitle) && !_isAnalyzing) {
      _startAIAnalysis();
    }
  }

  Future<void> _startAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _showAiSuggestions = false;
    });

    try {
      final uri = Uri.parse(
        '${ApiConstants.aiBaseUrl}${ApiConstants.aiSuggest}',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleCtrl.text,
          'imageBase64':
              kIsWeb && _webImageBytes != null
                  ? base64Encode(_webImageBytes!)
                  : null,
          'category': _selectedCategory.isEmpty ? null : _selectedCategory,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiSuggestions = {
            'description': (data['description'] ?? '').toString(),
            'price': (data['priceRange'] ?? '').toString(),
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
      imageUrl: kIsWeb ? '' : (_imagePath ?? ''),
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      priceRange: _priceCtrl.text,
      category: _selectedCategory,
      isDraft: draft,
      aiGenerated: _showAiSuggestions,
      webImageBytes: kIsWeb ? _webImageBytes : null, // WEB BYTES
    );
    Navigator.pop(context, newProduct);
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid =
        _titleCtrl.text.isNotEmpty &&
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
                          _imagePath != null || _webImageBytes != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child:
                                        kIsWeb
                                            ? Image.memory(_webImageBytes!)
                                            : buildFileImage(_imagePath!),
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
