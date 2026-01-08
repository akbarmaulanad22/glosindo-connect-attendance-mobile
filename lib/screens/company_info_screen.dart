import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Perusahaan')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header dengan Logo
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 50,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PT. Glosindo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Global Solutions Indonesia',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Profile Perusahaan
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Profil Perusahaan'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PT. Glosindo adalah perusahaan yang bergerak di bidang teknologi informasi dan solusi digital. Didirikan pada tahun 2010, kami telah melayani berbagai klien dari berbagai industri dengan komitmen untuk memberikan solusi terbaik.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 16),
                          _buildFactItem('Tahun Berdiri', '2010'),
                          const Divider(),
                          _buildFactItem('Karyawan', '500+ Profesional'),
                          const Divider(),
                          _buildFactItem('Klien', '200+ Perusahaan'),
                          const Divider(),
                          _buildFactItem('Proyek', '1000+ Proyek Selesai'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Visi
                  _buildSectionTitle('Visi'),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Menjadi perusahaan teknologi terdepan yang memberikan solusi inovatif untuk membantu bisnis bertransformasi digital dan mencapai kesuksesan berkelanjutan.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Misi
                  _buildSectionTitle('Misi'),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildMissionItem(
                            1,
                            'Mengembangkan solusi teknologi berkualitas tinggi yang memenuhi kebutuhan bisnis modern',
                          ),
                          const SizedBox(height: 12),
                          _buildMissionItem(
                            2,
                            'Memberikan pelayanan terbaik dengan fokus pada kepuasan pelanggan',
                          ),
                          const SizedBox(height: 12),
                          _buildMissionItem(
                            3,
                            'Membangun tim profesional yang kompeten dan inovatif',
                          ),
                          const SizedBox(height: 12),
                          _buildMissionItem(
                            4,
                            'Berkontribusi pada perkembangan teknologi di Indonesia',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nilai-Nilai Perusahaan
                  _buildSectionTitle('Nilai-Nilai Kami'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildValueCard(
                        'Integritas',
                        Icons.security,
                        Colors.blue,
                      ),
                      _buildValueCard(
                        'Inovasi',
                        Icons.lightbulb_outline,
                        Colors.orange,
                      ),
                      _buildValueCard('Kolaborasi', Icons.groups, Colors.green),
                      _buildValueCard('Keunggulan', Icons.star, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Kontak Informasi
                  _buildSectionTitle('Kontak Kami'),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        _buildContactTile(
                          Icons.location_on,
                          'Alamat',
                          'Jl. Sudirman No. 123\nJakarta Pusat, 10220\nIndonesia',
                          null,
                        ),
                        const Divider(height: 1),
                        _buildContactTile(
                          Icons.phone,
                          'Telepon',
                          '+62 21 1234 5678',
                          () => _launchUrl('tel:+622112345678'),
                        ),
                        const Divider(height: 1),
                        _buildContactTile(
                          Icons.email,
                          'Email',
                          'info@glosindo.com',
                          () => _launchUrl('mailto:info@glosindo.com'),
                        ),
                        const Divider(height: 1),
                        _buildContactTile(
                          Icons.language,
                          'Website',
                          'www.glosindo.com',
                          () => _launchUrl('https://www.glosindo.com'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Media
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ikuti Kami',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSocialButton(
                                Icons.facebook,
                                Colors.blue.shade700,
                                () =>
                                    _launchUrl('https://facebook.com/glosindo'),
                              ),
                              _buildSocialButton(
                                Icons.video_library,
                                Colors.red,
                                () =>
                                    _launchUrl('https://youtube.com/@glosindo'),
                              ),
                              _buildSocialButton(
                                Icons.camera_alt,
                                Colors.pink,
                                () => _launchUrl(
                                  'https://instagram.com/glosindo',
                                ),
                              ),
                              _buildSocialButton(
                                Icons.work,
                                Colors.blue.shade800,
                                () => _launchUrl(
                                  'https://linkedin.com/company/glosindo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© ${DateTime.now().year} PT. Glosindo',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All rights reserved',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFactItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionItem(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard(String title, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5)),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value),
      trailing: onTap != null
          ? Icon(Icons.open_in_new, size: 20, color: Colors.grey.shade600)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }
}
