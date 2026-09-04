# منهاج الإنجليزية A1 الكامل — حزمة معيارية جاهزة للدمج

هذه الحزمة هي مصدر محتوى كامل للمستوى A1 من `U0` إلى `U12`، مع مهمة ختامية واختبار خروج مستقل. بُنيت لتمنع تضخم ملف التأليف: كل وحدة وقواعدها ومفرداتها وعباراتها ووسائطها في ملفات منفصلة، بينما يُنشأ ملف واحد مجمّع آلياً عند التشغيل.

## ما تحتويه الحزمة

| المسار | الوظيفة |
|---|---|
| `manifest.json` | فهرس الملفات والسياسات وتوقعات الجودة |
| `course.json` | بيانات المستوى وحالة الاكتمال |
| `domain.json` | المهارات والأنماط وأنواع الأنشطة وCan‑Do IDs |
| `units/A1-U0.json` … `A1-U12.json` | الدروس والأنشطة ومهام الوحدات |
| `registries/grammar/` | قاعدة واحدة لكل بنية نحوية، مع أمثلة ثنائية اللغة |
| `registries/lexicon/` | lexical senses مع receptive/productive والتدوير |
| `registries/chunks/` | العبارات الوظيفية الجاهزة |
| `media/` | مواصفات المشاهد ومصادر TTS والنصوص الصوتية |
| `final/A1-FINAL-MISSION.json` | مهمة عملية متكاملة من ست مراحل |
| `assessment/A1-FINAL-ASSESSMENT.json` | اختبار خروج بمواد غير معادة من التدريب |
| `dist/a1-course-bundle.json` | ملف JSON واحد جاهز للبرنامج، مولّد آلياً |
| `quality/a1-quality-report.json` | تقرير التغطية والتسلسل والاستقلالية |

## خريطة الوحدات

| الوحدة | الموضوع |
|---|---|
| U0 | English Essentials |
| U1 | Hello, I’m… |
| U2 | People in My Life |
| U3 | My Home and My Things |
| U4 | My Day |
| U5 | Likes and Free Time |
| U6 | Food and Drink |
| U7 | Shopping |
| U8 | Around Town |
| U9 | Getting Around |
| U10 | Health and Help |
| U11 | Weather and Clothes |
| U12 | Plans and Messages |

## التشغيل المباشر

إذا كان البرنامج يريد ملفاً واحداً فقط، انسخ:

```text
dist/a1-course-bundle.json
```

مثال JavaScript:

```js
const response = await fetch('/content/a1-course-bundle.json');
const a1Course = await response.json();

console.log(a1Course.units);
console.log(a1Course.finalMission);
console.log(a1Course.finalAssessment);
```

## إعادة البناء والتحقق

لا توجد تبعيات خارجية؛ الأدوات تعمل بـNode.js مباشرة:

```bash
node tools/validate-a1.mjs
node tools/audit-quality.mjs
node tools/build-a1.mjs
```

ولإعادة توليد U4–U12 والملفات الختامية من مصدر التأليف:

```bash
node tools/author-complete-a1.mjs
```

بعد أي تعديل شغّل، بالترتيب: `validate-a1.mjs` ثم `audit-quality.mjs` ثم `build-a1.mjs`.

## قواعد تمنع فقدان الجودة

- عدّل ملفات الوحدات والسجلات المعيارية؛ لا تعدّل `dist/a1-course-bundle.json` يدوياً.
- لا تغيّر ID منشوراً. أضف ID جديداً عند إضافة sense أو بنية مختلفة.
- لا تنسخ سجلاً من وحدة سابقة؛ أشر إلى ID نفسه لإعادة التدوير.
- كل نشاط يجب أن يحمل `skill` و`mode` و`canDo`.
- `practice` لا يعد دليلاً على الإتقان؛ دليل الإتقان يحمل `mode: "mastery"`.
- كل وحدة أساسية تنتهي بمهمة تشمل الاستقبال والإنتاج والوساطة.
- الاختبار النهائي لا يعيد نصوص التدريب أو خياراتها حرفياً.
- التسجيل الصوتي له بديل كتابي للإتاحة، لكن البديل لا يُسجل كدليل Speaking.
- البيانات الشخصية والصحية في المهمات افتراضية افتراضياً.

## الأرقام الحالية

- 13 وحدة و89 درساً.
- 445 نشاطاً داخل الدروس.
- 12 نشاطاً في المهمة الختامية.
- 40 مهمة في اختبار الخروج: 16 Listening، و16 Reading، ومهمتا Writing، و4 Speaking، ومهمتا Mediation.
- 85 سجلاً نحوياً، و354 lexical senses، و143 chunk.
- 158 مواصفة media/TTS.

التقرير الآلي في `quality/a1-quality-report.json` هو المرجع النهائي لأرقام النسخة الحالية وحالة الفحص.
