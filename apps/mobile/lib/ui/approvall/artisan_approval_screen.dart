import 'package:flutter/material.dart';

class OutwardDistributionScreen extends StatelessWidget {
  const OutwardDistributionScreen({super.key});

  static const brown = Color(0xFF8B4E2F);
  static const dark = Color(0xFF302F2C);
  static const cream = Color(0xFFF9F6F1);
  static const card = Color(0xFFF3EFE9);
  static const green = Color(0xFFDCEBC2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'OUTWARD DISTRIBUTION',
                              style: TextStyle(
                                color: brown,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your product is ready to sell',
                              style: TextStyle(
                                color: Color(0xFF777069),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7DED3),
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_tree_outlined,
                            color: brown,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // STAGE PROGRESS
                    Row(
                      children: List.generate(
                        5,
                            (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 5,
                            ),
                            height: 5,
                            decoration: BoxDecoration(
                              color: brown,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SUCCESS ICON
                    Center(
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: const BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF60733C),
                          size: 45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'Published & Ready to Sell.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark,
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Your verified product is now ready for\nmulti-channel distribution.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF756D67),
                          height: 1.45,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PRODUCT CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 76,
                                width: 76,
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFFD5C09D),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: brown,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Devi Ram Weavers',
                                      style: TextStyle(
                                        color: dark,
                                        fontSize: 17,
                                        fontWeight:
                                        FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Chanderi Cluster',
                                      style: TextStyle(
                                        color:
                                        Color(0xFF766F68),
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Pure Silk  •  ₹3,850',
                                      style: TextStyle(
                                        color: brown,
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding:
                            const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 18,
                                  color:
                                  Color(0xFF60733C),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'VERIFIED • PUBLISHED',
                                  style: TextStyle(
                                    color:
                                    Color(0xFF53672F),
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'DISTRIBUTION CHANNELS',
                      style: TextStyle(
                        color: brown,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // WHATSAPP
                    _distributionCard(
                      icon: Icons.chat_outlined,
                      title: 'Direct WhatsApp Pack',
                      subtitle:
                      'Create a ready-to-share product card',
                      button: 'CREATE PACK',
                      onPressed: () {},
                    ),

                    const SizedBox(height: 10),

                    // MARKETPLACE
                    _distributionCard(
                      icon: Icons.storefront_outlined,
                      title: 'Marketplace Adapters',
                      subtitle:
                      'Prepare listing for partner marketplaces',
                      button: 'VIEW ADAPTERS',
                      onPressed: () {},
                    ),

                    const SizedBox(height: 10),

                    // FIELD VERIFICATION
                    _distributionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Cluster Field Verification',
                      subtitle:
                      'View location and artisan proof',
                      button: 'VIEW PROOF',
                      onPressed: () {},
                    ),

                    const SizedBox(height: 20),

                    // CREATE ANOTHER
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add,
                          color: brown,
                        ),
                        label: const Text(
                          'CREATE ANOTHER PRODUCT',
                          style: TextStyle(
                            color: brown,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: brown,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),

            // BOTTOM NAVIGATION
            Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE6E0DA),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_outlined, 'Home'),
                  _navItem(
                    Icons.inventory_2_outlined,
                    'Products',
                    active: true,
                  ),
                  _navItem(
                    Icons.insights_outlined,
                    'Insights',
                  ),
                  _navItem(
                    Icons.person_outline,
                    'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _distributionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String button,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E2D7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: brown,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF777069),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          TextButton(
            onPressed: onPressed,
            child: Text(
              button,
              style: const TextStyle(
                color: brown,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _navItem(
      IconData icon,
      String label, {
        bool active = false,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 21,
          color: active
              ? brown
              : const Color(0xFF817A73),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
            active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? brown
                : const Color(0xFF817A73),
          ),
        ),
      ],
    );
  }
}