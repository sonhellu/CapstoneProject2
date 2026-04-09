class University {
  const University({
    required this.name,
    required this.domains,
  });

  final String name;
  final List<String> domains; // first = default/main domain

  String get defaultDomain => domains.first;
  bool get hasMultipleDomains => domains.length > 1;
}

/// Combines [localPart] and [domain] into a full email address.
String combineEmail(String localPart, String domain) =>
    '${localPart.trim()}@$domain';

/// All valid domains (flat set) for quick lookup.
Set<String> get allUniversityDomains => {
      for (final u in koreanUniversities)
        for (final d in u.domains) d,
    };

/// Returns true if [email] uses a supported university domain.
bool isUniversityEmail(String email) {
  final lower = email.trim().toLowerCase();
  return allUniversityDomains.any((d) => lower.endsWith('@$d'));
}

/// Search universities by name or domain.
List<University> searchUniversities(String query) {
  if (query.isEmpty) return koreanUniversities;
  final q = query.trim().toLowerCase();
  return koreanUniversities
      .where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.domains.any((d) => d.contains(q)))
      .toList();
}

const List<University> koreanUniversities = [
  University(name: 'Seoul National University',       domains: ['snu.ac.kr']),
  University(name: 'KAIST',                           domains: ['kaist.ac.kr', 'student.kaist.ac.kr']),
  University(name: 'Yonsei University',               domains: ['yonsei.ac.kr', 'ms.yonsei.ac.kr']),
  University(name: 'Korea University',                domains: ['korea.ac.kr', 'st.korea.ac.kr']),
  University(name: 'POSTECH',                         domains: ['postech.ac.kr', 'stu.postech.ac.kr']),
  University(name: 'Sungkyunkwan University',         domains: ['skku.edu', 'g.skku.edu']),
  University(name: 'Hanyang University',              domains: ['hanyang.ac.kr', 'hy.ac.kr']),
  University(name: 'Sogang University',               domains: ['sogang.ac.kr']),
  University(name: 'Ewha Womans University',          domains: ['ewha.ac.kr', 'ewhain.net']),
  University(name: 'Kyung Hee University',            domains: ['khu.ac.kr', 'khu.edu']),
  University(name: 'UNIST',                           domains: ['unist.ac.kr']),
  University(name: 'DGIST',                           domains: ['dgist.ac.kr']),
  University(name: 'GIST',                            domains: ['gist.ac.kr', 'ms.gist.ac.kr']),
  University(name: 'Keimyung University',             domains: ['kmu.ac.kr', 'stu.kmu.ac.kr']),
  University(name: 'Incheon National University',     domains: ['inu.ac.kr']),
  University(name: 'Pusan National University',       domains: ['pusan.ac.kr', 'pnu.ac.kr']),
  University(name: 'Kyungpook National University',   domains: ['knu.ac.kr', 'student.knu.ac.kr']),
  University(name: 'Chonnam National University',     domains: ['jnu.ac.kr', 'chonnam.ac.kr']),
  University(name: 'Chungnam National University',    domains: ['cnu.ac.kr', 'o.cnu.ac.kr']),
  University(name: 'Jeonbuk National University',     domains: ['jbnu.ac.kr']),
  University(name: 'Chungbuk National University',    domains: ['cbnu.ac.kr']),
  University(name: 'Kangwon National University',     domains: ['kangwon.ac.kr']),
  University(name: 'Gyeongsang National University',  domains: ['gnu.ac.kr']),
  University(name: 'Jeju National University',        domains: ['jejunu.ac.kr', 'jejuu.ac.kr']),
  University(name: 'Inha University',                 domains: ['inha.ac.kr', 'inha.edu']),
  University(name: 'Konkuk University',               domains: ['konkuk.ac.kr']),
  University(name: 'Dongguk University',              domains: ['dongguk.edu', 'dongguk.ac.kr']),
  University(name: 'Hongik University',               domains: ['hongik.ac.kr']),
  University(name: 'Kookmin University',              domains: ['kookmin.ac.kr', 'stu.kookmin.ac.kr']),
  University(name: 'Sejong University',               domains: ['sejong.ac.kr']),
  University(name: 'Kwangwoon University',            domains: ['kw.ac.kr']),
  University(name: "Sookmyung Women's University",    domains: ['sookmyung.ac.kr']),
  University(name: 'Dankook University',              domains: ['dankook.ac.kr', 'dku.edu']),
  University(name: 'Ajou University',                 domains: ['ajou.ac.kr']),
  University(name: 'Hankuk Univ. of Foreign Studies', domains: ['hufs.ac.kr']),
  University(name: 'Seoul City University',           domains: ['uos.ac.kr']),
  University(name: "Sungshin Women's University",     domains: ['sungshin.ac.kr']),
  University(name: 'Sangmyung University',            domains: ['smu.ac.kr']),
  University(name: 'Gachon University',               domains: ['gachon.ac.kr']),
  University(name: 'Myongji University',              domains: ['mju.ac.kr']),
  University(name: 'Hallym University',               domains: ['hallym.ac.kr']),
  University(name: 'Catholic University of Korea',    domains: ['catholic.ac.kr']),
  University(name: 'Silla University',                domains: ['silla.ac.kr']),
  University(name: 'Yeungnam University',             domains: ['yu.ac.kr', 'ynu.ac.kr']),
  University(name: 'Dong-A University',               domains: ['donga.ac.kr']),
  University(name: 'Pai Chai University',             domains: ['pcu.ac.kr']),
  University(name: 'Woosong University',              domains: ['wsu.ac.kr', 'song.ac.kr']),
  University(name: 'Hannam University',               domains: ['hnu.kr', 'hannam.ac.kr']),
  University(name: 'Daejeon University',              domains: ['dju.ac.kr']),
  University(name: 'Chosun University',               domains: ['chosun.ac.kr']),
];
