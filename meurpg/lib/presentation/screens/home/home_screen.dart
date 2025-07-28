import 'package:flutter/material.dart';
import '/models/user_model.dart';
import '../tables/create_table_screen.dart';
import '../../widgets/custom_scaffold.dart';
import '../tables/my_tables_screen.dart';
import '../tables/search_tables_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/profile_screen.dart';
import '../system/system_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAvatar = 'avatar1.png';
  final TextEditingController _codigoController = TextEditingController();

  /* -------------------------------------------------------------------------- */
  /*                               AVATAR E PERFIL                              */
  /* -------------------------------------------------------------------------- */

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
                avatars
                    .map(
                      (avatar) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, avatar),
                        child: Row(
                          children: [
                            Image.asset('assets/images/$avatar', width: 40),
                            const SizedBox(width: 12),
                            Text(avatar.split('.').first),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
    );

    if (chosen != null) {
      setState(() => selectedAvatar = chosen);
    }
  }

  void _openProfileSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProfileScreen(
              user: widget.user,
              selectedAvatar: selectedAvatar,
            ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                            ENTRAR NA MESA POR CÓDIGO                       */
  /* -------------------------------------------------------------------------- */

  Future<void> _entrarComCodigo() async {
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

      await mesaRef.update({
        'players': FieldValue.arrayUnion([widget.user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou na mesa com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao entrar na mesa: $e')));
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                             COMPONENTE | CARD                              */
  /* -------------------------------------------------------------------------- */

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   BUILD                                    */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      user: widget.user,
      selectedAvatar: selectedAvatar,
      onAvatarTap: _selectAvatar,
      onSettingsTap: _openProfileSettings,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /* ------------------------- MENU PRINCIPAL EM CARDS ------------------------ */
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                children: [
                  _buildMenuCard(
                    icon: Icons.add_box,
                    title: 'Criar\nMesa',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CreateTableScreen(user: widget.user),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    icon: Icons.table_chart,
                    title: 'Minhas\nMesas',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyTablesScreen(user: widget.user),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    icon: Icons.search,
                    title: 'Buscar\nMesas',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SearchTablesScreen(user: widget.user),
                          ),
                        ),
                  ),
                  /* ---------------------- NOVO CARD – CRIAR SISTEMA ---------------------- */
                  _buildMenuCard(
                    icon: Icons.developer_board,
                    title: 'Sistemas',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SystemListScreen(user: widget.user),
                          ),
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /* ------------- CARD PARA ENTRAR NA MESA COM CÓDIGO ------------- */
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código da mesa',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
