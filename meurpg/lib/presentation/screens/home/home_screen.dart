import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAvatar = 'avatar1.png';
  final TextEditingController _codigoController = TextEditingController();

  void _selectAvatar() async {
    final avatars = [
      'avatar1.png',
      'avatar1.png',
      'avatar1.png',
      'avatar1.png',
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

  void _entrarComCodigo() {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um código válido.')));
      return;
    }

    // Aqui você vai fazer a lógica para validar e entrar na mesa com o código
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrando na mesa com código: $codigo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('MeuRPG'),
        actions: [
          InkWell(
            onTap: _openProfileSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  widget.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: _selectAvatar,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/$selectedAvatar'),
              ),
            ),
          ),
        ],
      ),
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
                // Navegar para criar uma mesa
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
                // Navegar para "Minhas Mesas"
              },
              child: const Text('Minhas Mesas'),
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
