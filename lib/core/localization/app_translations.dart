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
    'rule_ten_skip': '10 can burn a card & skip',
    'rule_ten_skip_hint':
        'Instead of moving, the next player throws away a random card and loses their turn.',
    'rule_queen_steal': 'Queen can steal a card & skip',
    'rule_queen_steal_hint':
        'Instead of moving, take a random card from the next player and skip their turn.',
    'ten_action': 'Burn a card from @name & skip them',
    'queen_action': 'Steal a card from @name & skip them',
    'pick_action': 'Tap a marble to move, or use the card\'s power',
    'pick_power': 'Use the card\'s power below',
    'effect_discard': '@victim lost a card and their turn',
    'effect_steal': '@name stole a card from @victim',
    'start_game': 'Start game',
    'round': 'Round @n',
    'your_turn': '@name, your turn',
    'bot_thinking': '@name is thinking…',
    'pick_card': 'Pick a card',
    'tap_again_play': 'Tap the card again to play it, or tap the lit hole',
    'tap_again_discard': 'Tap the card again to burn it',
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
    'cards_guide': 'Card guide',
    'card_1': 'ACE — Bring a marble out of the pocket onto your entry hole, OR move a marble 1 step, OR move it 11 steps.',
    'card_13': 'KING — Bring a marble out, OR move 13 steps. On the way it BURNS every marble it passes (sends them back to their pocket).',
    'card_12': 'QUEEN — Move a marble 12 steps forward, OR blindly take one card from the next player into your hand — and they lose their turn.',
    'card_11': 'JACK — Swap the places of two marbles on the track. With the board rule any two marbles (even two other players\'). A marble resting on its own entry hole cannot be swapped.',
    'card_10': '10 — Move a marble 10 steps forward, OR make the next player throw away one card (chosen at random) — and they lose their turn.',
    'card_9': '9 — Move a marble 9 steps forward.',
    'card_8': '8 — Move a marble 8 steps forward.',
    'card_7': '7 — Move a marble 7 steps, OR split the 7 between two marbles (e.g. 3 + 4). Great for entering home exactly.',
    'card_6': '6 — Move a marble 6 steps forward.',
    'card_5': '5 — Move a marble 5 steps forward. You may also move ANY other player\'s marble 5 steps — use it to push an enemy off a good spot or into a burn.',
    'card_4': '4 — Move a marble 4 steps BACKWARD. From your entry hole this drops you just behind your home lane, so a small card gets you home next turn.',
    'card_3': '3 — Move a marble 3 steps forward.',
    'card_2': '2 — Move a marble 2 steps forward.',
    'cards_footer': 'Landing on another marble burns it. A marble on its own entry hole is safe: it cannot be burned, swapped or jumped over. You need the exact number to enter the home lane, and marbles inside it cannot be passed. If none of your cards can be played you must burn one.',
    'play_online': 'Play online',
    'rejoin_room': 'Rejoin room @code',
    'rejoin_failed': 'That room is no longer available.',
    'online_title': 'Online room',
    'your_name': 'Your name',
    'create_room': 'Create room',
    'join_room': 'Join room',
    'room_code': 'Room code',
    'enter_code': 'Enter a 4-letter code',
    'waiting_for': 'Waiting for @name…',
    'waiting_host': 'Waiting for the host to start…',
    'share_code_hint': 'Share this code with your friends. Empty seats become bots when you start.',
    'connecting': 'Connecting…',
    'connection_failed': 'Could not reach the game server. Check your internet and try again.',
    'room_full': 'That room is full.',
    'room_not_found': 'No room with that code (codes expire when the host leaves).',
    'open_seat': 'Open seat',
    'host': 'Host',
    'you': 'You',
    'leave': 'Leave',
    'start_when_ready': 'Start when everyone is in',
    'left_game': '@name left the game',
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
    'rule_ten_skip': 'العشرة تحرق ورقة وتحجب الدور',
    'rule_ten_skip_hint':
        'بدل التحرك، اللاعب التالي يرمي ورقة عشوائية ويخسر دوره.',
    'rule_queen_steal': 'البنت تسرق ورقة وتحجب الدور',
    'rule_queen_steal_hint':
        'بدل التحرك، خذ ورقة عشوائية من اللاعب التالي واحجب دوره.',
    'ten_action': 'احرق ورقة من @name واحجب دوره',
    'queen_action': 'اسرق ورقة من @name واحجب دوره',
    'pick_action': 'اضغط على بلية للتحرك، أو استخدم قوة الورقة',
    'pick_power': 'استخدم قوة الورقة بالأسفل',
    'effect_discard': '@victim خسر ورقة ودوره',
    'effect_steal': '@name سرق ورقة من @victim',
    'start_game': 'ابدأ اللعبة',
    'round': 'الجولة @n',
    'your_turn': '@name، دورك',
    'bot_thinking': '@name يفكر…',
    'pick_card': 'اختر ورقة',
    'tap_again_play': 'اضغط الورقة مرة أخرى للعبها، أو اضغط الخانة المضيئة',
    'tap_again_discard': 'اضغط الورقة مرة أخرى لحرقها',
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
    'cards_guide': 'دليل الأوراق',
    'card_1': 'الآس (A) — أخرج بلية من الجيب إلى خانة دخولك، أو تحرك خطوة واحدة، أو ١١ خطوة.',
    'card_13': 'الشيخ (K) — أخرج بلية، أو تحرك ١٣ خطوة، ويحرق كل بلية يمر عليها في الطريق (ترجع إلى جيبها).',
    'card_12': 'البنت (Q) — تحرك ١٢ خطوة للأمام، أو خذ ورقة عشوائية من اللاعب التالي إلى يدك — ويخسر دوره.',
    'card_11': 'الشايب (J) — بدّل مكان بليتين على المسار. بقاعدة اللوحة أي بليتين (حتى بليتا لاعبَين آخرَين). البلية الواقفة على خانة دخولها لا تُبدَّل.',
    'card_10': '10 — تحرك ١٠ خطوات للأمام، أو اجعل اللاعب التالي يرمي ورقة (عشوائية) — ويخسر دوره.',
    'card_9': '9 — تحرك ٩ خطوات للأمام.',
    'card_8': '8 — تحرك ٨ خطوات للأمام.',
    'card_7': '7 — تحرك ٧ خطوات، أو قسّمها بين بليتين (مثلاً ٣ + ٤). ممتازة لدخول البيت بالرقم المضبوط.',
    'card_6': '6 — تحرك ٦ خطوات للأمام.',
    'card_5': '5 — تحرك ٥ خطوات للأمام. ويمكنك تحريك بلية أي لاعب آخر ٥ خطوات — ادفع الخصم من مكان جيد أو نحو الحرق.',
    'card_4': '4 — تحرك ٤ خطوات للخلف. من خانة دخولك تصبح خلف مدخل بيتك مباشرة، فتدخل البيت بورقة صغيرة في الدور التالي.',
    'card_3': '3 — تحرك ٣ خطوات للأمام.',
    'card_2': '2 — تحرك خطوتين للأمام.',
    'cards_footer': 'النزول على بلية أخرى يحرقها. البلية على خانة دخولها آمنة: لا تُحرق ولا تُبدَّل ولا يُقفز فوقها. تحتاج الرقم المضبوط لدخول البيت، ولا يمكن تجاوز البلي داخله. إذا لم تستطع لعب أي ورقة يجب أن تحرق واحدة.',
    'play_online': 'العب أونلاين',
    'rejoin_room': 'العودة إلى الغرفة @code',
    'rejoin_failed': 'هذه الغرفة لم تعد متاحة.',
    'online_title': 'غرفة أونلاين',
    'your_name': 'اسمك',
    'create_room': 'أنشئ غرفة',
    'join_room': 'انضم إلى غرفة',
    'room_code': 'رمز الغرفة',
    'enter_code': 'أدخل رمزاً من ٤ أحرف',
    'waiting_for': 'في انتظار @name…',
    'waiting_host': 'في انتظار المضيف ليبدأ…',
    'share_code_hint': 'شارك هذا الرمز مع أصدقائك. المقاعد الفارغة تصبح كمبيوتر عند البدء.',
    'connecting': 'جارٍ الاتصال…',
    'connection_failed': 'تعذر الوصول إلى الخادم. تحقق من الإنترنت وحاول مجدداً.',
    'room_full': 'هذه الغرفة ممتلئة.',
    'room_not_found': 'لا توجد غرفة بهذا الرمز (الرمز ينتهي عندما يغادر المضيف).',
    'open_seat': 'مقعد فارغ',
    'host': 'المضيف',
    'you': 'أنت',
    'leave': 'مغادرة',
    'start_when_ready': 'ابدأ عندما يكتمل الجميع',
    'left_game': '@name غادر اللعبة',
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
