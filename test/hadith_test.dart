import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_quran/core/constants/app_constants.dart';
import 'package:my_quran/data/datasources/hadith_local_data_source.dart';
import 'package:my_quran/data/datasources/hadith_notification_data_source.dart';
import 'package:my_quran/data/models/hadith_model.dart';
import 'package:my_quran/data/repositories/hadith_repository_impl.dart';
import 'package:my_quran/domain/entities/hadith.dart';
import 'package:my_quran/domain/repositories/hadith_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'notificationDetails': notificationDetails,
      'androidScheduleMode': androidScheduleMode,
      'payload': payload,
      'matchDateTimeComponents': matchDateTimeComponents,
    });
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => null;

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
    scheduled.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return scheduled
        .map(
          (item) => PendingNotificationRequest(
            item['id'] as int,
            item['title'] as String?,
            item['body'] as String?,
            item['payload'] as String?,
          ),
        )
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Bundled offline hadith dataset', () {
    test('is broad, multilingual, and includes narrators', () async {
      final raw = await rootBundle.loadString(AppAssets.hadiths);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

      expect(list.length, greaterThanOrEqualTo(500));
      final books = list
          .map((item) => item['slug'])
          .whereType<String>()
          .toSet();
      expect(books.length, greaterThanOrEqualTo(8));

      final withRawi = list.where(
        (item) => (item['rawi'] as String?)?.isNotEmpty ?? false,
      );
      expect(withRawi.length, greaterThanOrEqualTo(500));

      for (final item in list) {
        final hadith = HadithModel.fromJson(item).toEntity();
        expect(hadith.book, isNotEmpty);
        expect(hadith.number, greaterThan(0));
        expect(hadith.arabic, isNotEmpty);
        expect(hadith.translation, isNotEmpty);
      }
    });
  });

  group('Hadith Entity & Model (renomureza/hadis-api-id schema)', () {
    test('parses from renomureza JSON format with arab and id fields', () {
      final json = {
        'book': 'Shahih Bukhari',
        'slug': 'bukhari',
        'number': 1,
        'rawi': 'Umar bin Al Khaththab',
        'arab': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        'id': 'Semua perbuatan tergantung niatnya.',
      };

      final model = HadithModel.fromJson(json);
      expect(model.book, 'Shahih Bukhari');
      expect(model.slug, 'bukhari');
      expect(model.number, 1);
      expect(model.arab, 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ');
      expect(model.id, 'Semua perbuatan tergantung niatnya.');
      expect(model.rawi, 'Umar bin Al Khaththab');

      final entity = model.toEntity();
      expect(entity.book, 'Shahih Bukhari');
      expect(entity.number, 1);
      expect(entity.arabic, 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ');
      expect(entity.translation, 'Semua perbuatan tergantung niatnya.');
      expect(entity.reference, 'HR. Shahih Bukhari No. 1');
      expect(entity.rawi, 'Umar bin Al Khaththab');
    });

    test('serializes back to JSON and toEntity preserves all properties', () {
      const entity = Hadith(
        book: 'Muslim',
        slug: 'muslim',
        number: 2699,
        arabic: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا',
        translation: 'Barangsiapa menempuh suatu jalan untuk mencari ilmu...',
      );

      final model = HadithModel.fromEntity(entity);
      final json = model.toJson();

      expect(json['book'], 'Muslim');
      expect(json['slug'], 'muslim');
      expect(json['number'], 2699);
      expect(json['arab'], contains('طَرِيقًا'));
      expect(json['id'], contains('mencari ilmu'));
      expect(json.containsKey('rawi'), isFalse);
    });
  });

  group('Random Selection Logic', () {
    final sampleHadiths = [
      const Hadith(
        book: 'Shahih Bukhari',
        number: 1,
        arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        translation: 'Semua perbuatan tergantung niatnya.',
      ),
      const Hadith(
        book: 'Shahih Muslim',
        number: 2699,
        arabic: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا',
        translation: 'Barangsiapa menempuh suatu jalan untuk mencari ilmu...',
      ),
      const Hadith(
        book: 'Sunan Tirmidzi',
        number: 1987,
        arabic: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ',
        translation: 'Barangsiapa beriman kepada Allah dan hari akhir...',
      ),
    ];

    test('getRandomHadithFromList returns an item from the list', () {
      final picked = getRandomHadithFromList(sampleHadiths, Random(42));
      expect(sampleHadiths.contains(picked), isTrue);
      expect(picked.translation, isNotEmpty);
      expect(picked.arabic, isNotEmpty);
      expect(picked.reference, startsWith('HR. '));
    });

    test(
      'getRandomHadithFromList returns guaranteed fallback when list is empty',
      () {
        final fallback = getRandomHadithFromList([]);
        expect(fallback.number, 1);
        expect(fallback.book, 'Shahih Bukhari');
        expect(fallback.arabic, contains('النِّيَّاتِ'));
        expect(fallback.translation, contains('niat'));
      },
    );

    test(
      'HadithRepositoryImpl returns a random hadith from data source',
      () async {
        late Directory tempDir;
        tempDir = await Directory.systemTemp.createTemp('hadith_test_dir');
        Hive.init(tempDir.path);
        final box = await Hive.openBox<dynamic>('test_hadiths');

        final dataSource = HadithLocalDataSource(box: box);
        await dataSource.cacheHadiths(const [
          Hadith(
            book: 'Shahih Bukhari',
            number: 13,
            arabic: 'لاَ يُؤْمِنُ أَحَدُكُمْ',
            translation: 'Tidak beriman salah seorang di antara kalian...',
          ),
        ]);

        final repo = HadithRepositoryImpl(dataSource);

        final hadith = await repo.getRandomHadith(Random(1));
        expect(hadith.number, 13);
        expect(hadith.book, 'Shahih Bukhari');
        expect(hadith.reference, 'HR. Shahih Bukhari No. 13');

        await box.close();
        await tempDir.delete(recursive: true);
      },
    );
  });

  group('Daily 5:00 AM Notification Scheduling', () {
    late HadithNotificationDataSource notificationDataSource;
    late FakeNotificationsPlugin fakePlugin;

    setUp(() {
      fakePlugin = FakeNotificationsPlugin();
      notificationDataSource = HadithNotificationDataSource(fakePlugin);
    });

    test('nextInstanceOf5AM returns today at 5:00 AM if current time is before 5:00 AM', () {
      final location = tz.getLocation('Asia/Jakarta');
      // 04:15 AM
      final before5AM = tz.TZDateTime(location, 2026, 11, 15, 4, 15);
      final next5AM = notificationDataSource.nextInstanceOf5AM(
        location,
        before5AM,
      );

      expect(next5AM.year, 2026);
      expect(next5AM.month, 11);
      expect(next5AM.day, 15);
      expect(next5AM.hour, 5);
      expect(next5AM.minute, 0);
    });

    test('nextInstanceOf5AM returns tomorrow at 5:00 AM if current time is after 5:00 AM', () {
      final location = tz.getLocation('Asia/Jakarta');
      // 06:30 AM
      final after5AM = tz.TZDateTime(location, 2026, 11, 15, 6, 30);
      final next5AM = notificationDataSource.nextInstanceOf5AM(
        location,
        after5AM,
      );

      expect(next5AM.year, 2026);
      expect(next5AM.month, 11);
      expect(next5AM.day, 16);
      expect(next5AM.hour, 5);
      expect(next5AM.minute, 0);
    });

    test('schedules rolling daily notifications at 5:00 AM with title "Hadis Hari Ini"', () async {
      final hadiths = [
        const Hadith(
          book: 'Shahih Bukhari',
          number: 1,
          arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
          translation: 'Semua perbuatan tergantung niatnya.',
        ),
        const Hadith(
          book: 'Sunan Tirmidzi',
          number: 1956,
          arabic: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
          translation: 'Senyummu di hadapan saudaramu adalah sedekah bagimu.',
        ),
      ];

      final fromTime = DateTime.utc(2026, 11, 15, 12, 0); // 12:00 PM

      await notificationDataSource.scheduleDailyHadiths(
        hadiths: hadiths,
        timeZoneId: 'Asia/Jakarta',
        fromDate: fromTime,
        random: Random(42),
      );

      expect(
        fakePlugin.scheduled,
        hasLength(HadithNotificationDataSource.daysAhead),
      );

      final firstNotification = fakePlugin.scheduled.first;
      expect(firstNotification['id'], HadithNotificationDataSource.dailyId);
      expect(firstNotification['title'], 'Hadis Hari Ini');
      expect(
        firstNotification['body'],
        isIn([
          'Semua perbuatan tergantung niatnya.',
          'Senyummu di hadapan saudaramu adalah sedekah bagimu.',
        ]),
      );

      final scheduledDate = firstNotification['scheduledDate'] as tz.TZDateTime;
      expect(scheduledDate.hour, 5);
      expect(scheduledDate.minute, 0);
      // No daily-repeat component: the rolling one-shots must not stack.
      expect(firstNotification['matchDateTimeComponents'], isNull);
      expect(
        fakePlugin.cancelled,
        contains(HadithNotificationDataSource.dailyId),
      );
    });

    test(
      'rescheduling the same morning does not stack duplicate alarms',
      () async {
        final hadiths = [
          const Hadith(
            book: 'Shahih Bukhari',
            number: 1,
            arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
            translation: 'Semua perbuatan tergantung niatnya.',
          ),
        ];
        final fromTime = DateTime.utc(2026, 11, 15, 12, 0);

        await notificationDataSource.scheduleDailyHadiths(
          hadiths: hadiths,
          timeZoneId: 'Asia/Jakarta',
          fromDate: fromTime,
          random: Random(42),
        );
        await notificationDataSource.scheduleDailyHadiths(
          hadiths: hadiths,
          timeZoneId: 'Asia/Jakarta',
          fromDate: fromTime,
          random: Random(42),
        );

        expect(
          fakePlugin.scheduled,
          hasLength(HadithNotificationDataSource.daysAhead),
        );
      },
    );

    test('a fresh app session reuses the pending OS schedules', () async {
      final hadiths = [
        const Hadith(
          book: 'Shahih Bukhari',
          number: 1,
          arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
          translation: 'Semua perbuatan tergantung niatnya.',
        ),
      ];
      final fromTime = DateTime.utc(2026, 11, 15, 12, 0);

      await notificationDataSource.scheduleDailyHadiths(
        hadiths: hadiths,
        timeZoneId: 'Asia/Jakarta',
        fromDate: fromTime,
        random: Random(42),
      );

      final reopenedDataSource = HadithNotificationDataSource(fakePlugin);
      await reopenedDataSource.scheduleDailyHadiths(
        hadiths: hadiths,
        timeZoneId: 'Asia/Jakarta',
        fromDate: fromTime,
        random: Random(42),
      );

      expect(
        fakePlugin.scheduled,
        hasLength(HadithNotificationDataSource.daysAhead),
      );
    });
  });
}
