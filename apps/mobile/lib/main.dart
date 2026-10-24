import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomePage(),
    SendPage(),
    ReceivePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: _index,
  onTap: (i) => setState(() => _index = i),
  selectedItemColor: Colors.black,
  unselectedItemColor: Colors.grey,
  backgroundColor: Colors.white,
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.north_east), label: 'Send'),
    BottomNavigationBarItem(icon: Icon(Icons.south_west), label: 'Receive'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF5F2E9), // Warm cream
            Color(0xFFFAFAFA), // Off white
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 30),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '\$38,486.88',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Performance',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '+2.57%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30), // Adjusted spacing

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF24252A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.grey[400], size: 18),
                            const SizedBox(width: 12),
                            Icon(Icons.show_chart,
                                color: Colors.grey[400], size: 18),
                            const SizedBox(width: 12),
                            Icon(Icons.add, color: Colors.grey[400], size: 18),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _ChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // X-Axis Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('May', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Jun', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Jul', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Aug', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Sep', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Oct', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Nov', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Dec', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const _TransactionTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Shopping at Daraz',
                subtitle: 'Payment',
                amount: '-\$248.59',
                time: '08:43 pm',
              ),
              const SizedBox(height: 12),
              const _TransactionTile(
                icon: Icons.directions_car_outlined,
                title: 'DIU Transport',
                subtitle: 'Payment',
                amount: '-\$18.00',
                time: '08:43 pm',
              ),
              const SizedBox(height: 12),
              const _TransactionTile(
                icon: Icons.send_outlined,
                title: 'Send Money to Raiyan',
                subtitle: 'Payment',
                amount: '-\$145.98',
                time: '08:43 pm',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(
                'https://i.postimg.cc/QMYSkGhW/Gemini-Generated-Image-mqgujnmqgujnmqgu.jpg',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const Text(
                  'Niggustak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none, size: 24),
        )
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final String time;

  const _TransactionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }
}


class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw Horizontal Grid Lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Y-Axis Labels
    final textStyle = TextStyle(color: Colors.grey[600], fontSize: 10);
    final labels = ['3k', '2.5k', '2k', '1.5k', '1k'];
    for (int i = 0; i <= 4; i++) {
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, size.height * (i / 4) - 12));
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(20, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path, linePaint);

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashedPath = Path();
    dashedPath.moveTo(20, size.height * 0.7);
    dashedPath.lineTo(size.width * 0.3, size.height * 0.8);
    dashedPath.lineTo(size.width * 0.5, size.height * 0.4);
    dashedPath.lineTo(size.width * 0.7, size.height * 0.6);
    dashedPath.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(dashedPath, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SendPage extends StatelessWidget {
  const SendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5F2E9), Color(0xFFFAFAFA)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Money',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan a QR code or enter a payment code',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 28),

              // QR scanner placeholder
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR scanner coming soon')),
                ),
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFF24252A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Corner brackets
                      const _ScannerCorners(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider with "or"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 24),

              // Manual code entry
              const Text(
                'Enter code',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. ABC-123-XYZ',
                  hintStyle: TextStyle(color: Colors.grey[500], letterSpacing: 1),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final code = codeController.text.trim();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a code first')),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Looking up code: $code')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24252A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const len = 28.0;
    const thick = 3.0;
    const pad = 20.0;
    const color = Color(0xFFFFB300);

    Widget corner({bool top = true, bool left = true}) => Positioned(
          top: top ? pad : null,
          bottom: top ? null : pad,
          left: left ? pad : null,
          right: left ? null : pad,
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                thickness: thick,
                top: top,
                left: left,
              ),
            ),
          ),
        );

    return Stack(children: [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ]);
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final y = top ? 0.0 : size.height;
    final x = left ? 0.0 : size.width;
    final yEnd = top ? size.height : 0.0;
    final xEnd = left ? size.width : 0.0;

    canvas.drawLine(Offset(x, y), Offset(xEnd, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, yEnd), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.top != top || old.left != left;
}

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Receive Page'));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Page'));
  }
}