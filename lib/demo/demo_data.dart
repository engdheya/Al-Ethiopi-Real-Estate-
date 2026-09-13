import '../models/app_notification.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/area.dart';
import '../models/city.dart';
import '../models/comment.dart';
import '../models/comment_report.dart';
import '../models/contact_message.dart';
import '../models/feature_item.dart';
import '../models/property.dart';
import '../models/property_type.dart';
import '../models/rating_entry.dart';

/// Realistic Yemeni seed data.
///
/// Used in two places:
///  1. Demo mode (app boots without Firebase configured).
///  2. `scripts/seed_demo_data.js` uploads equivalent documents to Firestore.
class DemoData {
  DemoData._();

  static String img(String seed, [int w = 900, int h = 600]) =>
      'https://picsum.photos/seed/$seed/$w/$h';

  // ------------------------------------------------------------------ types

  static List<PropertyType> types() {
    const List<List<String>> rows = <List<String>>[
      <String>['type-apartment', 'شقة', 'apartment'],
      <String>['type-house', 'منزل', 'home'],
      <String>['type-villa', 'فيلا', 'villa'],
      <String>['type-land', 'أرض', 'landscape'],
      <String>['type-shop', 'محل تجاري', 'store'],
      <String>['type-office', 'مكتب', 'business'],
      <String>['type-building', 'عمارة', 'domain'],
      <String>['type-other', 'عقار آخر', 'real_estate_agent'],
    ];
    return <PropertyType>[
      for (int i = 0; i < rows.length; i++)
        PropertyType(id: rows[i][0], name: rows[i][1], icon: rows[i][2], order: i),
    ];
  }

  // ------------------------------------------------------------------ cities

  static List<City> cities() {
    const List<String> names = <String>[
      'صنعاء',
      'عدن',
      'تعز',
      'الحديدة',
      'إب',
      'المكلا',
      'ذمار',
      'مأرب',
    ];
    return <City>[
      for (int i = 0; i < names.length; i++)
        City(id: 'city-$i', name: names[i], order: i),
    ];
  }

  static List<Area> areas() {
    const Map<String, List<String>> byCity = <String, List<String>>{
      'city-0': <String>['حدة', 'بيت بوس', 'شملان', 'السبعين', 'مذبح'],
      'city-1': <String>['المنصورة', 'الشيخ عثمان', 'كريتر', 'خور مكسر', 'المعلا'],
      'city-2': <String>['المسبح', 'وادي القاضي', 'الحوبان', 'الروضة'],
      'city-3': <String>['الكورنيش', 'الحوك', 'الميناء', 'غليل'],
      'city-4': <String>['الظهار', 'المشنة', 'السبل'],
      'city-5': <String>['الديس', 'الشرج', 'فوة'],
      'city-6': <String>['عنس', 'الحدا', 'المدينة'],
      'city-7': <String>['الروضة', 'المطار', 'السوق'],
    };
    final List<Area> out = <Area>[];
    int order = 0;
    byCity.forEach((String cityId, List<String> names) {
      for (final String name in names) {
        out.add(Area(
          id: 'area-$order',
          name: name,
          cityId: cityId,
          order: order++,
        ));
      }
    });
    return out;
  }

  // --------------------------------------------------------------- features

  static List<FeatureItem> features() {
    const List<String> names = <String>[
      'ماء',
      'كهرباء',
      'موقف سيارات',
      'مطبخ',
      'تكييف',
      'حوش',
      'مصعد',
      'مفروش',
      'شارع رئيسي',
      'خزان مياه',
      'إنترنت فايبر',
      'حراسة',
    ];
    return <FeatureItem>[
      for (int i = 0; i < names.length; i++)
        FeatureItem(id: 'feat-$i', name: names[i], order: i),
    ];
  }

  // ------------------------------------------------------------- properties

  static List<PropertyImage> gallery(List<String> seeds) {
    return <PropertyImage>[
      for (int i = 0; i < seeds.length; i++)
        PropertyImage(
          url: img(seeds[i]),
          path: 'demo/${seeds[i]}',
          isMain: i == 0,
          order: i,
        ),
    ];
  }

