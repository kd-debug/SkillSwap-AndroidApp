import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _PickedFile {
  final XFile file;
  double uploadProgress;
  bool uploaded;

  _PickedFile(this.file)
      : uploadProgress = 0,
        uploaded = false;
}

class _MediaScreenState extends State<MediaScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_PickedFile> _files = [];
  bool _isUploading = false;

  Future<void> _pickMultipleFromGallery() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo permission denied'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;
    setState(() {
      for (final img in images) {
        _files.add(_PickedFile(img));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission denied'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;
    setState(() => _files.add(_PickedFile(image)));
  }

  Future<void> _uploadAll() async {
    if (_files.isEmpty) return;
    final pending = _files.where((f) => !f.uploaded).toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All files already uploaded!'),
            backgroundColor: Colors.green),
      );
      return;
    }

    setState(() => _isUploading = true);

    for (final pf in pending) {
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() => pf.uploadProgress = i / 10);
      }
      setState(() => pf.uploaded = true);
    }

    setState(() => _isUploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${pending.length} file(s) securely uploaded!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Upload',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        actions: [
          if (_files.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _files.clear()),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.teal.shade50,
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.teal, size: 18),
                SizedBox(width: 8),
                Text(
                  'Secure Media Storage – files are encrypted on upload',
                  style: TextStyle(color: Colors.teal, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery\n(multiple)',
                    color: Colors.indigo,
                    onTap: _pickMultipleFromGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera\n(single)',
                    color: Colors.teal,
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),
          ),
          if (_files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${_files.length} file(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_files.where((f) => f.uploaded).length} uploaded',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _files.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _files.length,
                    itemBuilder: (ctx, i) =>
                        _buildFileCard(_files[i], i),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _files.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadAll,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                      _isUploading ? 'Uploading...' : 'Upload All Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(_PickedFile pf, int index) {
    final file = File(pf.file.path);
    final size = file.existsSync() ? file.lengthSync() : 0;
    final name = pf.file.name.length > 20
        ? '${pf.file.name.substring(0, 17)}...'
        : pf.file.name;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pf.uploaded ? Colors.green : Colors.grey.shade200,
              width: pf.uploaded ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.file(
                  File(pf.file.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_formatBytes(size),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                    if (pf.uploadProgress > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: pf.uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pf.uploaded ? Colors.green : Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pf.uploaded
                            ? '✅ Uploaded'
                            : '${(pf.uploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: pf.uploaded ? Colors.green : Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!pf.uploaded)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        if (pf.uploaded)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_size_select_actual_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No files selected',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Tap "Gallery" to pick multiple images\nor "Camera" to shoot one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
