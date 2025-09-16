import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/preset_category.dart';
import '../models/timer_config.dart';
import '../models/timer_preset.dart';
import '../services/preset_storage_service.dart';

class PresetScreen extends StatefulWidget {
  final TimerConfig? currentConfig;
  final Function(TimerPreset)? onPresetSelected;

  const PresetScreen({super.key, this.currentConfig, this.onPresetSelected});

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PresetStorageService _storageService = PresetStorageService();

  List<TimerPreset> _allPresets = [];
  List<TimerPreset> _recentlyUsed = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPresets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    setState(() => _isLoading = true);

    try {
      await _storageService.initialize();
      final allPresets = await _storageService.getAllPresets();
      final recentlyUsed = await _storageService.getRecentlyUsedPresets();

      setState(() {
        _allPresets = allPresets;
        _recentlyUsed = recentlyUsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load presets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Timer Presets',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.currentConfig != null)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _showSavePresetDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Recent', icon: Icon(Icons.history)),
            Tab(text: 'Beginner', icon: Icon(Icons.child_care)),
            Tab(text: 'Intermediate', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Advanced', icon: Icon(Icons.whatshot)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPresetList(_recentlyUsed, 'Recently Used'),
                _buildPresetList(
                  _allPresets
                      .where((p) => p.category == PresetCategory.beginner)
                      .toList(),
                  'Beginner Presets',
                ),
                _buildPresetList(
                  _allPresets
                      .where((p) => p.category == PresetCategory.intermediate)
                      .toList(),
                  'Intermediate Presets',
                ),
                _buildPresetList(
                  _allPresets
                      .where((p) => p.category == PresetCategory.advanced)
                      .toList(),
                  'Advanced Presets',
                ),
              ],
            ),
    );
  }

  Widget _buildPresetList(List<TimerPreset> presets, String title) {
    if (presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No presets available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title == 'Recently Used'
                  ? 'Use some presets to see them here'
                  : 'Check back later for new presets',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return _buildPresetCard(preset);
      },
    );
  }

  Widget _buildPresetCard(TimerPreset preset) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(preset.category.colorValue),
          child: Text(
            preset.category.iconName,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          preset.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preset.description,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            _buildPresetDetails(preset),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!preset.isDefault)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(preset),
              ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _selectPreset(preset),
            ),
          ],
        ),
        onTap: () => _selectPreset(preset),
      ),
    );
  }

  Widget _buildPresetDetails(TimerPreset preset) {
    final config = preset.timerConfig;
    final workTime = _formatDuration(config.workDuration);
    final restTime = _formatDuration(config.restDuration);

    return Text(
      '${config.mode.displayName} • $workTime work / $restTime rest • ${config.rounds} rounds',
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
    );
  }

  void _selectPreset(TimerPreset preset) async {
    try {
      // Mark as used
      await _storageService.markPresetAsUsed(preset.id);

      // Notify parent
      if (widget.onPresetSelected != null) {
        widget.onPresetSelected!(preset);
      }

      // Navigate back
      Navigator.of(context).pop();

      _showSuccessSnackBar('Selected preset: ${preset.name}');
    } catch (e) {
      _showErrorSnackBar('Failed to select preset: $e');
    }
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    PresetCategory selectedCategory = PresetCategory.custom;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Save Current Timer',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Preset Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PresetCategory>(
                value: selectedCategory,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: PresetCategory.values
                    .where(
                      (category) => category != PresetCategory.recentlyUsed,
                    )
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => _savePreset(
                nameController.text,
                descriptionController.text,
                selectedCategory,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _savePreset(
    String name,
    String description,
    PresetCategory category,
  ) async {
    if (name.isEmpty || description.isEmpty) {
      _showErrorSnackBar('Name and description are required');
      return;
    }

    if (widget.currentConfig == null) {
      _showErrorSnackBar('No timer configuration to save');
      return;
    }

    try {
      final preset = TimerPreset(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        category: category,
        timerConfig: widget.currentConfig!,
        createdAt: DateTime.now(),
      );

      final success = await _storageService.savePreset(preset);
      if (success) {
        Navigator.of(context).pop(); // Close dialog
        await _loadPresets(); // Refresh list
        _showSuccessSnackBar('Preset saved successfully');
      } else {
        _showErrorSnackBar('Failed to save preset');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving preset: $e');
    }
  }

  void _showDeleteDialog(TimerPreset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Preset',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${preset.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deletePreset(preset),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePreset(TimerPreset preset) async {
    try {
      final success = await _storageService.deletePreset(preset.id);
      if (success) {
        Navigator.of(context).pop(); // Close dialog
        await _loadPresets(); // Refresh list
        _showSuccessSnackBar('Preset deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete preset');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting preset: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
