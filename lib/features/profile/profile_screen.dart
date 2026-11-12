import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../services/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Player Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to sign out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final user = ref.read(currentUserProfileProvider).value;
                if (user != null) {
                  await ref.read(presenceServiceProvider).setUserOffline(user.uid);
                }
                await ref.read(authServiceProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text("Profile not available"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // Avatar & Names
                    AppAvatar(
                      photoUrl: profile.photoUrl,
                      name: profile.displayName,
                      radius: 48,
                      showOnlineBadge: true,
                      isOnline: profile.isOnline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${profile.username} • ID: ${profile.playerId}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        profile.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Level & XP Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Level ${profile.level}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              Text(
                                "${profile.xp} XP",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (profile.xp % 150) / 150,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Statistics Cards Grid
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, "Matches", "${profile.totalMatches}", Icons.gamepad)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(context, "Wins", "${profile.wins}", Icons.emoji_events, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, "Losses", "${profile.losses}", Icons.cancel_outlined, color: Colors.redAccent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(context, "Draws", "${profile.draws}", Icons.handshake_outlined, color: Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, "Win Rate", "${profile.winRate.toStringAsFixed(1)}%", Icons.pie_chart)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(context, "Best Streak", "${profile.bestStreak} 🔥", Icons.local_fire_department, color: Colors.orange)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Edit Profile Button
                    GestureDetector(
                      onTap: () => context.push('/profile/edit'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Edit Profile Details",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: AppTheme.neumorphicBox(context, borderRadius: 14),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color ?? Colors.deepPurple),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
