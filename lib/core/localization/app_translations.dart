import 'package:get/get.dart';

/// All UI strings. English + Arabic; add a locale by adding a map.
class AppTranslations extends Translations {
  static const supported = ['en', 'ar'];

  @override
  Map<String, Map<String, String>> get keys => {
        'en': _en,
        'ar': _ar,
      };

  static const _en = {
    'app_name': 'Jackaroo',
    'tagline': 'Marbles. Cards. Teamwork.',
    'play': 'Play',
    'how_to_play': 'How to play',
    'settings': 'Settings',
    'language': 'Language',
    'sound': 'Sound effects',
    'music': 'Music',
    'hide_hands': 'Hide cards between turns',
    'hide_hands_hint': 'For pass-and-play on one device',
    'close': 'Close',
    'back': 'Back',
    'setup_title': 'New game',
    'players': 'Players',
    'team': 'Team',
    'team_a': 'Team A',
    'team_b': 'Team B',
    'human': 'Human',
    'bot': 'Bot',
    'easy': 'Easy',
    'normal': 'Normal',
    'hard': 'Hard',
    'name_hint': 'Name',
    'house_rules': 'House rules',
    'rule_jack_any': 'Jack swaps any two marbles',
    'rule_jack_any_hint':
        'Board rule. Off = one of the marbles must be yours (app rule).',
    'rule_five_any': '5 can move any marble',
    'rule_five_any_hint': 'Even an opponent\'s marble, 5 steps forward.',
    'rule_king_burns': 'King burns its path',
    'rule_king_burns_hint': 'A King moving 13 burns every marble it passes.',
    'rule_burn_partner': 'Can burn partner',
    'rule_burn_partner_hint': 'Landing on your partner sends them home.',
    'rule_seven_split': '7 can be split',
    'rule_seven_split_hint': 'Divide the 7 steps between two marbles.',
    'start_game': 'Start game',
    'round': 'Round @n',
    'your_turn': '@name, your turn',
    'bot_thinking': '@name is thinking…',
    'pick_card': 'Pick a card',
    'pick_marble': 'Tap a marble to move',
    'pick_target': 'Tap where to go',
    'pick_swap_target': 'Tap the marble to swap with',
    'pick_second_marble': 'Tap a second marble for the remaining @n',
    'pick_second_target': 'Tap where the second marble goes',
    'no_moves': 'No legal moves — tap a card to discard it',
    'discarded': '@name discarded a card',
    'pass_to': 'Pass the device to',
    'tap_to_reveal': 'Tap to see your cards',
    'cancel': 'Cancel',
    'menu': 'Menu',
    'resume': 'Resume',
    'restart': 'Restart',
    'quit': 'Quit to menu',
    'quit_confirm': 'Leave this game?',
    'winner': '@team wins!',
    'captures': 'Burns',
    'moves': 'Moves',
    'home_marbles': 'Home',
    'play_again': 'Play again',
    'main_menu': 'Main menu',
    'rules_title': 'How to play',
    'rules_body': '''
GOAL
Four players in two teams (partners sit opposite). The first team to bring all eight of its marbles into the home lanes wins.

TURNS
Each round every player gets 4 cards. On your turn play one card and move a marble. If no card can be played you must discard one.

CARDS
A — Bring a marble out, or move 1 or 11.
K — Bring a marble out, or move 13, burning every marble on the way.
Q — Move 12.
J — Swap two marbles on the track.
10, 9, 8, 6, 3, 2 — Move that many steps.
7 — Move 7, or split it between two marbles.
5 — Move 5. Can also move any other player's marble.
4 — Move 4 steps BACKWARD.

BURNING
Landing on another marble sends it back to its base. A marble resting on its own entry cell is safe — it cannot be burned, swapped, or jumped over.

HOME
The home lane starts just before your entry cell, so a marble must go around the board. You need the exact number to enter; marbles in the home lane can never be passed.

TIP: play a 4 from your entry cell to step back, then enter home with a small card.

PARTNERS
When all your marbles are home you keep playing cards to move your partner's marbles.
''',
  };

