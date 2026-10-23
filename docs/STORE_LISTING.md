> **What this file is:** Every answer the app stores ask for (listing text in both languages, privacy answers, age rating, review notes), written once from what the app actually does, so each release copies the same facts instead of re-deriving them.
> **How to use it:** Paste from here into App Store Connect (and, later, the Play Console). When the app changes in a way a listing states (a new level, a new data flow, a new sign-in method), change this file in the same change, together with `assets/legal/` if what leaves the device changed.

_Last verified: 2026-09-24 (`release/v1.0.0`) — written for the first App Store submission of 1.0.0 (iPhone only, `com.northstorm.mohingo`). The Google Play section is not written yet._

# Store listing

## App Store

### Create the app (App Store Connect → Apps → **+** → New App)

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `Mohingo: Learn English` (the name must be unused on the App Store; if it is taken, try `Mohingo English`) |
| Primary language | English (U.S.) |
| Bundle ID | `com.northstorm.mohingo` |
| SKU | `mohingo-ios` (private; any unique text) |
| User access | Full access |

Then add **Arabic** as a second language (the language menu at the top right of the app's page), and fill in each language below.

### Text, per language

Limits: name and subtitle 30 characters, promotional text 170, keywords 100, description 4,000. Everything below fits. Keep "Mohingo", "A1", "A2" and "CEFR" in Latin script in both languages.

#### English (U.S.)

**Name:** Mohingo: Learn English

**Subtitle:** English for Arabic speakers

**Promotional text:** Two complete levels, A1 and A2, with lessons for reading, listening, speaking and writing — explained in Arabic, working offline, free and without ads.

**Keywords:** `learn english,arabic,grammar,vocabulary,speaking,listening,reading,writing,cefr,beginner,lessons`

**Description:**

```
Mohingo is an English course for Arabic speakers who are learning on their own. It follows the CEFR levels step by step, so you always know what to learn next and why.

TWO COMPLETE LEVELS
• A1 and A2: 25 units and 173 guided lessons, from greetings and numbers to travel, health, work and study.
• Every lesson opens with a short conversation, with Arabic under every line.
• Grammar explained in Arabic, with notes on where English works differently from Arabic.

ALL FOUR SKILLS
• Reading and listening, with clear audio for every line, built into the app.
• Speaking: answer out loud and have your answer checked.
• Writing: short tasks, checked as you go.

START IN THE RIGHT PLACE
• A short placement test finds the unit where you should begin, or you can start from the very first lesson.

KEEP WHAT YOU LEARN
• Save words and phrases, and review them when they are due.
• A final mission and a final assessment for each level, with a result for each skill.

LEARN ANYWHERE
• Works without an internet connection; all the audio is included.
• An account is optional. Create one to keep your progress on more than one device.
• Interface in Arabic or English, in light or dark mode.

NO ADS, NO TRACKING
Mohingo is free. It has no ads, no analytics and no tracking.
```

#### Arabic

**Name:** Mohingo: تعلّم الإنجليزية

**Subtitle:** الإنجليزية للناطقين بالعربية

**Promotional text:** مستويان كاملان، A1 وA2، بدروس للقراءة والاستماع والتحدث والكتابة، مع شرح بالعربية. يعمل دون إنترنت، مجاني وبلا إعلانات.

**Keywords:** `تعلم الانجليزية,انجليزي,قواعد,مفردات,محادثة,استماع,قراءة,كتابة,مبتدئ,دروس,لغة انجليزية`

**Description:**

```
Mohingo دورة لتعلّم الإنجليزية مصمّمة للمتحدثين بالعربية الذين يتعلّمون بأنفسهم. تسير بك خطوة بخطوة وفق مستويات الإطار الأوروبي المرجعي (CEFR)، فتعرف دائماً ماذا تتعلّم بعد ذلك ولماذا.

مستويان كاملان
• المستويان A1 وA2: ‏25 وحدة و173 درساً موجّهاً، من التحية والأرقام إلى السفر والصحة والعمل والدراسة.
• يبدأ كل درس بمحادثة قصيرة، مع العربية تحت كل سطر.
• شرح القواعد بالعربية، مع ملاحظات توضّح أين تختلف الإنجليزية عن العربية.

المهارات الأربع
• القراءة والاستماع، مع صوت واضح لكل سطر مدمج في التطبيق.
• التحدث: أجب بصوتك، ويقيّم التطبيق إجابتك.
• الكتابة: مهام قصيرة تُقيَّم أثناء التعلّم.

ابدأ من المكان المناسب
• اختبار قصير لتحديد المستوى يدلّك على الوحدة التي تبدأ منها، أو ابدأ من الدرس الأول.

ثبّت ما تتعلّمه
• احفظ الكلمات والعبارات، وراجعها في موعدها.
• مهمة ختامية وتقييم نهائي لكل مستوى، بنتيجة لكل مهارة.

تعلّم في أي مكان
• يعمل دون اتصال بالإنترنت، وكل الأصوات مضمّنة في التطبيق.
• الحساب اختياري؛ أنشئه لتحتفظ بتقدّمك على أكثر من جهاز.
• واجهة بالعربية أو الإنجليزية، بالوضع الفاتح أو الداكن.

بلا إعلانات وبلا تتبّع
Mohingo مجاني، بلا إعلانات ولا أدوات تحليل ولا تتبّع.
```

#### URLs (both languages)

| Field | Value |
|---|---|
| Support URL | `https://mohingo.web.app/` |
| Marketing URL | leave empty |
| Privacy Policy URL | `https://mohingo.web.app/privacy` (English) · `https://mohingo.web.app/ar/privacy` (Arabic) |

### Screenshots

The app is iPhone only, so only the **6.9-inch iPhone** set is required (1320 × 2868 or 1290 × 2796, portrait); App Store Connect scales it for smaller iPhones. An iPhone 17 Pro Max takes screenshots at exactly 1320 × 2868 (side button + volume up). Upload 5-6 per language, in this order:

1. Home, with a unit in progress.
2. A lesson's opening conversation, showing the Arabic under each line.
3. A speaking task.
4. A grammar explanation.
5. The placement test.
6. Vocabulary or Review.

Take the English set with the app's interface in English and the Arabic set with it in Arabic (Settings → App language).

### App information

| Field | Value |
|---|---|
| Category | Education (secondary: none) |
| Content rights | Does not contain, show or access third-party content |
| Age rating | Answer **None** or **No** to every question: no violence, sexual content, profanity, drugs, gambling, horror or medical content; no unrestricted web access, user-generated content, messaging, advertising or in-app purchases. Expected result: 4+ |
| Copyright | `2026` followed by your name as enrolled in the Apple Developer Program |

### App Privacy ("Get started" under App Privacy)

Matches `assets/legal/privacy_en.md`. Tracking: **No**, the app does not track. Data collected: **Yes**:

| Data type | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|
| Contact Info → Email Address | Yes | No | App Functionality |
| Contact Info → Name (the name entered in Settings) | Yes | No | App Functionality |
| Identifiers → User ID (the account's Firebase id) | Yes | No | App Functionality |
| User Content → Other User Content (answers, including typed answers sent to the grammar check) | Yes | No | App Functionality |
| Usage Data → Product Interaction (lessons, scores, review schedule) | Yes | No | App Functionality |

Not collected: audio (the phone's own speech recognition turns speech into text; Mohingo never sends or keeps recordings), location, contacts, photos, health, financial data, browsing history, diagnostics.

### App Review information

- **Sign-in required:** No. Every learning feature works without an account.
- **Contact:** your name, phone and email (Apple uses them only to reach you).
- **Notes:**

```
Mohingo is an English course for Arabic speakers. No account or login is needed: every lesson, exercise and test works without signing in, and fully offline.

WHERE THINGS ARE
- First launch: tap "Accept and continue" on the privacy screen. A short guide then points out the tabs; "Skip" closes it.
- Learn tab: units and lessons. Speaking, listening, reading and writing tasks are inside the lessons.
- Tests tab: the placement test, and each level's final mission and final assessment.
- Settings > App language: switches the interface between English and Arabic.

ACCOUNTS (OPTIONAL)
Accounts only copy progress between devices. Settings > Account & sync > Sign in offers Sign in with Apple, Google, and email and password; a new account can be created there with any email address. Once signed in, Settings > Account & sync > Delete account deletes the account and its data, after the user confirms with Apple, Google or their password.

PERMISSIONS
The microphone and speech recognition are requested only when the user taps to answer a speaking task aloud. Every answer can be typed instead.
```

### Version release, pricing, export compliance

- **Price:** Free (Pricing and Availability → All countries or regions).
- **Release:** "Manually release this version", so it goes live only when you choose.
- **Export compliance:** already answered by the build (`ITSAppUsesNonExemptEncryption` = NO in `Info.plist`: the app uses only standard HTTPS).
- **EU Digital Services Act:** App Store Connect asks once, under Business, whether you are a trader. A trader's address, phone and email are shown on the EU store page.

## Google Play

Not written yet. Most of it carries over: the same text within Play's limits (title 30, short description 80, full description 4,000), the Data safety form from the App Privacy table above, and `https://mohingo.web.app/delete-account` as the account deletion URL.
