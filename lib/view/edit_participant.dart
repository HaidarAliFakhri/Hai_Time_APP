import 'package:flutter/material.dart';
import 'package:hai_time_app/db/db_helper.dart';
import 'package:hai_time_app/model/participant.dart';

class EditParticipantPage extends StatefulWidget {
  final Participant participant;
  const EditParticipantPage({super.key, required this.participant});

  @override
  State<EditParticipantPage> createState() => _EditParticipantPageState();
}

class _EditParticipantPageState extends State<EditParticipantPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameC;
  late TextEditingController _emailC;
  late TextEditingController _phoneC;
  late TextEditingController _cityC;
  late TextEditingController _passwordC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.participant.name);
    _emailC = TextEditingController(text: widget.participant.email);
    // _phoneC = TextEditingController(text: widget.participant.phone);
    // _cityC = TextEditingController(text: widget.participant.city);
    _passwordC = TextEditingController(text: widget.participant.password);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _cityC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Data User"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: "Nama"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _emailC,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _phoneC,
                decoration: const InputDecoration(labelText: "Nomor HP"),
              ),
              TextFormField(
                controller: _cityC,
                decoration: const InputDecoration(labelText: "Kota"),
              ),
              TextFormField(
                controller: _passwordC,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updated = Participant(
                      id: widget.participant.id,
                      name: _nameC.text.trim(),
                      email: _emailC.text.trim(),
                      // phone: _phoneC.text.trim(),
                      // city: _cityC.text.trim(),
                      password: _passwordC.text.trim(),
                    );

                    await DBHelperTime().updateParticipant(updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Data berhasil diperbarui")),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Simpan Perubahan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
