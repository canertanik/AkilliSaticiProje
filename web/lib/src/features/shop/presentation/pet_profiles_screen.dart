import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/pet_profile_service.dart';
import '../../../models/pet_profile_model.dart';
import 'package:go_router/go_router.dart';

class PetProfilesScreen extends StatefulWidget {
  const PetProfilesScreen({super.key});

  @override
  State<PetProfilesScreen> createState() => _PetProfilesScreenState();
}

class _PetProfilesScreenState extends State<PetProfilesScreen> {
  late PetProfileService _petService;
  List<PetProfileModel> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _petService = PetProfileService(context.read<AuthService>());
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final pets = await _petService.getMyPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showPetDialog([PetProfileModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final speciesCtrl = TextEditingController(
      text: existing?.species ?? 'Köpek',
    );
    final breedCtrl = TextEditingController(text: existing?.breed);
    final ageYearsCtrl = TextEditingController(
      text: existing?.ageYears.toString() ?? '0',
    );
    final ageMonthsCtrl = TextEditingController(
      text: existing?.ageMonths.toString() ?? '0',
    );
    final weightCtrl = TextEditingController(
      text: existing?.weightKg?.toString() ?? '',
    );
    bool isNeutered = existing?.isNeutered ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> save() async {
              if (nameCtrl.text.trim().isEmpty) return;

              final data = {
                'name': nameCtrl.text.trim(),
                'species': speciesCtrl.text.trim(),
                'breed': breedCtrl.text.trim(),
                'ageYears': int.tryParse(ageYearsCtrl.text.trim()) ?? 0,
                'ageMonths': int.tryParse(ageMonthsCtrl.text.trim()) ?? 0,
                'weightKg': double.tryParse(
                  weightCtrl.text.trim().replaceAll(',', '.'),
                ),
                'isNeutered': isNeutered,
              };

              try {
                if (existing == null) {
                  await _petService.createPet(data);
                } else {
                  await _petService.updatePet(existing.id, data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadPets();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            }

            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Yeni Evcil Hayvan Ekle'
                    : 'Evcil Hayvanı Düzenle',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Adı *'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          speciesCtrl.text.isNotEmpty
                              ? speciesCtrl.text
                              : 'Köpek',
                      decoration: const InputDecoration(labelText: 'Türü *'),
                      items: const [
                        DropdownMenuItem(value: 'Köpek', child: Text('Köpek')),
                        DropdownMenuItem(value: 'Kedi', child: Text('Kedi')),
                        DropdownMenuItem(value: 'Kuş', child: Text('Kuş')),
                        DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                      ],
                      onChanged:
                          (v) => setDialogState(() => speciesCtrl.text = v!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: breedCtrl,
                      decoration: const InputDecoration(labelText: 'Irkı'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageYearsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Yaş (Yıl)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ageMonthsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ay'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Kısırlaştırılmış'),
                      value: isNeutered,
                      onChanged: (v) => setDialogState(() => isNeutered = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(onPressed: save, child: const Text('Kaydet')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePet(PetProfileModel pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Emin misiniz?'),
            content: Text('${pet.name} silinecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _petService.deletePet(pet.id);
      _loadPets();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final pawPoints = user?.pawPoints ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvan Profilim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pati Puan Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF004D40)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pati Puan Bakiyeniz',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$pawPoints Puan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kayıtlı Hayvanlarım',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showPetDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_pets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz bir evcil hayvan eklemediniz.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._pets.map(
                      (pet) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Icon(
                              pet.species == 'Kedi' ? Icons.pets : Icons.pets,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            pet.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${pet.species} • ${pet.breed ?? "Bilinmiyor"} • ${pet.ageYears} Yıl ${pet.ageMonths} Ay\n${pet.weightKg != null ? "${pet.weightKg} kg • " : ""}${pet.isNeutered ? "Kısırlaştırılmış" : "Kısırlaştırılmamış"}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showPetDialog(pet),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePet(pet),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
