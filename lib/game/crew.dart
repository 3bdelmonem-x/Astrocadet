import 'package:flutter/material.dart';
import '../localization/game_localization.dart';

/// بيانات شخصيات الطاقم. عدلي الشخصية والجمل من هنا بس وهتتغير في كل اللعبة.
class CrewMember {
  final String id;
  final String title; // الاسم اللي بيظهر في الحوار
  final String role;
  final String personality; // وصف مختصر للشخصية (للتيم)
  final Color color;
  final IconData icon;
  final String? portrait; // مسار صورة لو موجودة
  // لحد ما نجيب صور للشخصية: بنستخدم تعبير من تعبيرات القائدة مكان الصورة
  final String placeholderMood;
  // اسم ملف صوت الكلام (talk_...) في assets/audio
  final String blip;
  final List<String> lines; // جمل بتقولها لما اللاعب يضغط عليها

  const CrewMember({
    required this.id,
    required this.title,
    required this.role,
    required this.personality,
    required this.color,
    required this.icon,
    required this.lines,
    this.portrait,
    this.placeholderMood = 'Neutral',
    this.blip = 'talk_commander',
  });

  String get label => '${gameText(title)} — ${gameText(role)}';
}

// القائدة: هادية وحاسمة وبتفكر قدام
const CrewMember nadia = CrewMember(
  id: 'nadia',
  title: 'Commander Nadia',
  role: 'Base Commander & Lead Engineer',
  personality: 'Calm, decisive, always thinks a few Sols ahead',
  color: Colors.cyan,
  icon: Icons.engineering,
  portrait: 'assets/images/GreenhouseScreen/Asset-Commander-Happy.png',
  blip: 'talk_commander',
  lines: [
    'Stay calm and keep every need balanced, Cadet.',
    'Think two Sols ahead. Today\'s choice is tomorrow\'s problem.',
    'Every decision costs something. Choose wisely.',
  ],
);

// كريم: متفائل وحماسي (الطاقة)
const CrewMember karim = CrewMember(
  id: 'karim',
  title: 'Karim',
  role: 'Systems & Power Specialist',
  personality: 'Optimistic, energetic, loves a challenge',
  color: Colors.amber,
  icon: Icons.bolt,
  placeholderMood: 'Happy',
  blip: 'talk_karim',
  lines: [
    'Power is life! More panels, more smiles!',
    'Dust storm? Pfft. That is what batteries are for!',
    'The sun always comes back. We just have to be ready!',
  ],
);

// أمارة: حنونة وحريصة (الحياة والزراعة)
const CrewMember amara = CrewMember(
  id: 'amara',
  title: 'Amara',
  role: 'Life Support & Biosphere Specialist',
  personality: 'Caring, careful, notices small problems early',
  color: Colors.green,
  icon: Icons.eco,
  placeholderMood: 'Worried',
  blip: 'talk_layla',
  lines: [
    'Every drop of water counts. Recycle, recycle, recycle.',
    'Plants grow slowly. Plant early and check on them.',
    'Small problems get big fast. Maintain before it breaks.',
  ],
);

// يوسف: دكتور هادي ودقيق (الإشعاع وصحة الطاقم)
const CrewMember youssef = CrewMember(
  id: 'youssef',
  title: 'Youssef',
  role: 'Flight Doctor & Radiation Specialist',
  personality: 'Calm, precise, worries about the crew\'s health',
  color: Colors.orange,
  icon: Icons.medical_services,
  placeholderMood: 'Neutral',
  portrait: 'assets/images/GreenhouseScreen/Asset-Youssef.png',
  blip: 'talk_youssef',
  lines: [
    'Radiation is invisible, but it adds up every Sol. Shield the habitat.',
    'A healthy crew needs water, food and air. Skip one and I will see it.',
    'Prevention is easier than treatment. Plan ahead, Cadet.',
  ],
);

const List<CrewMember> crewMembers = [nadia, karim, amara, youssef];

// مركز التحكم على الأرض (مش جزء من الطاقم اللي على المريخ)
const CrewMember missionControl = CrewMember(
  id: 'reyes',
  title: 'Dr. Reyes',
  role: 'Mission Control (Earth)',
  personality: 'Professional, reassuring, speaks in short radio messages',
  color: Colors.purpleAccent,
  icon: Icons.support_agent,
  blip: 'talk_earth',
  lines: [
    'Mission Control here. We are watching your telemetry, Cadet.',
    'Remember: every Sol you survive is a win for the whole team.',
    'Earth is with you, even when the signal is not.',
  ],
);