  static List<Property> properties() {
    final DateTime now = DateTime.now();
    return <Property>[
      Property(
        id: 'demo-p1',
        title: 'شقة فاخرة للإيجار في حدة',
        description:
            'شقة فاخرة بتشطيبات حديثة في حي حدة الراقي، قريبة من جميع الخدمات والمدارس والأسواق. إطلالة مميزة وتهوية ممتازة، صالحة للسكن العائلي الراقي.',
        purpose: PropertyPurpose.rent,
        typeId: 'type-apartment',
        typeName: 'شقة',
        cityId: 'city-0',
        cityName: 'صنعاء',
        areaId: 'area-0',
        areaName: 'حدة',
        address: 'شارع حدة الرئيسي، جوار سوق حدة',
        price: 300000,
        currency: 'YER',
        size: 180,
        bedrooms: 4,
        bathrooms: 3,
        floor: 3,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: true,
        images: gallery(<String>['sanaa-apt-1', 'sanaa-apt-2', 'sanaa-apt-3', 'sanaa-apt-4']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-2', 'feat-3', 'feat-4', 'feat-6'],
        featureNames: const <String>['ماء', 'كهرباء', 'موقف سيارات', 'مطبخ', 'تكييف', 'مصعد'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.5,
        ratingCount: 23,
        favoritesCount: 41,
        commentsCount: 3,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p2',
        title: 'أرض سكنية للبيع في بيت بوس',
        description:
            'أرض سكنية مميزة على شارعين، صك شرعي جاهز، مناسبة لبناء عمارة أو فيلا. الموقع هادئ وقريب من الخدمات.',
        purpose: PropertyPurpose.sale,
        typeId: 'type-land',
        typeName: 'أرض',
        cityId: 'city-0',
        cityName: 'صنعاء',
        areaId: 'area-1',
        areaName: 'بيت بوس',
        address: 'بيت بوس، شارع 30',
        price: 45000000,
        currency: 'YER',
        size: 600,
        bedrooms: 0,
        bathrooms: 0,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['sanaa-land-1', 'sanaa-land-2', 'sanaa-land-3']),
        featureIds: const <String>['feat-8'],
        featureNames: const <String>['شارع رئيسي'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.0,
        ratingCount: 8,
        favoritesCount: 17,
        commentsCount: 2,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p3',
        title: 'فيلا راقية للبيع في المنصورة',
        description:
            'فيلا دورين مع حوش واسع ومسبح، تشطيب فاخر، مجلس خارجي، غرفة سائق، موقع مميز في المنصورة بعدن.',
        purpose: PropertyPurpose.sale,
        typeId: 'type-villa',
        typeName: 'فيلا',
        cityId: 'city-1',
        cityName: 'عدن',
        areaId: 'area-5',
        areaName: 'المنصورة',
        address: 'المنصورة، بلوك 12',
        price: 120000,
        currency: 'USD',
        size: 350,
        bedrooms: 5,
        bathrooms: 4,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: true,
        images: gallery(<String>['aden-villa-1', 'aden-villa-2', 'aden-villa-3', 'aden-villa-4', 'aden-villa-5']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-2', 'feat-3', 'feat-4', 'feat-5', 'feat-9'],
        featureNames: const <String>['ماء', 'كهرباء', 'موقف سيارات', 'مطبخ', 'تكييف', 'حوش', 'خزان مياه'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.8,
        ratingCount: 31,
        favoritesCount: 88,
        commentsCount: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p4',
        title: 'شقة للإيجار في الشيخ عثمان',
        description:
            'شقة نظيفة ومشمسة، دور ثاني، قريبة من السوق والمواصلات. مناسبة لعائلة صغيرة.',
        purpose: PropertyPurpose.rent,
        typeId: 'type-apartment',
        typeName: 'شقة',
        cityId: 'city-1',
        cityName: 'عدن',
        areaId: 'area-6',
        areaName: 'الشيخ عثمان',
        address: 'الشيخ عثمان، جوار المسجد الكبير',
        price: 180000,
        currency: 'YER',
        size: 120,
        bedrooms: 3,
        bathrooms: 2,
        floor: 2,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['aden-apt-1', 'aden-apt-2', 'aden-apt-3']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-3'],
        featureNames: const <String>['ماء', 'كهرباء', 'مطبخ'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 3.9,
        ratingCount: 11,
        favoritesCount: 12,
        commentsCount: 1,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 7)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p5',
        title: 'محل تجاري للإيجار على شارع رئيسي',
        description:
            'محل تجاري واجهة زجاجية على شارع رئيسي في شملان، مناسب لجميع الأنشطة التجارية، مع مخزن خلفي.',
        purpose: PropertyPurpose.rent,
        typeId: 'type-shop',
        typeName: 'محل تجاري',
        cityId: 'city-0',
        cityName: 'صنعاء',
        areaId: 'area-2',
        areaName: 'شملان',
        address: 'شملان، الشارع الرئيسي',
        price: 500000,
        currency: 'YER',
        size: 90,
        bedrooms: 0,
        bathrooms: 1,
        status: PropertyStatus.rented,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['sanaa-shop-1', 'sanaa-shop-2']),
        featureIds: const <String>['feat-1', 'feat-8'],
        featureNames: const <String>['كهرباء', 'شارع رئيسي'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.2,
        ratingCount: 6,
        favoritesCount: 9,
        commentsCount: 0,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 3)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p6',
        title: 'منزل شعبي للبيع في تعز',
        description:
            'منزل دورين بطراز معماري يمني أصيل في وادي القاضي، حوش داخلي، مناسب للسكن أو الاستثمار.',
        purpose: PropertyPurpose.sale,
        typeId: 'type-house',
        typeName: 'منزل',
        cityId: 'city-2',
        cityName: 'تعز',
        areaId: 'area-11',
        areaName: 'وادي القاضي',
        address: 'وادي القاضي، حارة السلام',
        price: 38000000,
        currency: 'YER',
        size: 200,
        bedrooms: 4,
        bathrooms: 2,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['taiz-house-1', 'taiz-house-2', 'taiz-house-3']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-5'],
        featureNames: const <String>['ماء', 'كهرباء', 'حوش'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.1,
        ratingCount: 9,
        favoritesCount: 14,
        commentsCount: 1,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 10)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p7',
        title: 'عمارة استثمارية للبيع في الحديدة',
        description:
            'عمارة 4 أدوار، 8 شقق مؤجرة بالكامل بعوائد ممتازة، موقع استثماري على الكورنيش، أوراق سليمة.',
        purpose: PropertyPurpose.sale,
        typeId: 'type-building',
        typeName: 'عمارة',
        cityId: 'city-3',
        cityName: 'الحديدة',
        areaId: 'area-15',
        areaName: 'الكورنيش',
        address: 'الكورنيش، جوار الميناء',
        price: 250000,
        currency: 'USD',
        size: 800,
        bedrooms: 16,
        bathrooms: 8,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: true,
        images: gallery(<String>['hodeidah-bld-1', 'hodeidah-bld-2', 'hodeidah-bld-3', 'hodeidah-bld-4']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-2', 'feat-6', 'feat-9'],
        featureNames: const <String>['ماء', 'كهرباء', 'موقف سيارات', 'مصعد', 'خزان مياه'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.6,
        ratingCount: 15,
        favoritesCount: 52,
        commentsCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p8',
        title: 'مكتب للإيجار في برج تجاري بحدة',
        description:
            'مكتب مجهز في برج تجاري، تكييف مركزي، مصعد، مواقف خاصة، مناسب للشركات والمؤسسات.',
        purpose: PropertyPurpose.rent,
        typeId: 'type-office',
        typeName: 'مكتب',
        cityId: 'city-0',
        cityName: 'صنعاء',
        areaId: 'area-0',
        areaName: 'حدة',
        address: 'حدة، البرج التجاري، الدور الخامس',
        price: 220000,
        currency: 'YER',
        size: 70,
        bedrooms: 0,
        bathrooms: 1,
        floor: 5,
        status: PropertyStatus.available,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['sanaa-office-1', 'sanaa-office-2']),
        featureIds: const <String>['feat-1', 'feat-2', 'feat-4', 'feat-6', 'feat-10'],
        featureNames: const <String>['كهرباء', 'موقف سيارات', 'تكييف', 'مصعد', 'إنترنت فايبر'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 3.7,
        ratingCount: 4,
        favoritesCount: 6,
        commentsCount: 0,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 14)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p9',
        title: 'أرض زراعية للبيع في ذمار',
        description:
            'أرض زراعية خصبة مع بئر ماء، مناسبة للزراعة أو الاستثمار المستقبلي، أوراق سليمة.',
        purpose: PropertyPurpose.sale,
        typeId: 'type-land',
        typeName: 'أرض',
        cityId: 'city-6',
        cityName: 'ذمار',
        areaId: 'area-24',
        areaName: 'عنس',
        address: 'عنس، وادي رماع',
        price: 12000000,
        currency: 'YER',
        size: 2500,
        bedrooms: 0,
        bathrooms: 0,
        status: PropertyStatus.sold,
        isPublished: true,
        isFeatured: false,
        images: gallery(<String>['dhamar-land-1', 'dhamar-land-2']),
        featureIds: const <String>['feat-0'],
        featureNames: const <String>['ماء'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 4.3,
        ratingCount: 5,
        favoritesCount: 3,
        commentsCount: 0,
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 6)),
        createdBy: 'demo-admin',
      ),
      Property(
        id: 'demo-p10',
        title: 'شقة مفروشة للإيجار في خور مكسر (مسودة)',
        description:
            'شقة مفروشة بالكامل، قريبة من المطار، مناسبة للمغتربين والموظفين. هذه مسودة غير منشورة تظهر في لوحة الإدارة فقط.',
        purpose: PropertyPurpose.rent,
        typeId: 'type-apartment',
        typeName: 'شقة',
        cityId: 'city-1',
        cityName: 'عدن',
        areaId: 'area-8',
        areaName: 'خور مكسر',
        address: 'خور مكسر، جوار المطار',
        price: 250000,
        currency: 'YER',
        size: 95,
        bedrooms: 2,
        bathrooms: 2,
        floor: 1,
        status: PropertyStatus.available,
        isPublished: false,
        isFeatured: false,
        images: gallery(<String>['aden-furn-1', 'aden-furn-2']),
        featureIds: const <String>['feat-0', 'feat-1', 'feat-3', 'feat-4', 'feat-7'],
        featureNames: const <String>['ماء', 'كهرباء', 'مطبخ', 'تكييف', 'مفروش'],
        phone: '967771234567',
        whatsapp: '967771234567',
        ratingAvg: 0,
        ratingCount: 0,
        favoritesCount: 0,
        commentsCount: 0,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        createdBy: 'demo-admin',
      ),
    ];
  }

  // --------------------------------------------------------------- comments

  static List<PropertyComment> comments() {
    final DateTime now = DateTime.now();
    return <PropertyComment>[
      PropertyComment(
        id: 'demo-c1',
        propertyId: 'demo-p1',
        userId: 'demo-user-1',
        userName: 'محمد الحميري',
        text: 'شقة رائعة والموقع ممتاز، تعاملت مع المعلن وكان راقياً في التعامل. أنصح بها.',
        rating: 5,
        likedBy: const <String>['demo-user-2', 'demo-user-3'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PropertyComment(
        id: 'demo-c2',
        propertyId: 'demo-p1',
        userId: 'demo-user-2',
        userName: 'أحمد الشرعبي',
        text: 'هل السعر شامل الماء والكهرباء؟ وهل يوجد مصعد في العمارة؟',
        rating: 4,
        likedBy: const <String>['demo-user-1'],
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      PropertyComment(
        id: 'demo-c3',
        propertyId: 'demo-p1',
        userId: 'demo-user-3',
        userName: 'سارة العمودي',
        text: 'زرت الشقة أمس، التشطيب فعلاً فاخر لكن الشارع مزدحم وقت الذروة.',
        rating: 4,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      PropertyComment(
        id: 'demo-c4',
        propertyId: 'demo-p3',
        userId: 'demo-user-2',
        userName: 'أحمد الشرعبي',
        text: 'فيلا تحفة ما شاء الله، الحوش واسع والمسبح نظيف. السعر مناسب لموقع المنصورة.',
        rating: 5,
        likedBy: const <String>['demo-user-1', 'demo-user-3', 'demo-user-4'],
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      PropertyComment(
        id: 'demo-c5',
        propertyId: 'demo-p2',
        userId: 'demo-user-4',
        userName: 'خالد المطري',
        text: 'هل الصك جاهز للفراغ مباشرة؟ وما عرض الشارع الأمامي؟',
        rating: 4,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PropertyComment(
        id: 'demo-c6',
        propertyId: 'demo-p7',
        userId: 'demo-user-1',
        userName: 'محمد الحميري',
        text: 'فرصة استثمارية قوية، العائد الشهري ممتاز حسب ما ذكر المعلن.',
        rating: 5,
        likedBy: const <String>['demo-user-2'],
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }

  static Map<String, RatingEntry> ratings() {
    final DateTime now = DateTime.now();
    final List<RatingEntry> list = <RatingEntry>[
      RatingEntry(id: 'demo-p1_demo-user-1', propertyId: 'demo-p1', userId: 'demo-user-1', value: 5, createdAt: now.subtract(const Duration(days: 1))),
      RatingEntry(id: 'demo-p1_demo-user-2', propertyId: 'demo-p1', userId: 'demo-user-2', value: 4, createdAt: now.subtract(const Duration(hours: 20))),
      RatingEntry(id: 'demo-p3_demo-user-2', propertyId: 'demo-p3', userId: 'demo-user-2', value: 5, createdAt: now.subtract(const Duration(hours: 10))),
    ];
    return <String, RatingEntry>{for (final RatingEntry r in list) r.id: r};
  }

  // ------------------------------------------------------------------ users

  static List<AppUser> users() {
    final DateTime now = DateTime.now();
    return <AppUser>[
      AppUser(uid: 'demo-admin', displayName: 'مدير التطبيق', email: 'admin@alethiopi.com', createdAt: now.subtract(const Duration(days: 90))),
      AppUser(uid: 'demo-user-1', displayName: 'محمد الحميري', email: 'mohammed@example.com', createdAt: now.subtract(const Duration(days: 60))),
      AppUser(uid: 'demo-user-2', displayName: 'أحمد الشرعبي', email: 'ahmed@example.com', createdAt: now.subtract(const Duration(days: 45))),
      AppUser(uid: 'demo-user-3', displayName: 'سارة العمودي', email: 'sara@example.com', createdAt: now.subtract(const Duration(days: 30))),
      AppUser(uid: 'demo-user-4', displayName: 'خالد المطري', email: 'khaled@example.com', createdAt: now.subtract(const Duration(days: 12))),
    ];
  }

  // ---------------------------------------------------------------- reports

  static List<CommentReport> reports() {
    final DateTime now = DateTime.now();
    return <CommentReport>[
      CommentReport(
        id: 'demo-r1',
        commentId: 'demo-c2',
        propertyId: 'demo-p1',
        reporterId: 'demo-user-3',
        reason: 'معلومات مضللة',
        details: 'السؤال مكرر في كل العقارات.',
        commentText: 'هل السعر شامل الماء والكهرباء؟',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      CommentReport(
        id: 'demo-r2',
        commentId: 'demo-c5',
        propertyId: 'demo-p2',
        reporterId: 'demo-user-1',
        reason: 'أخرى',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  // --------------------------------------------------------------- messages

  static List<ContactMessage> messages() {
    final DateTime now = DateTime.now();
    return <ContactMessage>[
      ContactMessage(
        id: 'demo-m1',
        name: 'عبدالله السقاف',
        phone: '967733112233',
        message: 'السلام عليكم، أبحث عن شقة للإيجار في صنعاء بحدود 200 ألف، هل تتوفر لديكم خيارات؟',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ContactMessage(
        id: 'demo-m2',
        name: 'فاطمة الشامي',
        phone: '967770445566',
        message: 'هل يمكن إضافة عقاري الخاص للبيع في التطبيق؟',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  // ------------------------------------------------------------ notifications

  static List<AppNotification> notifications() {
    final DateTime now = DateTime.now();
    return <AppNotification>[
      AppNotification(
        id: 'demo-n1',
        title: 'فيلا جديدة مميزة في المنصورة',
        body: 'تمت إضافة فيلا راقية للبيع في المنصورة بعدن، اكتشف التفاصيل والصور الآن.',
        type: 'featured_property',
        propertyId: 'demo-p3',
        createdAt: now.subtract(const Duration(hours: 11)),
      ),
      AppNotification(
        id: 'demo-n2',
        title: 'مرحباً بك في الأثيوبي للعقارات',
        body: 'تصفح أحدث الشقق والأراضي والعقارات في اليمن وتواصل مباشرة مع المعلن.',
        type: 'announcement',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  // ---------------------------------------------------------------- settings

  static AppSettings settings() {
    return const AppSettings(
      phone: '967771234567',
      whatsapp: '967771234567',
      email: 'info@alethiopi-realestate.com',
      address: 'صنعاء، شارع حدة، جوار برج الأثيوبي',
      facebookUrl: 'https://facebook.com/alethiopi.realestate',
      aboutAr:
          'الأثيوبي للعقارات منصة يمنية متخصصة في عرض الشقق والأراضي والعقارات للبيع والإيجار. نهدف إلى تسهيل رحلة البحث عن العقار المثالي عبر صور واضحة ومعلومات دقيقة وتواصل مباشر مع المعلن.',
      termsAr:
          'باستخدامك للتطبيق فأنت توافق على: احترام حقوق الآخرين، وعدم نشر محتوى مسيء أو مضلل في التعليقات، وأن المعلومات المعروضة استرشادية ويُنصح بالمعاينة قبل أي تعاقد. يحق للإدارة حذف أي محتوى مخالف دون إشعار.',
      privacyAr:
          'نجمع الحد الأدنى من البيانات اللازمة لتشغيل التطبيق (الاسم والبريد الإلكتروني عند التسجيل). لا نبيع بياناتك لأي طرف ثالث، وتُستخدم بيانات التواصل فقط لتحسين الخدمة والرد على استفساراتك.',
    );
  }
}
