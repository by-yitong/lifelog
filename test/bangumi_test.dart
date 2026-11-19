import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/counter_edit/data/bangumi.dart';

void main() {
  test('解析老版搜索结果：中文名优先、封面优先取 large、http 升级 https', () {
    final body = jsonEncode({
      'results': 33,
      'list': [
        {
          'id': 153197,
          'name': '斗破苍穹',
          'name_cn': '斗破苍穹',
          'images': {
            'small': 'http://lain.bgm.tv/pic/cover/s/a.jpg',
            'large': 'http://lain.bgm.tv/pic/cover/l/a.jpg',
            'medium': 'http://lain.bgm.tv/pic/cover/m/a.jpg',
          },
        },
        {
          'id': 999,
          'name': 'Frieren',
          'name_cn': '',
          'images': {'common': 'http://lain.bgm.tv/pic/cover/c/b.jpg'},
        },
      ],
    });

    final subjects = parseBangumiSearch(body);

    expect(subjects, hasLength(2));
    expect(subjects[0].id, '153197');
    expect(subjects[0].name, '斗破苍穹');
    expect(subjects[0].originName, '斗破苍穹');
    expect(subjects[0].coverUrl, 'https://lain.bgm.tv/pic/cover/l/a.jpg');
    expect(subjects[1].name, 'Frieren'); // 中文名为空时回退原名
    expect(subjects[1].coverUrl, 'https://lain.bgm.tv/pic/cover/c/b.jpg');
  });

  test('无封面图或畸形数据被跳过；空/非对象响应安全返回空', () {
    final noCover = jsonEncode({
      'list': [
        {'id': 1, 'name': 'x', 'name_cn': '', 'images': {}},
      ],
    });
    expect(parseBangumiSearch(noCover), isEmpty);
    expect(parseBangumiSearch('{"list": "oops"}'), isEmpty);
    expect(() => parseBangumiSearch('not json at all'),
        throwsFormatException);
  });
}
