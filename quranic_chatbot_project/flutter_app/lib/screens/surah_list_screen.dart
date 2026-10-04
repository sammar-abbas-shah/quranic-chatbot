part of '../main.dart';

// ---------------------------------------------------------------------------
// Developer Backend Test screen (raw backend response).
// ---------------------------------------------------------------------------

/// Your original test screen (unchanged logic): shows the raw backend
/// response, including the real error text if the server is unreachable.
/// Open it from Settings > Backend connection test.
class SurahListScreen extends StatefulWidget {
  final api.HttpQuranService quranService;
  final api.HttpChatService chatService;

  const SurahListScreen(
      {super.key, required this.quranService, required this.chatService});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<dynamic>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = widget.quranService.getSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surahs')),
      body: FutureBuilder<List<dynamic>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Surahs found'));
          }

          final surahs = snapshot.data!;
          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                title: Text('${surah['id']}. ${surah['name_english']}'),
                subtitle: Text(surah['name_arabic'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
