import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MaddyApp());

const gold = Color(0xFFD7AE55);
const bg = Color(0xFF090909);
const panel = Color(0xFF171717);

class MaddyApp extends StatelessWidget {
  const MaddyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maddy AI Studio',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const StudioHome(),
    );
  }
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});
  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  final promptController = TextEditingController();
  final keyController = TextEditingController();
  final picker = ImagePicker();
  XFile? selected;
  String? resultBase64;
  bool busy = false;
  String status = 'Describe the image you want to create.';
  String mode = 'create';

  Future<void> chooseImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file != null) setState(() { selected = file; mode = 'edit'; status = 'Photo selected. Describe your edit.'; });
  }

  Future<void> generate() async {
    final apiKey = keyController.text.trim();
    final prompt = promptController.text.trim();
    if (apiKey.isEmpty) { setState(() => status = 'Enter your Gemini API key first.'); return; }
    if (prompt.isEmpty) { setState(() => status = 'Please write a prompt.'); return; }
    if (mode == 'edit' && selected == null) { setState(() => status = 'Choose a photo to edit first.'); return; }

    setState(() { busy = true; status = 'Creating your image…'; resultBase64 = null; });
    try {
      final parts = <Map<String, dynamic>>[];
      if (mode == 'edit' && selected != null) {
        final bytes = await File(selected!.path).readAsBytes();
        final ext = selected!.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        parts.add({'inline_data': {'mime_type': ext, 'data': base64Encode(bytes)}});
      }
      parts.add({'text': prompt});

      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image:generateContent');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: jsonEncode({
          'contents': [{'parts': parts}],
          'generationConfig': {'responseModalities': ['TEXT', 'IMAGE']}
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = body['error']?['message'] ?? 'API request failed (${response.statusCode}).';
        throw Exception(message);
      }

      String? imageData;
      final candidates = body['candidates'] as List? ?? [];
      for (final candidate in candidates) {
        final responseParts = candidate['content']?['parts'] as List? ?? [];
        for (final part in responseParts) {
          if (part['inlineData']?['data'] != null) imageData = part['inlineData']['data'];
          if (part['inline_data']?['data'] != null) imageData = part['inline_data']['data'];
        }
      }
      if (imageData == null) throw Exception('No image returned. Try another prompt or check model access.');
      setState(() { resultBase64 = imageData; status = 'Done! Your image is ready.'; });
    } catch (e) {
      setState(() => status = 'Could not generate: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> shareResult() async {
    if (resultBase64 == null) return;
    final bytes = base64Decode(resultBase64!);
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/maddy_ai_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Created with Maddy AI Studio');
  }

  @override
  void dispose() {
    promptController.dispose();
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: gold),
          SizedBox(width: 9),
          Text('MADDY ', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          Text('AI STUDIO', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
        ]),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF30230D), Color(0xFF15120C)]),
                border: Border.all(color: gold.withOpacity(.55)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CREATE WITHOUT LIMITS', style: TextStyle(color: gold, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                SizedBox(height: 9),
                Text('Your imagination.\\nYour AI studio.', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.15)),
                SizedBox(height: 8),
                Text('Generate a new image or transform a photo with a prompt.', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('GEMINI API KEY', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Paste your API key for this session',
                filled: true, fillColor: panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
              ),
            ),
            const SizedBox(height: 7),
            const Text('For personal testing only. Do not publish an app containing your own API key.', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _modeButton('CREATE IMAGE', 'create', Icons.add_photo_alternate_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _modeButton('EDIT PHOTO', 'edit', Icons.tune)),
            ]),
            const SizedBox(height: 14),
            if (mode == 'edit') ...[
              OutlinedButton.icon(
                onPressed: busy ? null : chooseImage,
                icon: const Icon(Icons.upload_file),
                label: Text(selected == null ? 'Choose photo from gallery' : 'Change selected photo'),
                style: OutlinedButton.styleFrom(foregroundColor: gold, side: const BorderSide(color: gold), padding: const EdgeInsets.all(15)),
              ),
              if (selected != null) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(selected!.path), height: 170, fit: BoxFit.cover)),
              ],
              const SizedBox(height: 14),
            ],
            const Text('YOUR PROMPT', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: promptController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: mode == 'create'
                    ? 'Example: A cinematic golden-hour portrait, realistic photography...'
                    : 'Example: Change the background to a luxury city at night...',
                filled: true, fillColor: panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: busy ? null : generate,
                icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                label: Text(busy ? 'CREATING…' : 'GENERATE WITH AI', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            Text(status, style: const TextStyle(color: Colors.white70)),
            if (resultBase64 != null) ...[
              const SizedBox(height: 18),
              const Text('YOUR CREATION', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(resultBase64!), fit: BoxFit.contain)),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: shareResult, icon: const Icon(Icons.share), label: const Text('Save / Share image'), style: OutlinedButton.styleFrom(foregroundColor: gold, side: const BorderSide(color: gold))),
            ],
            const SizedBox(height: 24),
            const Center(child: Text('MADDY AI STUDIO • PERSONAL PROJECT', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1))),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, String value, IconData icon) {
    final active = mode == value;
    return OutlinedButton.icon(
      onPressed: busy ? null : () => setState(() { mode = value; status = value == 'edit' ? 'Choose a photo to edit.' : 'Describe the image you want to create.'; }),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.black : gold,
        backgroundColor: active ? gold : panel,
        side: const BorderSide(color: gold),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
