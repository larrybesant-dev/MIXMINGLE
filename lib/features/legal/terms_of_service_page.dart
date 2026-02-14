import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Agreement to Terms',
              'By accessing or using Mix & Mingle, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using this service.',
            ),
            _buildSection(
              '1. Eligibility',
              'You must be at least 18 years old to use this service. By using Mix & Mingle, you represent and warrant that:\n\n'
                  '• You are at least 18 years of age\n'
                  '• You have the legal capacity to enter into this agreement\n'
                  '• You will comply with these Terms and all applicable laws\n'
                  '• All information you provide is accurate and truthful',
            ),
            _buildSection(
              '2. Account Registration',
              'To use Mix & Mingle, you must create an account. You agree to:\n\n'
                  '• Provide accurate, current, and complete information\n'
                  '• Maintain and promptly update your account information\n'
                  '• Keep your password secure and confidential\n'
                  '• Notify us immediately of any unauthorized access\n'
                  '• Be responsible for all activities under your account\n'
                  '• Not share your account with others\n'
                  '• Not create multiple accounts or use fake identities',
            ),
            _buildSection(
              '3. User Conduct',
              'You agree NOT to:\n\n'
                  '• Violate any laws or regulations\n'
                  '• Harass, abuse, threaten, or intimidate other users\n'
                  '• Post sexually explicit, violent, or offensive content\n'
                  '• Impersonate others or misrepresent your identity\n'
                  '• Spam, advertise, or promote commercial activities without permission\n'
                  '• Use the service for any illegal or unauthorized purpose\n'
                  '• Attempt to gain unauthorized access to the service\n'
                  '• Interfere with or disrupt the service or servers\n'
                  '• Use automated systems (bots) without permission\n'
                  '• Collect information about other users without consent\n'
                  '• Post content that infringes intellectual property rights',
            ),
            _buildSection(
              '4. Content',
              'You retain ownership of content you post, but grant us a license:\n\n'
                  '• Worldwide, non-exclusive, royalty-free license\n'
                  '• To use, reproduce, modify, adapt, publish, and distribute your content\n'
                  '• For the purpose of operating and improving the service\n\n'
                  'You represent that you have rights to all content you post and that it does not violate any third-party rights.',
            ),
            _buildSection(
              '5. Content Moderation',
              'We reserve the right to:\n\n'
                  '• Monitor, review, and remove any content at our discretion\n'
                  '• Suspend or terminate accounts that violate these Terms\n'
                  '• Report illegal activity to law enforcement\n'
                  '• Cooperate with legal investigations\n\n'
                  'We are not obligated to monitor content but may do so for safety and compliance purposes.',
            ),
            _buildSection(
              '6. Intellectual Property',
              'Mix & Mingle and all related content, features, and functionality are owned by us and protected by copyright, trademark, and other intellectual property laws. You may not:\n\n'
                  '• Copy, modify, or distribute our content\n'
                  '• Use our trademarks without permission\n'
                  '• Reverse engineer or decompile the app\n'
                  '• Create derivative works',
            ),
            _buildSection(
              '7. Premium Features & Subscriptions',
              'Some features require a paid subscription:\n\n'
                  '• Subscriptions auto-renew unless cancelled\n'
                  '• Prices are subject to change with notice\n'
                  '• Refunds are handled according to platform policies (App Store, Google Play)\n'
                  '• Cancellation takes effect at the end of the billing period\n'
                  '• We may modify or discontinue features at any time',
            ),
            _buildSection(
              '8. Video Chat & Communication',
              'Our video chat features are powered by Agora. By using video chat:\n\n'
                  '• You consent to real-time audio and video transmission\n'
                  '• You agree to behave appropriately and respectfully\n'
                  '• You understand calls may be monitored for safety\n'
                  '• You agree not to record others without consent\n'
                  '• You understand we are not liable for user conduct',
            ),
            _buildSection(
              '9. Disclaimer of Warranties',
              'THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND:\n\n'
                  '• We do not guarantee uninterrupted or error-free service\n'
                  '• We do not warrant accuracy or reliability of content\n'
                  '• We do not guarantee specific results from using the service\n'
                  '• We are not responsible for user conduct or content\n\n'
                  'USE AT YOUR OWN RISK.',
            ),
            _buildSection(
              '10. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n\n'
                  '• We are not liable for indirect, incidental, or consequential damages\n'
                  '• Our total liability shall not exceed the amount you paid us in the last 12 months\n'
                  '• We are not liable for user conduct, content, or interactions\n'
                  '• We are not liable for service interruptions or data loss',
            ),
            _buildSection(
              '11. Indemnification',
              'You agree to indemnify and hold us harmless from any claims, damages, losses, or expenses (including legal fees) arising from:\n\n'
                  '• Your use of the service\n'
                  '• Your violation of these Terms\n'
                  '• Your violation of any rights of others\n'
                  '• Content you post',
            ),
            _buildSection(
              '12. Termination',
              'We may terminate or suspend your account at any time for:\n\n'
                  '• Violation of these Terms\n'
                  '• Illegal activity\n'
                  '• Fraudulent or abusive behavior\n'
                  '• Any reason at our sole discretion\n\n'
                  'You may delete your account at any time through Account Settings.',
            ),
            _buildSection(
              '13. Dispute Resolution',
              'Any disputes arising from these Terms or the service shall be resolved through:\n\n'
                  '• Informal negotiation first\n'
                  '• Binding arbitration if negotiation fails\n'
                  '• Governed by the laws of [Your Jurisdiction]\n\n'
                  'You waive the right to participate in class action lawsuits.',
            ),
            _buildSection(
              '14. Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will notify you of significant changes via:\n\n'
                  '• In-app notification\n'
                  '• Email to your registered address\n'
                  '• Updated "Last updated" date\n\n'
                  'Continued use after changes constitutes acceptance.',
            ),
            _buildSection(
              '15. General Provisions',
              '• Severability: If any provision is invalid, the rest remains in effect\n'
                  '• Waiver: Our failure to enforce any right does not waive that right\n'
                  '• Assignment: You may not transfer your rights; we may transfer ours\n'
                  '• Entire Agreement: These Terms constitute the entire agreement\n'
                  '• Language: English version controls in case of conflicts',
            ),
            _buildSection(
              '16. Contact Information',
              'For questions about these Terms, contact us at:\n\n'
                  'Email: legal@mixandmingle.com\n'
                  'Address: [Your Company Address]\n',
            ),
            const SizedBox(height: 32),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600),
                  children: [
                    const TextSpan(text: 'By using Mix & Mingle, you agree to our\n'),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, '/privacy');
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
