/// Central Arabic strings catalog.
///
/// The app ships Arabic-first (RTL). Everything user-facing lives here so an
/// English localization can be added later by introducing an `AppStringsEn`
/// implementation behind the same getters.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'الأثيوبي للعقارات';
  static const String appNameEn = 'Al-Ethiopi Real Estate';
  static const String appTagline = 'عقارك المثالي بانتظارك';

  // Splash / hero
  static const String heroTitle = 'ابحث عن عقارك المثالي';
  static const String heroSubtitle =
      'شقق وأراضي وعقارات للبيع والإيجار، ابحث عن العقار المناسب لك وتواصل مباشرة مع المعلن.';

  // Bottom navigation (user)
  static const String navHome = 'الرئيسية';
  static const String navProperties = 'العقارات';
  static const String navFavorites = 'المفضلة';
  static const String navAccount = 'الحساب';

  // Bottom navigation (admin)
  static const String navDashboard = 'لوحة التحكم';
  static const String navAdminProperties = 'العقارات';
  static const String navAdminComments = 'التعليقات';
  static const String navAdminMessages = 'الرسائل';
  static const String navAdminMore = 'المزيد';

  // Home
  static const String searchHint = 'ابحث عن شقة، أرض، مدينة...';
  static const String featuredProperties = 'عقارات مميزة';
  static const String latestProperties = 'أحدث العقارات';
  static const String apartmentsForRent = 'شقق للإيجار';
  static const String landsForSale = 'أراضٍ للبيع';
  static const String browseCategories = 'تصفح حسب النوع';
  static const String popularCities = 'مدن رائجة';
  static const String viewAll = 'عرض الكل';
  static const String quickRent = 'إيجار';
  static const String quickSale = 'بيع';
  static const String quickContact = 'تواصل معنا';
  static const String quickFavorites = 'المفضلة';

  // Property vocabulary
  static const String sale = 'للبيع';
  static const String rent = 'للإيجار';
  static const String purpose = 'الغرض';
  static const String propertyType = 'نوع العقار';
  static const String city = 'المدينة';
  static const String area = 'المنطقة';
  static const String address = 'العنوان';
  static const String price = 'السعر';
  static const String currency = 'العملة';
  static const String size = 'المساحة';
  static const String sizeUnit = 'م²';
  static const String bedrooms = 'غرف النوم';
  static const String bathrooms = 'الحمامات';
  static const String floor = 'الدور';
  static const String status = 'الحالة';
  static const String description = 'الوصف';
  static const String features = 'المميزات';
  static const String contactInfo = 'معلومات المعلن';
  static const String propertyName = 'اسم العقار';
  static const String phoneNumber = 'رقم الهاتف';
  static const String whatsappNumber = 'رقم الواتساب';
  static const String featured = 'مميز';
  static const String published = 'منشور';
  static const String unpublished = 'مخفي';
  static const String mainImage = 'الصورة الرئيسية';

  static const String statusAvailable = 'متاح';
  static const String statusRented = 'مؤجر';
  static const String statusSold = 'مباع';
  static const String statusUnavailable = 'غير متاح';

  // Property details actions
  static const String callNow = 'اتصل الآن';
  static const String whatsapp = 'واتساب';
  static const String save = 'حفظ';
  static const String saved = 'محفوظ';
  static const String share = 'مشاركة';
  static const String shareViaApps = 'مشاركة عبر التطبيقات';
  static const String copyTextLabel = 'نسخ النص';
  static const String comments = 'التعليقات';
  static const String specifications = 'المواصفات';
  static const String gallery = 'معرض الصور';

  // Search & filters
  static const String searchTitle = 'البحث';
  static const String filters = 'الفلاتر';
  static const String applyFilters = 'تطبيق';
  static const String clearFilters = 'مسح الكل';
  static const String all = 'الكل';
  static const String optional = 'اختياري';
  static const String minPrice = 'أقل سعر';
  static const String maxPrice = 'أعلى سعر';
  static const String minSize = 'أقل مساحة';
  static const String maxSize = 'أكبر مساحة';
  static const String minBedrooms = 'غرف النوم (على الأقل)';
  static const String minBathrooms = 'الحمامات (على الأقل)';
  static const String sortBy = 'ترتيب حسب';
  static const String sortNewest = 'الأحدث';
  static const String sortPriceAsc = 'السعر: من الأقل';
  static const String sortPriceDesc = 'السعر: من الأعلى';
  static const String recentSearches = 'عمليات بحث سابقة';
  static const String pickCityFirst = 'اختر المدينة أولاً';
  static const String anyCity = 'كل المدن';
  static const String anyArea = 'كل المناطق';
  static const String anyType = 'كل الأنواع';

  // Comments & ratings
  static const String addComment = 'أضف تعليقاً';
  static const String commentHint = 'شاركنا رأيك في هذا العقار...';
  static const String editComment = 'تعديل التعليق';
  static const String deleteComment = 'حذف التعليق';
  static const String deleteCommentConfirm =
      'هل أنت متأكد من حذف هذا التعليق؟ لا يمكن التراجع عن ذلك.';
  static const String reportComment = 'الإبلاغ عن تعليق';
  static const String reportReason = 'سبب الإبلاغ';
  static const String reportDetails = 'تفاصيل إضافية (اختياري)';
  static const String reportDetailsHint = 'اشرح سبب الإبلاغ باختصار...';
  static const String submitReport = 'إرسال البلاغ';
  static const String rateProperty = 'قيّم هذا العقار';
  static const String yourRating = 'تقييمك';
  static const String ratingsCount = 'تقييم';
  static const String noRatingYet = 'لا يوجد تقييم بعد';
  static const String likes = 'إعجاب';
  static const List<String> reportReasons = <String>[
    'محتوى مسيء',
    'إعلان مزعج',
    'معلومات مضللة',
    'محتوى غير مناسب',
    'أخرى',
  ];

  // Auth
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirm = 'هل تريد تسجيل الخروج من حسابك؟';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String fullName = 'الاسم الكامل';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String resetPassword = 'استعادة كلمة المرور';
  static const String sendResetLink = 'إرسال رابط الاستعادة';
  static const String resetLinkSent =
      'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني.';
  static const String loginWithGoogle = 'الدخول عبر Google';
  static const String continueAsGuest = 'المتابعة كضيف';
  static const String noAccount = 'ليس لديك حساب؟';
  static const String alreadyHaveAccount = 'لديك حساب بالفعل؟';
  static const String loginRequired = 'تسجيل الدخول مطلوب';
  static const String loginRequiredToComment =
      'سجّل الدخول لتتمكن من إضافة تعليق وتقييم العقارات.';
  static const String welcomeBack = 'مرحباً بعودتك';
  static const String createAccountTitle = 'أنشئ حسابك مجاناً';
  static const String guestUser = 'زائر';
  static const String memberSince = 'عضو منذ';

  // Profile / account
  static const String profile = 'الحساب';
  static const String editProfile = 'تعديل الملف الشخصي';
  static const String displayName = 'الاسم';
  static const String myFavorites = 'عقاراتي المفضلة';
  static const String notifications = 'الإشعارات';
  static const String contactUs = 'تواصل معنا';
  static const String aboutApp = 'عن التطبيق';
  static const String termsOfUse = 'شروط الاستخدام';
  static const String privacyPolicy = 'سياسة الخصوصية';
  static const String appVersion = 'إصدار التطبيق';
  static const String adminPanel = 'لوحة الإدارة';
  static const String openAdminPanel = 'الدخول إلى لوحة الإدارة';

  // Contact
  static const String contactTitle = 'تواصل معنا';
  static const String contactSubtitle =
      'يسعدنا تواصلك معنا، املأ النموذج التالي وسنرد عليك قريباً.';
  static const String yourName = 'الاسم';
  static const String yourPhone = 'رقم الهاتف';
  static const String yourMessage = 'رسالتك';
  static const String messageHint = 'اكتب رسالتك هنا...';
  static const String sendMessage = 'إرسال الرسالة';
  static const String callUs = 'اتصل بنا';
  static const String emailUs = 'راسلنا';
  static const String ourAddress = 'عنواننا';

  // Notifications
  static const String notificationsTitle = 'الإشعارات';
  static const String noNotifications = 'لا توجد إشعارات بعد';
  static const String openProperty = 'عرض العقار';
  static const String notificationsPermissionTitle = 'تفعيل الإشعارات';
  static const String notificationsPermissionMsg =
      'فعّل الإشعارات ليصلك جديد العقارات المميزة والإعلانات المهمة.';

  // Admin
  static const String dashboard = 'لوحة التحكم';
  static const String totalProperties = 'إجمالي العقارات';
  static const String propertiesForSale = 'عقارات للبيع';
  static const String propertiesForRent = 'عقارات للإيجار';
  static const String featuredCount = 'عقارات مميزة';
  static const String availableCount = 'عقارات متاحة';
  static const String soldCount = 'عقارات مباعة';
  static const String rentedCount = 'عقارات مؤجرة';
  static const String totalComments = 'التعليقات';
  static const String pendingReports = 'بلاغات قيد المراجعة';
  static const String totalUsers = 'المستخدمون';
  static const String addProperty = 'إضافة عقار';
  static const String editProperty = 'تعديل العقار';
  static const String manageProperties = 'إدارة العقارات';
  static const String manageTypes = 'أنواع العقارات';
  static const String manageCities = 'المدن';
  static const String manageAreas = 'المناطق';
  static const String manageFeatures = 'المميزات';
  static const String moderateComments = 'إدارة التعليقات';
  static const String reports = 'البلاغات';
  static const String messages = 'رسائل التواصل';
  static const String sendNotification = 'إرسال إشعار';
  static const String appSettings = 'إعدادات التطبيق';
  static const String publish = 'نشر';
  static const String unpublish = 'إخفاء';
  static const String markFeatured = 'تمييز';
  static const String unmarkFeatured = 'إلغاء التمييز';
  static const String deleteProperty = 'حذف العقار';
  static const String deletePropertyConfirm =
      'هل أنت متأكد من حذف هذا العقار نهائياً مع جميع صوره؟ لا يمكن التراجع.';
  static const String addImages = 'إضافة صور';
  static const String changeMainImage = 'تعيين كصورة رئيسية';
  static const String deleteImage = 'حذف الصورة';
  static const String deleteImageConfirm = 'هل تريد حذف هذه الصورة؟';
  static const String saveChanges = 'حفظ التغييرات';
  static const String addNew = 'إضافة جديد';
  static const String itemName = 'الاسم';
  static const String showInApp = 'ظاهر في التطبيق';
  static const String order = 'الترتيب';
  static const String notificationTitle = 'عنوان الإشعار';
  static const String notificationBody = 'نص الإشعار';
  static const String linkedProperty = 'العقار المرتبط (اختياري)';
  static const String noLinkedProperty = 'بدون ربط';
  static const String markReportReviewed = 'تمت المراجعة';
  static const String dismissReport = 'تجاهل البلاغ';
  static const String viewComment = 'عرض التعليق';
  static const String hideComment = 'إخفاء التعليق';
  static const String showComment = 'إظهار التعليق';
  static const String markMessageRead = 'تعيين كمقروءة';
  static const String messageDetails = 'تفاصيل الرسالة';
  static const String adminOnly = 'هذه الصفحة خاصة بالإدارة فقط.';
  static const String noPermission = 'ليست لديك صلاحية لتنفيذ هذا الإجراء.';

  // Settings fields
  static const String settingsPhone = 'هاتف التواصل';
  static const String settingsWhatsapp = 'واتساب التواصل';
  static const String settingsEmail = 'البريد الإلكتروني';
  static const String settingsAddress = 'العنوان';
  static const String settingsFacebook = 'رابط فيسبوك';
  static const String settingsAbout = 'نبذة عن التطبيق';
  static const String settingsTerms = 'شروط الاستخدام';
  static const String settingsPrivacy = 'سياسة الخصوصية';

  // Common actions
  static const String ok = 'حسناً';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String saveAction = 'حفظ';
  static const String close = 'إغلاق';
  static const String retry = 'إعادة المحاولة';
  static const String loading = 'جارٍ التحميل...';
  static const String copyLink = 'نسخ الرابط';
  static const String seeMore = 'عرض المزيد';

  // States & messages
  static const String noInternet = 'لا يوجد اتصال بالإنترنت.';
  static const String backOnline = 'تمت استعادة الاتصال بالإنترنت.';
  static const String somethingWentWrong = 'حدث خطأ، حاول مرة أخرى.';
  static const String noResults = 'لم يتم العثور على عقارات.';
  static const String noResultsHint = 'جرّب تعديل البحث أو الفلاتر.';
  static const String noFavorites = 'لا توجد عقارات محفوظة.';
  static const String noFavoritesHint =
      'اضغط على أيقونة القلب لحفظ العقارات التي تعجبك هنا.';
  static const String noCommentsYet = 'لا توجد تعليقات بعد.';
  static const String beFirstToComment = 'كن أول من يعلّق على هذا العقار.';
  static const String demoModeBanner = 'وضع العرض — البيانات تجريبية وليست من Firebase';
  static const String linkCopied = 'تم نسخ الرابط.';
  static const String textCopied = 'تم النسخ.';

  // Success messages
  static const String commentAdded = 'تمت إضافة التعليق بنجاح.';
  static const String commentUpdated = 'تم تعديل التعليق بنجاح.';
  static const String commentDeleted = 'تم حذف التعليق.';
  static const String ratingSaved = 'شكراً لك! تم حفظ تقييمك.';
  static const String favoriteAdded = 'تمت الإضافة إلى المفضلة.';
  static const String favoriteRemoved = 'تمت الإزالة من المفضلة.';
  static const String reportSent = 'تم إرسال البلاغ، شكراً لك.';
  static const String messageSent = 'تم إرسال رسالتك بنجاح.';
  static const String propertySaved = 'تم حفظ العقار بنجاح.';
  static const String propertyDeleted = 'تم حذف العقار.';
  static const String imageDeleted = 'تم حذف الصورة.';
  static const String notificationSent = 'تم إرسال الإشعار.';
  static const String profileUpdated = 'تم تحديث الملف الشخصي.';
  static const String settingsSaved = 'تم حفظ الإعدادات.';
  static const String accountCreated = 'تم إنشاء حسابك بنجاح، أهلاً بك.';

  // Validation
  static const String requiredField = 'هذا الحقل مطلوب.';
  static const String invalidEmail = 'البريد الإلكتروني غير صالح.';
  static const String shortPassword = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين.';
  static const String invalidPhone = 'رقم الهاتف غير صالح.';
  static const String invalidPrice = 'أدخل سعراً صالحاً أكبر من صفر.';
  static const String invalidSize = 'أدخل مساحة صالحة أكبر من صفر.';
  static const String commentEmpty = 'التعليق لا يمكن أن يكون فارغاً.';
  static const String commentTooLong = 'التعليق طويل جداً.';
  static const String selectCityFirst = 'اختر المدينة أولاً.';
  static const String pickAtLeastOneImage = 'أضف صورة واحدة على الأقل للعقار.';
  static const String tooManyImages = 'الحد الأقصى 12 صورة للعقار الواحد.';

  // Share text builder
  static String sharePropertyText({
    required String title,
    required String priceText,
    required String location,
    required String playStoreUrl,
  }) {
    return '$title\n$priceText\n$location\n\nحمّل تطبيق $appName:\n$playStoreUrl';
  }

  static String whatsappPropertyInquiry(String title) =>
      'السلام عليكم، أستفسر عن العقار: $title';
}
