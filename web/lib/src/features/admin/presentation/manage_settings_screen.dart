import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../models/store_settings_model.dart';
import '../../../models/product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/product_service.dart';

class ManageSettingsScreen extends StatefulWidget {
  const ManageSettingsScreen({super.key});

  @override
  State<ManageSettingsScreen> createState() => _ManageSettingsScreenState();
}

class _ManageSettingsScreenState extends State<ManageSettingsScreen> {
  late SettingsService _settingsService;
  late ProductService _productService;
  
  bool _isLoading = true;
  bool _isSaving = false;

  List<String> _availableCategories = [];
  List<String> _availableBrands = [];

  List<String> _selectedCategories = [];
  List<String> _selectedBrands = [];

  final _customCategoryController = TextEditingController();
  final _customBrandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _settingsService = SettingsService(auth);
    _productService = ProductService(auth);
    _loadSettings();
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _customBrandController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  String? _extractBrand(String title) {
    final t = _normalize(title);
    const brands = <String, String>{
      'royal canin': 'Royal Canin',
      'pro plan': 'Pro Plan',
      'purina': 'Purina',
      'n&d': 'N&D',
      'hills': "Hill's",
      'brit care': 'Brit Care',
      'acana': 'Acana',
      'gimcat': 'GimCat',
      'wanpy': 'Wanpy',
      'catlife': 'Catlife',
      'pedigree': 'Pedigree',
      'whiskas': 'Whiskas',
      'reflex': 'Reflex',
      'felicia': 'Felicia',
      'mystic': 'Mystic'
    };

    for (final entry in brands.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return null;
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.getSettings();
      _selectedCategories = settings.popularCategories.toList();
      _selectedBrands = settings.popularBrands.toList();

      final products = await _productService.getAdminProducts();
      final catSet = <String>{};
      final brandSet = <String>{};

      for (var p in products) {
        if (p.category != null && p.category!.isNotEmpty) {
          catSet.add(p.category!.trim());
        }
        final brand = _extractBrand(p.title);
        if (brand != null) {
          brandSet.add(brand);
        }
      }

      _availableCategories = catSet.toList()..sort();
      _availableBrands = brandSet.toList()..sort();
      
      // Ensure selected items are also in available items even if products deleted
      for (var c in _selectedCategories) {
        if (!_availableCategories.contains(c)) _availableCategories.add(c);
      }
      for (var b in _selectedBrands) {
        if (!_availableBrands.contains(b)) _availableBrands.add(b);
      }

    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final model = StoreSettingsModel(
      popularCategories: _selectedCategories,
      popularBrands: _selectedBrands,
    );

    final error = await _settingsService.updateSettings(model);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayarlar başarıyla kaydedildi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mağaza Arama Ayarları',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kullanıcıların arama kutusunda göreceği popüler marka ve kategorileri buradan seçebilirsiniz.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 24),
          
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popüler Kategoriler',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedCategories.length == _availableCategories.length) {
                            _selectedCategories.clear();
                          } else {
                            _selectedCategories = List.from(_availableCategories);
                          }
                        });
                      },
                      child: Text(_selectedCategories.length == _availableCategories.length ? 'Tümünü Temizle' : 'Tümünü Seç'),
                    )
                  ],
                ),
                const Text(
                  'Mağazanızda bulunan kategorilerden öne çıkarmak istediklerinizi seçin.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_availableCategories.isEmpty)
                  const Text('Henüz kategorili ürün yok.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCategories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          hintText: 'Listede olmayan bir kategori ekle...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final val = _customCategoryController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            if (!_availableCategories.contains(val)) _availableCategories.add(val);
                            if (!_selectedCategories.contains(val)) _selectedCategories.add(val);
                            _customCategoryController.clear();
                          });
                        }
                      },
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popüler Markalar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedBrands.length == _availableBrands.length) {
                            _selectedBrands.clear();
                          } else {
                            _selectedBrands = List.from(_availableBrands);
                          }
                        });
                      },
                      child: Text(_selectedBrands.length == _availableBrands.length ? 'Tümünü Temizle' : 'Tümünü Seç'),
                    )
                  ],
                ),
                const Text(
                  'Ürün isimlerinizden otomatik algılanan markalardan öne çıkarmak istediklerinizi seçin.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_availableBrands.isEmpty)
                  const Text('Henüz markalı ürün algılanmadı.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableBrands.map((brand) {
                      final isSelected = _selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBrands.add(brand);
                            } else {
                              _selectedBrands.remove(brand);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customBrandController,
                        decoration: const InputDecoration(
                          hintText: 'Listede olmayan bir marka ekle...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final val = _customBrandController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            if (!_availableBrands.contains(val)) _availableBrands.add(val);
                            if (!_selectedBrands.contains(val)) _selectedBrands.add(val);
                            _customBrandController.clear();
                          });
                        }
                      },
                      child: const Text('Ekle'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Ayarları Kaydet', style: TextStyle(fontSize: 16)),
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
