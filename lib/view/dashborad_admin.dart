import 'package:flutter/material.dart';
import 'package:hai_time_app/db/db_helper.dart';
import 'package:hai_time_app/model/participant.dart';
import 'package:hai_time_app/page/login_page.dart';
import 'package:hai_time_app/view/edit_participant.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  List<Participant> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    setState(() => _isLoading = true);
    try {
      final data = await DBHelperTime().getAllParticipants();
      setState(() {
        _participants = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteParticipant(int id) async {
    try {
      await DBHelperTime().deleteParticipant(id);
      await _fetchParticipants();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Akun berhasil dihapus!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
    }
  }

  Future<void> _logoutAdmin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar dari akun admin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil logout sebagai admin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF8),
      appBar: AppBar(
        title: const Text("Dashboard Admin HaiTrip"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Muat ulang data",
            onPressed: _fetchParticipants,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout Admin",
            onPressed: _logoutAdmin,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
          ? const Center(
              child: Text(
                "Belum ada akun terdaftar.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final p = _participants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(
                                "assets/images/logo/logo_app.png",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text("🔑 Password: "),
                            Expanded(
                              child: Text(
                                p.password,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "📧 ${p.email}",
                          style: const TextStyle(
                            fontSize:
                                18, // 🔼 ubah ukuran sesuai keinginan (default biasanya 14–16)
                            fontWeight: FontWeight
                                .w500, // opsional: bisa bold atau medium
                            color: Colors.black87, // opsional: ubah warna teks
                          ),
                        ),

                        // Text("📱 ${p.phone}"),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              color: Colors.blue.shade700,
                              tooltip: "Detail Akun",
                              onPressed: () {
                                _showDetailDialog(context, p);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditParticipantPage(participant: p),
                                  ),
                                ).then(
                                  (_) => setState(() {}),
                                ); // refresh setelah edit
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.redAccent,
                              tooltip: "Hapus Akun",
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Konfirmasi"),
                                    content: Text(
                                      "Yakin ingin menghapus akun '${p.name}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Batal"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Hapus"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteParticipant(p.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDetailDialog(BuildContext context, Participant p) {
    showDialog(
      context: context,
      builder: (context) {
        bool obscure = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text("Detail Akun - ${p.name}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📧 Email: ${p.email}"),
                  // Text("📱 Nomor HP: ${p.phone}"),
                  // Text("🌆 Asal Kota: ${p.city}"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("🔑 Password: "),
                      Expanded(
                        child: Text(
                          obscure
                              ? "********"
                              : "(disimpan di SharedPreferences)",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Tutup"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
