import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../models/rent_item.dart';

class RentService {
  final _api = ApiClient();

  // 지역코드 기본값: 27290 = 대구 달서구 (Keimyung University)
  // data.go.kr thường trễ 2-3 tháng → thử lùi tối đa 6 tháng
  Future<List<RentItem>> fetchRent({String lawdCd = '27290'}) async {
    final now = DateTime.now();
    for (var offset = 2; offset <= 20; offset++) {
      final target = DateTime(now.year, now.month - offset);
      final ym =
          '${target.year}${target.month.toString().padLeft(2, '0')}';
      final res = await _api.get(
        '/api/rent',
        queryParams: {'lawd_cd': lawdCd, 'deal_ymd': ym},
      );
      if (res.statusCode != 200) continue;
      final list = jsonDecode(res.body) as List;
      if (list.isNotEmpty) {
        return list
            .map((e) => RentItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
