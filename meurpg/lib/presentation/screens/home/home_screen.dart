import 'package:flutter/material.dart';
import '/models/user_model.dart';
import '../tables/create_table_screen.dart';
import '../../widgets/custom_scaffold.dart';
import '../tables/my_tables_screen.dart';
import '../tables/search_tables_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAvatar = 'avatar1.png';
  final TextEditingController _codigoController = TextEditingController();

  void _selectAvatar() async {
    final avatars = [
      'avatar1.png',
      'avatar2.png',
      'avatar3.png',
      'avatar4.png',
    ];

    final chosen = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Escolha seu avatar'),
            children:
                avatars.map((avatar) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, avatar),
                    child: Row(
                      children: [
                        Image.asset('assets/images/$avatar', width: 40),
                        const SizedBox(width: 12),
                        Text(avatar.split('.').first),
                      ],
                    ),
                  );
                }).toList(),
          ),
    );

    if (chosen != null) {
      setState(() {
        selectedAvatar = chosen;
      });
    }
  }

  void _openProfileSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela de perfil em construção')),
    );
  }

  void _entrarComCodigo() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um código válido.')));
      return;
    }

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('tables')
              .where('joinCode', isEqualTo: codigo)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesa não encontrada com esse código.')),
        );
        return;
      }

      final mesaDoc = query.docs.first;
      final mesaRef = mesaDoc.reference;

      final players = List<String>.from(mesaDoc['players'] ?? []);

      if (players.contains(widget.user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você já está nessa mesa.')),
        );
        return;
      }

      // Adiciona o usuário ao array
      await mesaRef.update({
        'players': FieldValue.arrayUnion([widget.user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou na mesa com sucesso!')),
      );

      // (Opcional) Vá para a tela de detalhes da mesa
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (_) => TableDetailsScreen(user: widget.user, tableDoc: mesaDoc),
      // ));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao entrar na mesa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      user: widget.user,
      selectedAvatar: selectedAvatar,
      onAvatarTap: _selectAvatar,
      onSettingsTap: _openProfileSettings,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTableScreen(user: widget.user),
                  ),
                );
              },
              child: const Text('Criar uma Mesa'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyTablesScreen(user: widget.user),
                  ),
                );
              },
              child: const Text('Minhas Mesas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchTablesScreen(user: widget.user),
                  ),
                );
              },
              child: const Text('Buscar Mesas'),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código da mesa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _entrarComCodigo,
              child: const Text('Entrar com Código'),
            ),
          ],
        ),
      ),
    );
  }
}
