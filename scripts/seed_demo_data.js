#!/usr/bin/env node
/**
 * Seeds realistic Yemeni demo content into Cloud Firestore.
 *
 * Usage:
 *   1. cd scripts && npm install
 *   2. Download a service-account key from Firebase Console
 *      (Project settings > Service accounts > Generate new private key)
 *   3. GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo_data.js
 *
 * The script is idempotent for catalogs (fixed doc ids) and skips properties
 * when the collection is already populated (pass --force to reseed anyway).
 */

const admin = require('firebase-admin');

const FORCE = process.argv.includes('--force');

admin.initializeApp({
  credential: admin.applicationDefault(),
});

const db = admin.firestore();
const now = admin.firestore.FieldValue.serverTimestamp();

// ---------------------------------------------------------------- catalogs

const TYPES = [
  ['type-apartment', 'شقة', 'apartment'],
  ['type-house', 'منزل', 'home'],
  ['type-villa', 'فيلا', 'villa'],
  ['type-land', 'أرض', 'landscape'],
  ['type-shop', 'محل تجاري', 'store'],
  ['type-office', 'مكتب', 'business'],
  ['type-building', 'عمارة', 'domain'],
  ['type-other', 'عقار آخر', 'real_estate_agent'],
];

const CITIES = [
  'صنعاء',
  'عدن',
  'تعز',
  'الحديدة',
  'إب',
  'المكلا',
  'ذمار',
  'مأرب',
];

const AREAS = {
  'city-0': ['حدة', 'بيت بوس', 'شملان', 'السبعين', 'مذبح'],
  'city-1': ['المنصورة', 'الشيخ عثمان', 'كريتر', 'خور مكسر', 'المعلا'],
  'city-2': ['المسبح', 'وادي القاضي', 'الحوبان', 'الروضة'],
  'city-3': ['الكورنيش', 'الحوك', 'الميناء', 'غليل'],
  'city-4': ['الظهار', 'المشنة', 'السبل'],
  'city-5': ['الديس', 'الشرج', 'فوة'],
  'city-6': ['عنس', 'الحدا', 'المدينة'],
  'city-7': ['الروضة', 'المطار', 'السوق'],
};

