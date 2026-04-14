/// Domain model for a community post.
class PostAuthor {
  const PostAuthor({
    required this.name,
    required this.school,
    required this.major,
    this.avatarUrl,
    this.avatarInitial = '?',
  });

  final String name;
  final String school;
  final String major;
  final String? avatarUrl;
  final String avatarInitial;
}

class Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.time,
    required this.category,
    this.images = const [],
    required this.language,
    this.likes = 0,
    this.comments = 0,
    this.userId = '',
  });

  final String id;
  final String title;
  final String content;
  final PostAuthor author;

  /// Display string, e.g. "2h ago" or "3 days ago".
  final String time;

  /// e.g. "International", "Campus", "Scholarship", "Housing"
  final String category;

  final List<String> images;

  /// Language code shown as tag: "VN", "KR", "EN"
  final String language;

  final int likes;
  final int comments;

  /// UID of the user who created this post.
  final String userId;

  Post copyWith({
    String? id,
    String? title,
    String? content,
    PostAuthor? author,
    String? time,
    String? category,
    List<String>? images,
    String? language,
    int? likes,
    int? comments,
    String? userId,
  }) =>
      Post(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        author: author ?? this.author,
        time: time ?? this.time,
        category: category ?? this.category,
        images: images ?? this.images,
        language: language ?? this.language,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        userId: userId ?? this.userId,
      );
}

// ─────────────────────────── Mock Data ───────────────────────────