  static const _ar = {
    'app_name': 'جاكارو',
    'tagline': 'بلي. ورق. شغل فريق.',
    'play': 'العب',
    'how_to_play': 'طريقة اللعب',
    'settings': 'الإعدادات',
    'language': 'اللغة',
    'sound': 'المؤثرات الصوتية',
    'music': 'الموسيقى',
    'hide_hands': 'إخفاء الورق بين الأدوار',
    'hide_hands_hint': 'للعب بالتناوب على جهاز واحد',
    'close': 'إغلاق',
    'back': 'رجوع',
    'setup_title': 'لعبة جديدة',
    'players': 'اللاعبون',
    'team': 'فريق',
    'team_a': 'الفريق أ',
    'team_b': 'الفريق ب',
    'human': 'لاعب',
    'bot': 'كمبيوتر',
    'easy': 'سهل',
    'normal': 'عادي',
    'hard': 'صعب',
    'name_hint': 'الاسم',
    'house_rules': 'قواعد البيت',
    'rule_jack_any': 'الشايب يبدّل أي بليتين',
    'rule_jack_any_hint':
        'قاعدة اللوحة. عند الإيقاف: لازم تكون إحدى البليتين لك (قاعدة التطبيق).',
    'rule_five_any': 'الخمسة تحرّك أي بلية',
    'rule_five_any_hint': 'حتى بلية الخصم، ٥ خطوات للأمام.',
    'rule_king_burns': 'الشيخ يحرق طريقه',
    'rule_king_burns_hint': 'الشيخ بـ١٣ خطوة يحرق كل بلية يمر عليها.',
    'rule_burn_partner': 'يمكن حرق الشريك',
    'rule_burn_partner_hint': 'النزول على بلية شريكك يرجعها للبيت.',
    'rule_seven_split': 'السبعة تنقسم',
    'rule_seven_split_hint': 'قسّم خطوات السبعة بين بليتين.',
    'start_game': 'ابدأ اللعبة',
    'round': 'الجولة @n',
    'your_turn': '@name، دورك',
    'bot_thinking': '@name يفكر…',
    'pick_card': 'اختر ورقة',
    'pick_marble': 'اضغط على بلية لتحريكها',
    'pick_target': 'اضغط على المكان',
    'pick_swap_target': 'اضغط على البلية التي تريد التبديل معها',
    'pick_second_marble': 'اضغط على بلية ثانية للخطوات المتبقية (@n)',
    'pick_second_target': 'اضغط على مكان البلية الثانية',
    'no_moves': 'لا توجد حركة — اضغط على ورقة لحرقها',
    'discarded': '@name حرق ورقة',
    'pass_to': 'مرّر الجهاز إلى',
    'tap_to_reveal': 'اضغط لرؤية أوراقك',
    'cancel': 'إلغاء',
    'menu': 'القائمة',
    'resume': 'استمرار',
    'restart': 'إعادة',
    'quit': 'الخروج للقائمة',
    'quit_confirm': 'تريد ترك هذه اللعبة؟',
    'winner': '@team فاز!',
    'captures': 'حرق',
    'moves': 'حركات',
    'home_marbles': 'في البيت',
    'play_again': 'العب مرة أخرى',
    'main_menu': 'القائمة الرئيسية',
    'rules_title': 'طريقة اللعب',
    'rules_body': '''
الهدف
أربعة لاعبين في فريقين (الشريك يجلس في المقابل). أول فريق يُدخل بلياته الثماني إلى البيت يفوز.

الأدوار
في كل جولة يأخذ كل لاعب ٤ أوراق. في دورك العب ورقة وحرّك بلية. إذا لم تستطع اللعب بأي ورقة يجب أن تحرق ورقة.

الأوراق
A — أخرج بلية، أو تحرك ١ أو ١١.
K — أخرج بلية، أو تحرك ١٣ وأحرق كل بلية في الطريق.
Q — تحرك ١٢.
J — بدّل مكان بليتين على المسار.
10, 9, 8, 6, 3, 2 — تحرك بعدد الخطوات.
7 — تحرك ٧، أو قسّمها بين بليتين.
5 — تحرك ٥. ويمكن تحريك بلية أي لاعب آخر.
4 — تحرك ٤ خطوات للخلف.

الحرق
النزول على بلية أخرى يرجعها إلى قاعدتها. البلية الواقفة على خانة دخولها آمنة — لا تُحرق ولا تُبدّل ولا يمكن القفز فوقها.

البيت
مدخل البيت قبل خانة الدخول مباشرة، لذا يجب أن تدور البلية حول اللوحة. تحتاج الرقم المضبوط للدخول، ولا يمكن تجاوز البلي في البيت.

نصيحة: العب ٤ من خانة الدخول لترجع للخلف ثم ادخل البيت بورقة صغيرة.

الشركاء
عندما تصل كل بلياتك للبيت تواصل اللعب بأوراقك لتحريك بلي شريكك.
''',
  };
}