const FEATURES = [
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

// ------------------------------------------------------------- properties

const img = (seed) => `https://picsum.photos/seed/${seed}/900/600`;
const gallery = (seeds) =>
  seeds.map((s, i) => ({
    url: img(s),
    path: `seed/${s}`,
    isMain: i === 0,
    order: i,
  }));

function keywords(...parts) {
  const norm = (s) =>
    s
      .toLowerCase()
      .replace(/[ً-ٰٟ]/g, '')
      .replace(/ـ/g, '')
      .replace(/[أإآٱ]/g, 'ا')
      .replace(/ة/g, 'ه')
      .replace(/ى/g, 'ي');
  const tokens = new Set();
  for (const part of parts) {
    for (const word of norm(part).split(/\s+/)) {
      if (word.length < 2) continue;
      tokens.add(word);
      for (let i = 2; i < word.length; i++) tokens.add(word.slice(0, i));
      if (tokens.size > 60) break;
    }
  }
  return [...tokens].slice(0, 60);
}

const PROPERTIES = [
  {
    title: 'شقة فاخرة للإيجار في حدة',
    description:
      'شقة فاخرة بتشطيبات حديثة في حي حدة الراقي، قريبة من جميع الخدمات والمدارس والأسواق.',
    purpose: 'rent',
    typeId: 'type-apartment',
    typeName: 'شقة',
    cityId: 'city-0',
    cityName: 'صنعاء',
    areaName: 'حدة',
    address: 'شارع حدة الرئيسي',
    price: 300000,
    currency: 'YER',
    size: 180,
    bedrooms: 4,
    bathrooms: 3,
    floor: 3,
    status: 'available',
    isPublished: true,
    isFeatured: true,
    seeds: ['sanaa-apt-1', 'sanaa-apt-2', 'sanaa-apt-3'],
    featureNames: ['ماء', 'كهرباء', 'موقف سيارات', 'مطبخ', 'تكييف', 'مصعد'],
  },
  {
    title: 'أرض سكنية للبيع في بيت بوس',
    description: 'أرض سكنية مميزة على شارعين، صك شرعي جاهز، مناسبة لبناء عمارة أو فيلا.',
    purpose: 'sale',
    typeId: 'type-land',
    typeName: 'أرض',
    cityId: 'city-0',
    cityName: 'صنعاء',
    areaName: 'بيت بوس',
    address: 'بيت بوس، شارع 30',
    price: 45000000,
    currency: 'YER',
    size: 600,
    bedrooms: 0,
    bathrooms: 0,
    status: 'available',
    isPublished: true,
    isFeatured: false,
    seeds: ['sanaa-land-1', 'sanaa-land-2'],
    featureNames: ['شارع رئيسي'],
  },
  {
    title: 'فيلا راقية للبيع في المنصورة',
    description: 'فيلا دورين مع حوش واسع، تشطيب فاخر، مجلس خارجي، موقع مميز في المنصورة بعدن.',
    purpose: 'sale',
    typeId: 'type-villa',
    typeName: 'فيلا',
    cityId: 'city-1',
    cityName: 'عدن',
    areaName: 'المنصورة',
    address: 'المنصورة، بلوك 12',
    price: 120000,
    currency: 'USD',
    size: 350,
    bedrooms: 5,
    bathrooms: 4,
    status: 'available',
    isPublished: true,
    isFeatured: true,
    seeds: ['aden-villa-1', 'aden-villa-2', 'aden-villa-3'],
    featureNames: ['ماء', 'كهرباء', 'موقف سيارات', 'مطبخ', 'تكييف', 'حوش'],
  },
  {
    title: 'شقة للإيجار في الشيخ عثمان',
    description: 'شقة نظيفة ومشمسة، دور ثاني، قريبة من السوق والمواصلات.',
    purpose: 'rent',
    typeId: 'type-apartment',
    typeName: 'شقة',
    cityId: 'city-1',
    cityName: 'عدن',
    areaName: 'الشيخ عثمان',
    address: 'الشيخ عثمان',
    price: 180000,
    currency: 'YER',
    size: 120,
    bedrooms: 3,
    bathrooms: 2,
    floor: 2,
    status: 'available',
    isPublished: true,
    isFeatured: false,
    seeds: ['aden-apt-1', 'aden-apt-2'],
    featureNames: ['ماء', 'كهرباء', 'مطبخ'],
  },
  {
    title: 'عمارة استثمارية للبيع في الحديدة',
    description: 'عمارة 4 أدوار، 8 شقق مؤجرة بالكامل بعوائد ممتازة، موقع استثماري على الكورنيش.',
    purpose: 'sale',
    typeId: 'type-building',
    typeName: 'عمارة',
    cityId: 'city-3',
    cityName: 'الحديدة',
    areaName: 'الكورنيش',
    address: 'الكورنيش',
    price: 250000,
    currency: 'USD',
    size: 800,
    bedrooms: 16,
    bathrooms: 8,
    status: 'available',
    isPublished: true,
    isFeatured: true,
    seeds: ['hodeidah-bld-1', 'hodeidah-bld-2'],
    featureNames: ['ماء', 'كهرباء', 'موقف سيارات', 'مصعد'],
  },
];

const SETTINGS = {
  phone: '967771234567',
  whatsapp: '967771234567',
  email: 'info@alethiopi-realestate.com',
  address: 'صنعاء، شارع حدة',
  facebookUrl: 'https://facebook.com/alethiopi.realestate',
  aboutAr:
    'الأثيوبي للعقارات منصة يمنية متخصصة في عرض الشقق والأراضي والعقارات للبيع والإيجار.',
  termsAr:
    'باستخدامك للتطبيق فأنت توافق على احترام حقوق الآخرين وعدم نشر محتوى مسيء أو مضلل.',
  privacyAr:
    'نجمع الحد الأدنى من البيانات اللازمة لتشغيل التطبيق ولا نبيع بياناتك لأي طرف ثالث.',
};

// ------------------------------------------------------------------ runner

async function seedCatalogs(batch) {
  TYPES.forEach(([id, name, icon], i) => {
    batch.set(
      db.collection('property_types').doc(id),
      { name, icon, order: i, isActive: true },
      { merge: true },
    );
  });
  CITIES.forEach((name, i) => {
    batch.set(
      db.collection('cities').doc(`city-${i}`),
      { name, order: i, isActive: true },
      { merge: true },
    );
  });
  let order = 0;
  for (const [cityId, names] of Object.entries(AREAS)) {
    for (const name of names) {
      batch.set(
        db.collection('areas').doc(`area-${order}`),
        { name, cityId, order: order++, isActive: true },
        { merge: true },
      );
    }
  }
  FEATURES.forEach((name, i) => {
    batch.set(
      db.collection('features').doc(`feat-${i}`),
      { name, icon: 'check_circle', order: i, isActive: true },
      { merge: true },
    );
  });
  batch.set(db.collection('settings').doc('app'), SETTINGS, { merge: true });
}

async function main() {
  console.log('Seeding catalogs + settings...');
  const batch = db.batch();
  await seedCatalogs(batch);
  await batch.commit();
  console.log('Catalogs done.');

  const existing = await db.collection('properties').limit(1).get();
  if (!existing.empty && !FORCE) {
    console.log(
      `properties collection already has documents — skipping property seed (use --force to reseed).`,
    );
    return;
  }

  // Resolve area ids + feature ids for denormalized fields.
  const areaSnap = await db.collection('areas').get();
  const areaIdByName = {};
  areaSnap.forEach((d) => {
    areaIdByName[`${d.data().cityId}|${d.data().name}`] = d.id;
  });
  const featSnap = await db.collection('features').get();
  const featIdByName = {};
  featSnap.forEach((d) => {
    featIdByName[d.data().name] = d.id;
  });

  console.log('Seeding properties...');
  for (const p of PROPERTIES) {
    const areaId = areaIdByName[`${p.cityId}|${p.areaName}`] || '';
    const doc = {
      ...p,
      areaId,
      seeds: undefined,
      images: gallery(p.seeds),
      featureIds: p.featureNames.map((n) => featIdByName[n]).filter(Boolean),
      phone: '967771234567',
      whatsapp: '967771234567',
      ratingAvg: 0,
      ratingCount: 0,
      favoritesCount: 0,
      commentsCount: 0,
      createdAt: now,
      updatedAt: now,
      searchKeywords: keywords(
        p.title,
        p.cityName,
        p.areaName,
        p.typeName,
        p.address,
        p.purpose === 'sale' ? 'للبيع' : 'للإيجار',
      ),
    };
    delete doc.seeds;
    const ref = await db.collection('properties').add(doc);
    console.log(`  + ${p.title} (${ref.id})`);
  }
  console.log('Done. Seed complete.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