const mockPosts = [
  Post(
    id: 'p1',
    title: 'Tips for your first semester in Korea 🇰🇷',
    content:
        'Moving to Korea can feel overwhelming at first, but with the right preparation everything becomes manageable. '
        'In this post I will walk you through the five most important things to sort out before classes begin.\n\n'
        '**1. Get a Korean SIM card**\nHead to any KT, SKT or LG U+ booth right at Incheon Airport. '
        'A prepaid data SIM costs around ₩30,000 and will keep you connected from day one.\n\n'
        '**2. Open a bank account**\nKeimyung\'s global office can issue a letter that most banks accept. '
        'Kakao Bank or Toss Bank are the easiest for foreigners — the entire process is done through an app.\n\n'
        '**3. Register your foreigner ID (ARC)**\nWithin 90 days of arrival you must visit the local Immigration Office. '
        'Bring your passport, enrollment certificate, and a passport photo.\n\n'
        '**4. Find housing early**\nUniversity dormitories fill up fast. Apply as soon as the portal opens. '
        'Off-campus options in the Daemyeong-dong area are affordable and close to campus.\n\n'
        '**5. Download KakaoTalk**\nEvery Korean student, professor, and delivery service uses KakaoTalk. '
        'It is not optional!',
    author: PostAuthor(
      name: 'Nguyen Van An',
      school: 'Keimyung University',
      major: 'Computer Engineering',
      avatarInitial: 'N',
    ),
    time: '2h ago',
    category: 'International',
    images: [
      'https://images.unsplash.com/photo-1541410965313-d53b3c16ef17?w=800',
      'https://images.unsplash.com/photo-1607013251379-e6eecfffe234?w=800',
    ],
    language: 'VN',
    likes: 48,
    comments: 12,
  ),
  Post(
    id: 'p2',
    title: 'GKS Scholarship 2025 — Complete Guide',
    content:
        'The Global Korea Scholarship (GKS) is the most prestigious scholarship for international students. '
        'Here is everything you need to apply for the 2025 cycle.\n\n'
        '**Eligibility**\nApplicants must hold citizenship of a GKS-eligible country, be under 25, '
        'and maintain a GPA above 80%.\n\n'
        '**Benefits**\nFull tuition, monthly allowance of ₩900,000, round-trip airfare, and Korean language training.\n\n'
        '**Important Dates**\n- Application Open: February 2025\n- Deadline: March 14, 2025\n- Results: May 2025',
    author: PostAuthor(
      name: 'Tanaka Yuki',
      school: 'Keimyung University',
      major: 'Business Administration',
      avatarInitial: 'T',
    ),
    time: '5h ago',
    category: 'Scholarship',
    images: [
      'https://images.unsplash.com/photo-1627556704302-624286467c65?w=800',
    ],
    language: 'EN',
    likes: 132,
    comments: 34,
  ),
  Post(
    id: 'p3',
    title: '대명동 맛집 추천 리스트 2025',
    content:
        '학교 근처 대명동에서 자주 가는 맛집들을 정리해봤어요. 유학생 친구들도 꼭 한 번 가보세요!\n\n'
        '**1. 국밥집 "할매국밥"** — 국물이 진하고 가격도 저렴해요 (7,000원~)\n\n'
        '**2. 분식 "명동분식"** — 떡볶이, 순대, 튀김 조합이 최고예요.\n\n'
        '**3. 카페 "더 프레임"** — 공부하기 좋은 분위기, 와이파이 빵빵해요.\n\n'
        '**4. 치킨 "교촌치킨 대명점"** — 한국 치킨 입문하기 딱 좋아요.',
    author: PostAuthor(
      name: 'Kim Jisoo',
      school: 'Keimyung University',
      major: 'Korean Language & Lit.',
      avatarInitial: 'K',
    ),
    time: '1d ago',
    category: 'Campus',
    images: [
      'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=800',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
    ],
    language: 'KR',
    likes: 87,
    comments: 21,
  ),
  Post(
    id: 'p4',
    title: 'Finding cheap housing near Keimyung',
    content:
        'After spending two semesters in the dorms I finally moved off-campus and cut my monthly rent in half. '
        'Here is my honest guide to finding a room or studio in Daegu.\n\n'
        '**Platforms to use**\n- Zigbang (직방) — best app for foreigners, has English support\n'
        '- Dabang (다방) — great for finding 고시원 (small single rooms)\n\n'
        '**Price ranges (2025)**\n- 고시원: ₩250,000–400,000/month\n- One-room (원룸): ₩350,000–550,000/month\n\n'
        '**Tips**\nAlways ask for a 전월세 contract. Bring your ARC card to every viewing. '
        'Use Naver Map to measure the walking distance to campus before committing.',
    author: PostAuthor(
      name: 'Ahmed Hassan',
      school: 'Keimyung University',
      major: 'Architecture',
      avatarInitial: 'A',
    ),
    time: '2d ago',
    category: 'Housing',
    images: [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
    ],
    language: 'EN',
    likes: 61,
    comments: 8,
  ),
  Post(
    id: 'p5',
    title: 'Hướng dẫn đăng ký môn học học kỳ mới',
    content:
        'Mình chia sẻ kinh nghiệm đăng ký môn học tại trường Keimyung cho các bạn năm nhất.\n\n'
        '**Bước 1: Đăng nhập hệ thống**\nVào portal.kmu.ac.kr và dùng tài khoản trường cấp.\n\n'
        '**Bước 2: Xem thời khóa biểu**\nVào mục "Course Registration" → chọn học kỳ → lọc theo ngành.\n\n'
        '**Bước 3: Đăng ký sớm**\nHệ thống mở lúc 9:00 AM ngày đã thông báo. Server rất hay bị quá tải '
        'nên nên chuẩn bị sẵn danh sách môn từ trước.\n\n'
        '**Lưu ý**: Môn tiếng Hàn (Korean Language) bắt buộc với du học sinh năm nhất.',
    author: PostAuthor(
      name: 'Tran Thi Mai',
      school: 'Keimyung University',
      major: 'International Trade',
      avatarInitial: 'M',
    ),
    time: '3d ago',
    category: 'Academic',
    images: [],
    language: 'VN',
    likes: 55,
    comments: 17,
  ),
  Post(
    id: 'p6',
    title: 'Korean language exchange partners wanted!',
    content:
        'Hi everyone! I am looking for Korean students who want to do a language exchange. '
        'I can teach English or Vietnamese in exchange for Korean conversation practice.\n\n'
        'My level: TOPIK 3 (reading OK, speaking needs work 😅)\n\n'
        'Preferred times: weekday evenings or Saturday afternoon\n'
        'Location: campus library or a nearby café\n\n'
        'Please DM me or comment below if you are interested!',
    author: PostAuthor(
      name: 'Linh Pham',
      school: 'Keimyung University',
      major: 'Korean Language',
      avatarInitial: 'L',
    ),
    time: '4d ago',
    category: 'International',
    images: [],
    language: 'EN',
    likes: 29,
    comments: 41,
  ),
];
