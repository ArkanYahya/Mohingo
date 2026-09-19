import {buildUnit,I,P,O,R,Prod} from "./helpers.mjs";

const evals={
  speak:["taskCompletion","intelligibility","appropriateLanguage","accuracy"],
  write:["taskCompletion","clarity","organisation","appropriateLanguage","accuracy"],
  mediate:["selectRelevantInformation","clarity","audienceAwareness","accuracy"]
};

const U1=buildUnit({
  id:"A2-U1",title:"Life Now",titleAr:"حياتي الآن",recycleFrom:["A1-U1","A1-U4","A1-U5"],unlocks:"A2-U2",
  objectives:{listen:"LISTENING.UNDERSTAND_LIFE_UPDATE",read:"READING.UNDERSTAND_PROFILE",produce:"PRODUCTION.DESCRIBE_CURRENT_LIFE",interact:"INTERACTION.ASK_FOLLOW_UP",write:"WRITING.WRITE_LIFE_UPDATE",mediate:"MEDIATION.RELAY_LIFE_UPDATE",mission:"ACTION.COMPLETE_LIFE_UPDATE"},
  grammar:[
    ["PRESENT_SIMPLE_REVIEW","present simple for routines","المضارع البسيط للروتين",1,"I usually walk to work.","أمشي عادةً إلى العمل."],
    ["PRESENT_CONTINUOUS_NOW","be + verb-ing for now","المضارع المستمر لما يحدث الآن",2,"I am staying with my aunt this week.","أقيم مع عمتي هذا الأسبوع."],
    ["PRESENT_SIMPLE_VS_CONTINUOUS","routine vs temporary action","الفرق بين المعتاد والمؤقت",2,"I work in Basra, but I am working from home today.","أعمل في البصرة، لكنني أعمل من المنزل اليوم."],
    ["WH_FOLLOW_UP","Wh- follow-up questions","أسئلة المتابعة بأدوات الاستفهام",3,"What do you do after work?","ماذا تفعل بعد العمل؟"],
    ["QUESTION_AUXILIARY_REVIEW","do/does and be in questions","مراجعة أدوات السؤال",4,"Are you enjoying the course?","هل تستمتع بالدورة؟"],
    ["LINKERS_AND_BUT_BECAUSE","and, but, because","الربط بـ and وbut وbecause",6,"I like my job because it is useful.","أحب عملي لأنه مفيد."]
  ],
  lexicon:[
    ["ROUTINE_N01","routine","noun","روتين",1,"My morning routine is simple.","روتيني الصباحي بسيط."],
    ["NORMALLY_ADV01","normally","adverb","عادةً",1,"I normally start at eight.","أبدأ عادةً في الثامنة."],
    ["WEEKDAY_N01","weekday","noun","يوم عمل",1,"I study on weekdays.","أدرس في أيام العمل."],
    ["TEMPORARY_ADJ01","temporary","adjective","مؤقت",2,"This is a temporary job.","هذه وظيفة مؤقتة."],
    ["CURRENTLY_ADV01","currently","adverb","حالياً",2,"I am currently living in Amman.","أعيش حالياً في عمّان."],
    ["STAY_V01","stay","verb","يقيم",2,"We are staying near the centre.","نقيم قرب المركز."],
    ["FOLLOW_UP_N01","follow-up","noun","متابعة",3,"Ask one follow-up question.","اسأل سؤال متابعة واحداً."],
    ["DETAIL_N01","detail","noun","تفصيل",3,"Tell me one more detail.","أخبرني بتفصيل آخر."],
    ["RECENTLY_ADV01","recently","adverb","مؤخراً",3,"What are you doing recently?","ماذا تفعل مؤخراً؟"],
    ["INTERESTED_ADJ01","interested","adjective","مهتم",4,"I am interested in languages.","أنا مهتم باللغات."],
    ["BUSY_ADJ01","busy","adjective","مشغول",4,"She is busy this month.","هي مشغولة هذا الشهر."],
    ["ENJOY_V01","enjoy","verb","يستمتع",4,"I enjoy meeting people.","أستمتع بلقاء الناس."],
    ["PROFILE_N01","profile","noun","ملف شخصي",5,"Read the student profile.","اقرأ الملف الشخصي للطالب."],
    ["BACKGROUND_N01","background","noun","خلفية",5,"His background is in design.","خلفيته في التصميم."],
    ["SIMILAR_ADJ01","similar","adjective","مشابه",5,"Our routines are similar.","روتينانا متشابهان."],
    ["UPDATE_N01","update","noun","تحديث",6,"Send me a short update.","أرسل لي تحديثاً قصيراً."],
    ["CHANGE_N01","change","noun","تغيير",6,"There is one big change.","يوجد تغيير كبير واحد."],
    ["SITUATION_N01","situation","noun","وضع",6,"Describe your current situation.","صف وضعك الحالي."]
  ],
  chunks:[
    ["ON_WEEKDAYS","on weekdays","في أيام العمل",1],
    ["AT_THE_MOMENT","at the moment","في الوقت الحالي",2],
    ["THIS_WEEK","this week","هذا الأسبوع",2],
    ["WHAT_ABOUT_YOU","What about you?","ماذا عنك؟",3],
    ["TELL_ME_MORE","Tell me more.","أخبرني بالمزيد.",3],
    ["THAT_SOUNDS_INTERESTING","That sounds interesting.","يبدو ذلك ممتعاً.",4],
    ["HAVE_IN_COMMON","have ... in common","لديهما ... مشترك",5],
    ["RIGHT_NOW","right now","الآن",6]
  ],
  lessons:[
    {title:"A Regular Week",titleAr:"أسبوع معتاد",canDo:["listen","produce"],grammar:["PRESENT_SIMPLE_REVIEW"],lex:["ROUTINE_N01","NORMALLY_ADV01","WEEKDAY_N01"],chunks:["ON_WEEKDAYS"],
      input:I("I normally get up at seven on weekdays. I take the bus to work and play football on Thursday.","أستيقظ عادةً في السابعة في أيام العمل. أستقل الحافلة إلى العمل وألعب كرة القدم يوم الخميس.","How does the speaker travel to work?","كيف يذهب المتحدث إلى العمل؟",["By bus","By car","On foot"],"By bus"),
      practice:P("Mina ___ studies after dinner.",["normally","now","temporary"],"normally"),
      mastery:I("Karim works in a shop from Sunday to Thursday. On Friday, he visits his parents.","يعمل كريم في متجر من الأحد إلى الخميس. يوم الجمعة يزور والديه.","What does Karim do on Friday?","ماذا يفعل كريم يوم الجمعة؟",["He visits his parents.","He works in the shop.","He studies."],"He visits his parents."),
      production:Prod("spokenProduction","Describe three things in your usual week.","صف ثلاثة أشياء في أسبوعك المعتاد.",evals.speak)},
    {title:"A Temporary Change",titleAr:"تغيير مؤقت",canDo:["listen","produce"],grammar:["PRESENT_CONTINUOUS_NOW","PRESENT_SIMPLE_VS_CONTINUOUS"],lex:["TEMPORARY_ADJ01","CURRENTLY_ADV01","STAY_V01"],chunks:["AT_THE_MOMENT","THIS_WEEK"],
      input:I("I usually live in Mosul, but this month I am staying with my brother in Erbil. I am taking an evening course there.","أعيش عادةً في الموصل، لكنني أقيم هذا الشهر مع أخي في أربيل. أحضر دورة مسائية هناك.","Where is the speaker staying this month?","أين يقيم المتحدث هذا الشهر؟",["In Erbil","In Mosul","In Baghdad"],"In Erbil"),
      practice:P("I work at the office, but today I ___ from home.",["am working","work","worked"],"am working"),
      mastery:I("Lina normally teaches children. This week, she is helping at a sports camp.","تدرّس لينا الأطفال عادةً. هذا الأسبوع تساعد في مخيم رياضي.","What is temporary?","ما الأمر المؤقت؟",["Helping at a sports camp","Teaching children","Living with children"],"Helping at a sports camp"),
      production:Prod("spokenProduction","Say one usual fact and one temporary fact about your life now.","اذكر حقيقة معتادة وحقيقة مؤقتة عن حياتك الآن.",evals.speak)},
    {title:"Ask a Better Question",titleAr:"اسأل سؤالاً أفضل",canDo:["read","interact"],grammar:["WH_FOLLOW_UP"],lex:["FOLLOW_UP_N01","DETAIL_N01","RECENTLY_ADV01"],chunks:["WHAT_ABOUT_YOU","TELL_ME_MORE"],inputSkill:"reading",masterySkill:"reading",
      input:R("Nora: I am learning to drive. Sami: Really? When do you practise? Nora: On Saturday mornings.","When does Nora practise driving?","متى تتدرب نورا على القيادة؟",["On Saturday mornings","Every evening","On Monday"],"On Saturday mornings"),
      practice:O(["do","What","after work?","you","do"],["What","do","you","do","after work?"]),
      mastery:R("Adel: I have a new job. Rana: Where do you work? Adel: At the city hospital.","Which question asks for more detail?","أي سؤال يطلب تفصيلاً إضافياً؟",["Where do you work?","Do you work?","Is it a job?"],"Where do you work?"),
      production:Prod("spokenInteraction","A partner says, ‘I am taking a new course.’ Ask two relevant follow-up questions.","يقول شريك: «أحضر دورة جديدة». اسأل سؤالَي متابعة مناسبين.",evals.speak)},
    {title:"Show Interest",titleAr:"أظهر الاهتمام",canDo:["listen","interact"],grammar:["QUESTION_AUXILIARY_REVIEW"],lex:["INTERESTED_ADJ01","BUSY_ADJ01","ENJOY_V01"],chunks:["THAT_SOUNDS_INTERESTING","TELL_ME_MORE"],
      input:I("A: I am working on a new project. B: That sounds interesting. Are you enjoying it? A: Yes, very much.","أ: أعمل على مشروع جديد. ب: يبدو ذلك ممتعاً. هل تستمتع به؟ أ: نعم، كثيراً.","What does B do?","ماذا يفعل ب؟",["Shows interest and asks a question","Changes the subject","Ends the conversation"],"Shows interest and asks a question"),
      practice:P("___ you enjoying your new class?",["Are","Do","Is"],"Are"),
      mastery:I("A: My sister is opening a café. B: Really? Tell me more. Where is it?", "أ: ستفتح أختي مقهى. ب: حقاً؟ أخبرني بالمزيد. أين هو؟","Which phrase shows interest?","أي عبارة تظهر الاهتمام؟",["Tell me more.","Where is it?","My sister"],"Tell me more."),
      production:Prod("spokenInteraction","Respond with interest and ask a follow-up question about a new hobby.","استجب باهتمام واسأل سؤال متابعة عن هواية جديدة.",evals.speak)},
    {title:"Compare Two Profiles",titleAr:"قارن ملفين شخصيين",canDo:["read","mediate"],grammar:["PRESENT_SIMPLE_VS_CONTINUOUS"],lex:["PROFILE_N01","BACKGROUND_N01","SIMILAR_ADJ01"],chunks:["HAVE_IN_COMMON"],inputSkill:"reading",masterySkill:"reading",
      input:R("Maha is a nurse and works nights. Tia is studying nursing and is currently working at a bookshop. Both enjoy running.","What do Maha and Tia have in common?","ما الشيء المشترك بين مها وتيا؟",["They enjoy running.","They both work nights.","They both work at a bookshop."],"They enjoy running."),
      practice:P("They both like music, so they have that ___ common.",["in","at","on"],"in"),
      mastery:R("Omar usually lives in Cairo and works in IT. Ben lives in London and is visiting Cairo for a month. Both are learning Arabic.","Which fact is true?","أي حقيقة صحيحة؟",["Both are learning Arabic.","Both live in Cairo permanently.","Both work in IT."],"Both are learning Arabic."),
      production:Prod("mediation","Read two short profiles provided by the app and relay one similarity and one difference in simple language.","اقرأ ملفين قصيرين يعرضهما التطبيق وانقل تشابهاً واحداً واختلافاً واحداً بلغة بسيطة.",evals.mediate)},
    {title:"My Life Update",titleAr:"تحديث عن حياتي",canDo:["write","produce"],grammar:["LINKERS_AND_BUT_BECAUSE"],lex:["UPDATE_N01","CHANGE_N01","SITUATION_N01"],chunks:["RIGHT_NOW","AT_THE_MOMENT"],inputSkill:"reading",masterySkill:"reading",
      input:R("Hi Salma, I still work at the bank, but I am taking a design course at the moment because I want a change. I am busy, but happy.","Why is the writer taking a design course?","لماذا يحضر الكاتب دورة تصميم؟",["Because the writer wants a change.","Because the bank is closed.","Because Salma is a designer."],"Because the writer wants a change."),
      practice:P("I like the course ___ it is practical.",["because","but","and"],"because"),
      mastery:R("I usually study in the morning, but this week I am studying at night because I have a temporary job.","What has changed this week?","ما الذي تغير هذا الأسبوع؟",["The study time","The usual city","The course subject"],"The study time"),
      production:Prod("writing","Write a life update with two usual facts, one current change and a reason.","اكتب تحديثاً عن حياتك يتضمن حقيقتين معتادتين وتغييراً حالياً وسبباً.",evals.write,[60,90])}
  ],
  mission:{title:"A Two-Minute Life Update",titleAr:"تحديث عن الحياة في دقيقتين",scenario:"You meet a former classmate online. Exchange updates, ask follow-up questions and relay one useful detail to another friend.",
    reading:R("Yara works in a hotel, but this month she is training at a new branch. She enjoys it because she is meeting visitors from many countries.","Why does Yara enjoy the training?","لماذا تستمتع يارا بالتدريب؟",["She meets international visitors.","She works fewer days.","The branch is near home."],"She meets international visitors."),
    audio:I("I normally study engineering, but I am working in my uncle's shop during the holiday.","أدرس الهندسة عادةً، لكنني أعمل في متجر عمي خلال العطلة.","What is the speaker doing temporarily?","ماذا يفعل المتحدث مؤقتاً؟",["Working in a shop","Studying engineering","Visiting a school"],"Working in a shop"),
    interaction:{prompt:"Exchange current-life updates and ask at least two connected follow-up questions.",promptAr:"تبادل تحديثات الحياة الحالية واسأل سؤالَي متابعة مترابطين على الأقل.",evaluation:evals.speak},
    production:{prompt:"Give a one-to-two-minute update about your routine and one current change.",promptAr:"قدّم تحديثاً من دقيقة إلى دقيقتين عن روتينك وتغيير حالي واحد.",evaluation:evals.speak},
    mediation:{prompt:"Relay the classmate's routine, current change and reason to a third person.",promptAr:"انقل إلى شخص ثالث روتين زميلك وتغييره الحالي وسببه.",evaluation:evals.mediate},
    writing:{prompt:"Write a connected update to an old classmate using and, but and because.",promptAr:"اكتب تحديثاً مترابطاً إلى زميل قديم مستخدماً and وbut وbecause.",evaluation:evals.write,wordGuide:[80,110]}}
});

const U2=buildUnit({
  id:"A2-U2",title:"Past Experiences",titleAr:"تجارب سابقة",recycleFrom:["A1-U4","A1-U5","A2-U1"],unlocks:"A2-U3",
  objectives:{listen:"LISTENING.UNDERSTAND_PAST_EVENT",read:"READING.FOLLOW_SHORT_NARRATIVE",produce:"PRODUCTION.TELL_PAST_EXPERIENCE",interact:"INTERACTION.ASK_ABOUT_PAST",write:"WRITING.WRITE_PAST_NARRATIVE",mediate:"MEDIATION.RELAY_EVENT_SEQUENCE",mission:"ACTION.SHARE_MEMORABLE_DAY"},
  grammar:[
    ["BE_PAST","was/were","الماضي من be",1,"The trip was exciting.","كانت الرحلة ممتعة."],
    ["PAST_REGULAR","regular past -ed","الماضي المنتظم",2,"We visited the old market.","زرنا السوق القديم."],
    ["PAST_IRREGULAR","common irregular past forms","أفعال الماضي الشاذة الشائعة",3,"I went home and made dinner.","ذهبت إلى المنزل وأعددت العشاء."],
    ["PAST_QUESTIONS","did + subject + base verb","أسئلة الماضي بـ did",4,"Where did you go?","أين ذهبت؟"],
    ["PAST_NEGATIVE","did not + base verb","نفي الماضي",4,"We didn't stay long.","لم نبق طويلاً."],
    ["PAST_TIME_LINKERS","first, then, after that, finally","روابط تسلسل الماضي",5,"First we ate; then we walked.","أولاً أكلنا؛ ثم مشينا."]
  ],
  lexicon:[
    ["MEMORABLE_ADJ01","memorable","adjective","لا يُنسى",1,"It was a memorable day.","كان يوماً لا يُنسى."],
    ["TRIP_N01","trip","noun","رحلة",1,"The trip was short.","كانت الرحلة قصيرة."],
    ["YESTERDAY_ADV01","yesterday","adverb","أمس",1,"I was busy yesterday.","كنت مشغولاً أمس."],
    ["VISIT_V01","visit","verb","يزور",2,"We visited a museum.","زرنا متحفاً."],
    ["ARRIVE_V01","arrive","verb","يصل",2,"They arrived at noon.","وصلوا ظهراً."],
    ["DECIDE_V01","decide","verb","يقرر",2,"I decided to walk.","قررت أن أمشي."],
    ["GO_V02","go","verb","يذهب (ماضٍ: went)",3,"She went to the beach.","ذهبت إلى الشاطئ."],
    ["BUY_V02","buy","verb","يشتري (ماضٍ: bought)",3,"He bought a ticket.","اشترى تذكرة."],
    ["MEET_V02","meet","verb","يلتقي (ماضٍ: met)",3,"I met an old friend.","التقيت صديقاً قديماً."],
    ["HAPPEN_V01","happen","verb","يحدث",4,"What happened next?","ماذا حدث بعد ذلك؟"],
    ["EXPERIENCE_N01","experience","noun","تجربة",4,"Tell me about the experience.","حدثني عن التجربة."],
    ["AGO_ADV01","ago","adverb","منذ",4,"It happened two years ago.","حدث ذلك منذ سنتين."],
    ["SUDDENLY_ADV01","suddenly","adverb","فجأة",5,"Suddenly, the lights went out.","فجأة انطفأت الأضواء."],
    ["FINALLY_ADV01","finally","adverb","أخيراً",5,"Finally, we found the hotel.","أخيراً وجدنا الفندق."],
    ["SEQUENCE_N01","sequence","noun","تسلسل",5,"Put the events in sequence.","رتب الأحداث بالتسلسل."],
    ["STORY_N01","story","noun","قصة",6,"Write a short story.","اكتب قصة قصيرة."],
    ["EVENT_N01","event","noun","حدث",6,"Describe the main event.","صف الحدث الرئيسي."],
    ["SURPRISED_ADJ01","surprised","adjective","متفاجئ",6,"We were surprised.","كنا متفاجئين."]
  ],
  chunks:[
    ["LAST_WEEKEND","last weekend","عطلة نهاية الأسبوع الماضية",1],
    ["LAST_YEAR","last year","العام الماضي",1],
    ["TWO_DAYS_AGO","two days ago","منذ يومين",2],
    ["WHAT_HAPPENED","What happened?","ماذا حدث؟",4],
    ["HOW_WAS_IT","How was it?","كيف كان؟",4],
    ["AFTER_THAT","after that","بعد ذلك",5],
    ["IN_THE_END","in the end","في النهاية",5],
    ["A_GREAT_TIME","have a great time","يقضي وقتاً رائعاً",3]
  ],
  lessons:[
    {title:"Where Were You?",titleAr:"أين كنت؟",canDo:["listen","produce"],grammar:["BE_PAST"],lex:["MEMORABLE_ADJ01","TRIP_N01","YESTERDAY_ADV01"],chunks:["LAST_WEEKEND","LAST_YEAR"],input:I("Last weekend, I was in Najaf with my cousins. The streets were busy, but the visit was memorable.","في عطلة الأسبوع الماضية كنت في النجف مع أبناء عمومتي. كانت الشوارع مزدحمة، لكن الزيارة لا تُنسى.","Where was the speaker?","أين كان المتحدث؟",["In Najaf","At home","In Basra"],"In Najaf"),practice:P("The cafés ___ busy last night.",["were","was","are"],"were"),mastery:I("Rita was at a family party yesterday. Her parents were there too.","كانت ريتا في حفلة عائلية أمس. كان والداها هناك أيضاً.","Who was at the party?","من كان في الحفلة؟",["Rita and her parents","Rita alone","Only her parents"],"Rita and her parents"),production:Prod("spokenProduction","Say where you were yesterday and how it was.","قل أين كنت أمس وكيف كان الأمر.",evals.speak)},
    {title:"Regular Past Actions",titleAr:"أفعال الماضي المنتظمة",canDo:["listen","produce"],grammar:["PAST_REGULAR"],lex:["VISIT_V01","ARRIVE_V01","DECIDE_V01"],chunks:["TWO_DAYS_AGO"],input:I("We arrived early, visited the castle and decided to eat near the river.","وصلنا مبكراً وزرنا القلعة وقررنا أن نأكل قرب النهر.","Where did they eat?","أين أكلوا؟",["Near the river","At the castle","At home"],"Near the river"),practice:P("Maya ___ her aunt on Monday.",["visited","visit","visits"],"visited"),mastery:I("Ali planned a picnic, packed lunch and walked to the park. Rain started at noon.","خطط علي لنزهة وجهز الغداء ومشى إلى الحديقة. بدأ المطر ظهراً.","What happened at noon?","ماذا حدث ظهراً؟",["Rain started.","Ali packed lunch.","The picnic ended early."],"Rain started."),production:Prod("spokenProduction","Describe three regular past actions from a recent day.","صف ثلاثة أفعال ماضية منتظمة من يوم قريب.",evals.speak)},
    {title:"Irregular Past Actions",titleAr:"أفعال الماضي الشاذة",canDo:["read","produce"],grammar:["PAST_IRREGULAR"],lex:["GO_V02","BUY_V02","MEET_V02"],chunks:["A_GREAT_TIME"],inputSkill:"reading",masterySkill:"reading",input:R("I went to the market, bought some fruit and met my old teacher. We had a great time talking.","Who did the writer meet?","من التقى الكاتب؟",["An old teacher","A fruit seller","A cousin"],"An old teacher"),practice:P("We ___ a bus to the centre.",["took","take","taking"],"took"),mastery:R("Sara saw a new film, ate dinner with friends and came home at eleven.","What did Sara do before coming home?","ماذا فعلت سارة قبل عودتها؟",["She ate with friends.","She took a class.","She bought a film."],"She ate with friends."),production:Prod("spokenProduction","Use three common irregular past verbs to describe a real or fictional outing.","استخدم ثلاثة أفعال ماضية شاذة شائعة لوصف نزهة حقيقية أو خيالية.",evals.speak)},
    {title:"Ask About the Past",titleAr:"اسأل عن الماضي",canDo:["listen","interact"],grammar:["PAST_QUESTIONS","PAST_NEGATIVE"],lex:["HAPPEN_V01","EXPERIENCE_N01","AGO_ADV01"],chunks:["WHAT_HAPPENED","HOW_WAS_IT"],input:I("A: How was the concert? B: Great. A: Who did you go with? B: My sister. We didn't stay for the last song.","أ: كيف كانت الحفلة؟ ب: رائعة. أ: مع من ذهبت؟ ب: أختي. لم نبق للأغنية الأخيرة.","Did they hear the last song?","هل سمعوا الأغنية الأخيرة؟",["No","Yes","The speaker does not say"],"No"),practice:P("Where did you ___ last summer?",["go","went","going"],"go"),mastery:I("A: What happened yesterday? B: I missed the bus. A: Did you arrive late? B: No, I took a taxi.","أ: ماذا حدث أمس؟ ب: فاتتني الحافلة. أ: هل وصلت متأخراً؟ ب: لا، أخذت سيارة أجرة.","How did B avoid arriving late?","كيف تجنب ب الوصول متأخراً؟",["By taking a taxi","By catching the bus","By walking"],"By taking a taxi"),production:Prod("spokenInteraction","Ask a partner three connected questions about a past experience.","اسأل شريكاً ثلاثة أسئلة مترابطة عن تجربة سابقة.",evals.speak)},
    {title:"Put Events in Order",titleAr:"رتب الأحداث",canDo:["read","mediate"],grammar:["PAST_TIME_LINKERS"],lex:["SUDDENLY_ADV01","FINALLY_ADV01","SEQUENCE_N01"],chunks:["AFTER_THAT","IN_THE_END"],inputSkill:"reading",masterySkill:"reading",input:R("First, we took the wrong road. After that, the car stopped. Finally, a farmer showed us the way.","Who helped in the end?","من ساعد في النهاية؟",["A farmer","A driver","A police officer"],"A farmer"),practice:O(["we","After that,","the museum.","visited"],["After that,","we","visited","the museum."]),mastery:R("Nabil lost his key. Then he called his brother. His brother brought a spare key, and finally Nabil entered the flat.","What happened immediately after Nabil lost the key?","ماذا حدث مباشرة بعد أن أضاع نبيل المفتاح؟",["He called his brother.","He entered the flat.","He found the key."],"He called his brother."),production:Prod("mediation","Read a four-event timeline and relay the events in the correct order.","اقرأ خطاً زمنياً من أربعة أحداث وانقلها بالترتيب الصحيح.",evals.mediate)},
    {title:"A Short Past Story",titleAr:"قصة قصيرة في الماضي",canDo:["write","produce"],grammar:["BE_PAST","PAST_REGULAR","PAST_IRREGULAR","PAST_TIME_LINKERS"],lex:["STORY_N01","EVENT_N01","SURPRISED_ADJ01"],chunks:["IN_THE_END","A_GREAT_TIME"],inputSkill:"reading",masterySkill:"reading",input:R("Last Saturday, we went to the lake. Suddenly, we saw a small boat with no one in it. We called the police. In the end, they found the owner safely on the other side.","Why did the group call the police?","لماذا اتصلت المجموعة بالشرطة؟",["They saw an empty boat.","They lost their bags.","They needed a ride."],"They saw an empty boat."),practice:P("In the end, everyone ___ safe.",["was","were","is"],"was"),mastery:R("Mona arrived at the station late, but the train was delayed. She bought coffee and finally got on the train at nine.","Why did Mona still catch the train?","لماذا لحقت منى بالقطار؟",["The train was delayed.","She arrived early.","She bought a new ticket."],"The train was delayed."),production:Prod("writing","Write a short past narrative with a beginning, ordered events and an ending.","اكتب سرداً قصيراً في الماضي له بداية وأحداث مرتبة ونهاية.",evals.write,[70,100])}
  ],
  mission:{title:"A Memorable Day",titleAr:"يوم لا يُنسى",scenario:"Tell a friend about a memorable day, answer questions, order its events and send a written version.",reading:R("On Friday, Hana missed her train. She waited for the next one, met an old friend on the platform and travelled with her. The delay became the best part of the day.","Why did the delay become positive?","لماذا أصبح التأخير أمراً إيجابياً؟",["Hana met an old friend.","The ticket was cheaper.","The train was empty."],"Hana met an old friend."),audio:I("First we visited the market. Then we ate by the river. Suddenly it rained, so we ran into a small café.","أولاً زرنا السوق. ثم أكلنا قرب النهر. فجأة أمطرت، فركضنا إلى مقهى صغير.","Where did the speakers go when it rained?","إلى أين ذهب المتحدثون عندما أمطرت؟",["A café","The market","The station"],"A café"),interaction:{prompt:"Tell a past experience and respond to at least three follow-up questions.",promptAr:"احك تجربة سابقة وأجب عن ثلاثة أسئلة متابعة على الأقل.",evaluation:evals.speak},production:{prompt:"Give a connected one-to-two-minute account of a memorable day.",promptAr:"قدّم رواية مترابطة من دقيقة إلى دقيقتين عن يوم لا يُنسى.",evaluation:evals.speak},mediation:{prompt:"Relay the main events from a provided timeline in the correct order.",promptAr:"انقل الأحداث الرئيسية من خط زمني معروض بالترتيب الصحيح.",evaluation:evals.mediate},writing:{prompt:"Write the memorable day as a connected story with past forms and sequence linkers.",promptAr:"اكتب اليوم الذي لا يُنسى كقصة مترابطة مستخدماً صيغ الماضي وروابط التسلسل.",evaluation:evals.write,wordGuide:[80,110]}}
});

const U3=buildUnit({
  id:"A2-U3",title:"People and Relationships",titleAr:"الناس والعلاقات",recycleFrom:["A1-U2","A2-U1","A2-U2"],unlocks:"A2-U4",
  objectives:{listen:"LISTENING.UNDERSTAND_PERSON_DESCRIPTION",read:"READING.COMPARE_PEOPLE",produce:"PRODUCTION.DESCRIBE_PERSON",interact:"INTERACTION.DISCUSS_PEOPLE",write:"WRITING.WRITE_PERSON_PROFILE",mediate:"MEDIATION.RELAY_PERSON_MATCH",mission:"ACTION.CHOOSE_TEAM_MEMBER"},
  grammar:[
    ["LOOK_LIKE","look like + noun/pronoun","وصف المظهر بـ look like",1,"She looks like her mother.","هي تشبه أمها."],
    ["BE_LIKE","be like for character","السؤال عن الشخصية بـ be like",2,"What is he like?","كيف هي شخصيته؟"],
    ["COMPARATIVE_ADJECTIVES","comparative adjective + than","صيغة المقارنة",3,"Lina is calmer than Noor.","لينا أهدأ من نور."],
    ["SUPERLATIVE_ADJECTIVES","the + superlative adjective","صيغة التفضيل",4,"He is the most patient person here.","هو أكثر شخص صبور هنا."],
    ["RELATIVE_WHO_CHUNK","a person who ...","عبارة a person who",5,"We need someone who listens well.","نحتاج شخصاً يستمع جيداً."],
    ["TOO_ALSO_RELATION","too / also for shared qualities","too وalso للصفات المشتركة",6,"Mira is organised, and Sami is organised too.","ميرا منظمة، وسامي منظم أيضاً."]
  ],
  lexicon:[
    ["TALL_ADJ01","tall","adjective","طويل القامة",1,"He is tall and slim.","هو طويل ونحيف."],
    ["CURLY_ADJ01","curly","adjective","مجعد",1,"She has curly hair.","لديها شعر مجعد."],
    ["APPEARANCE_N01","appearance","noun","مظهر",1,"Describe his appearance.","صف مظهره."],
    ["PATIENT_ADJ01","patient","adjective","صبور",2,"Our teacher is patient.","مدرسنا صبور."],
    ["RELIABLE_ADJ01","reliable","adjective","موثوق",2,"A reliable friend keeps promises.","الصديق الموثوق يفي بوعوده."],
    ["OUTGOING_ADJ01","outgoing","adjective","اجتماعي",2,"Nadia is friendly and outgoing.","نادية ودودة واجتماعية."],
    ["CALM_ADJ01","calm","adjective","هادئ",3,"Sami is calmer than me.","سامي أهدأ مني."],
    ["ORGANISED_ADJ01","organised","adjective","منظم",3,"Rana is very organised.","رنا منظمة جداً."],
    ["CONFIDENT_ADJ01","confident","adjective","واثق",3,"He feels more confident now.","يشعر بثقة أكبر الآن."],
    ["FUNNIEST_ADJ01","funny","adjective","مضحك",4,"She is the funniest person in our group.","هي أكثر شخص مضحك في مجموعتنا."],
    ["KIND_ADJ01","kind","adjective","لطيف",4,"Ali is the kindest neighbour.","علي ألطف جار."],
    ["ACTIVE_ADJ01","active","adjective","نشيط",4,"Who is the most active member?","من أكثر الأعضاء نشاطاً؟"],
    ["COLLEAGUE_N01","colleague","noun","زميل عمل",5,"My colleague helped me.","ساعدني زميلي."],
    ["NEIGHBOUR_N01","neighbour","noun","جار",5,"Our new neighbour is friendly.","جارنا الجديد ودود."],
    ["RELATIONSHIP_N01","relationship","noun","علاقة",5,"They have a good working relationship.","لديهما علاقة عمل جيدة."],
    ["TEAM_N01","team","noun","فريق",6,"The team needs a leader.","يحتاج الفريق إلى قائد."],
    ["MEMBER_N01","member","noun","عضو",6,"Each member has a role.","لكل عضو دور."],
    ["SUITABLE_ADJ01","suitable","adjective","مناسب",6,"She is suitable for the role.","هي مناسبة للدور."]
  ],
  chunks:[
    ["WHAT_DOES_LOOK_LIKE","What does ... look like?","كيف يبدو...؟",1],
    ["WHAT_IS_LIKE","What is ... like?","كيف هي شخصية...؟",2],
    ["MORE_THAN","more ... than","أكثر ... من",3],
    ["THE_MOST","the most ...","الأكثر ...",4],
    ["GET_ON_WELL","get on well","ينسجم جيداً",5],
    ["A_PERSON_WHO","a person who ...","شخص يقوم بـ...",5],
    ["GOOD_AT","be good at","يجيد",6],
    ["BEST_CHOICE","the best choice","الخيار الأفضل",4]
  ],
  lessons:[
    {title:"What Do They Look Like?",titleAr:"كيف يبدون؟",canDo:["listen","produce"],grammar:["LOOK_LIKE"],lex:["TALL_ADJ01","CURLY_ADJ01","APPEARANCE_N01"],chunks:["WHAT_DOES_LOOK_LIKE"],input:I("My cousin is tall and has short curly hair. He wears glasses.","ابن عمي طويل وله شعر قصير مجعد. يرتدي نظارة.","Which description is correct?","أي وصف صحيح؟",["Tall with curly hair","Short with straight hair","Tall without glasses"],"Tall with curly hair"),practice:P("What does your sister look ___?",["like","as","than"],"like"),mastery:I("The new manager is medium height with long dark hair. She usually wears a blue jacket.","What colour jacket does she usually wear?","ما لون السترة التي ترتديها عادةً؟",["Blue","Black","Green"],"Blue"),production:Prod("spokenProduction","Describe a real or fictional person’s appearance in three or four details.","صف مظهر شخص حقيقي أو خيالي في ثلاثة أو أربعة تفاصيل.",evals.speak)},
    {title:"What Are They Like?",titleAr:"كيف هي شخصياتهم؟",canDo:["listen","interact"],grammar:["BE_LIKE"],lex:["PATIENT_ADJ01","RELIABLE_ADJ01","OUTGOING_ADJ01"],chunks:["WHAT_IS_LIKE"],input:I("A: What is Dalia like? B: She is outgoing and kind. She talks to everyone, but she is also a patient listener.","أ: كيف هي شخصية داليا؟ ب: اجتماعية ولطيفة. تتحدث مع الجميع، لكنها أيضاً مستمعة صبورة.","Which quality is mentioned?","أي صفة ذُكرت؟",["Patient","Careless","Quiet"],"Patient"),practice:P("What ___ your new colleague like?",["is","does","has"],"is"),mastery:I("Fadi is reliable. When he says he will help, he always comes on time.","What shows that Fadi is reliable?","ما الذي يدل على أن فادي موثوق؟",["He keeps his promises.","He talks a lot.","He works alone."],"He keeps his promises."),production:Prod("spokenInteraction","Ask about someone’s character and respond with two qualities plus an example.","اسأل عن شخصية شخص وأجب بصفتين مع مثال.",evals.speak)},
    {title:"Compare People",titleAr:"قارن بين الناس",canDo:["read","produce"],grammar:["COMPARATIVE_ADJECTIVES"],lex:["CALM_ADJ01","ORGANISED_ADJ01","CONFIDENT_ADJ01"],chunks:["MORE_THAN"],inputSkill:"reading",masterySkill:"reading",input:R("Rami and Hadi are both friendly. Rami is calmer, but Hadi is more confident when speaking to a group.","Who is more confident in a group?","من الأكثر ثقة أمام مجموعة؟",["Hadi","Rami","Both equally"],"Hadi"),practice:P("Salma is more organised ___ her brother.",["than","that","then"],"than"),mastery:R("Lina finishes tasks early. Noor sometimes forgets deadlines. Lina is more organised than Noor.","Why is Lina described as more organised?","لماذا توصف لينا بأنها أكثر تنظيماً؟",["She finishes tasks early.","She forgets deadlines.","She works fewer hours."],"She finishes tasks early."),production:Prod("spokenProduction","Compare two people using at least two comparative forms and fair evidence.","قارن بين شخصين مستخدماً صيغتي مقارنة على الأقل ودليلاً عادلاً.",evals.speak)},
    {title:"The Best for the Role",titleAr:"الأفضل للدور",canDo:["read","interact"],grammar:["SUPERLATIVE_ADJECTIVES"],lex:["FUNNIEST_ADJ01","KIND_ADJ01","ACTIVE_ADJ01"],chunks:["THE_MOST","BEST_CHOICE"],inputSkill:"reading",masterySkill:"reading",input:R("Three volunteers can lead the activity. Sami has the most experience, Reem is the most organised, and Amal is the most creative.","Who is the most organised?","من الأكثر تنظيماً؟",["Reem","Sami","Amal"],"Reem"),practice:P("He is the ___ patient person on the team.",["most","more","much"],"most"),mastery:R("Nora runs every day and plays two sports. Huda walks twice a week. Nora is the most active person in the group.","What supports the description of Nora?","ما الذي يدعم وصف نورا؟",["Her frequent exercise","Her quiet personality","Her job"],"Her frequent exercise"),production:Prod("spokenInteraction","Discuss three candidates and agree who is the best for a simple role, giving reasons.","ناقش ثلاثة مرشحين واتفق على الأفضل لدور بسيط مع ذكر الأسباب.",evals.speak)},
    {title:"People in My Community",titleAr:"الناس في مجتمعي",canDo:["read","mediate"],grammar:["RELATIVE_WHO_CHUNK"],lex:["COLLEAGUE_N01","NEIGHBOUR_N01","RELATIONSHIP_N01"],chunks:["GET_ON_WELL","A_PERSON_WHO"],inputSkill:"reading",masterySkill:"reading",input:R("My neighbour is a person who helps older people in our street. My colleague is someone who always shares useful information.","Who helps older people?","من يساعد كبار السن؟",["The neighbour","The colleague","The writer"],"The neighbour"),practice:P("We need someone ___ listens carefully.",["who","where","what"],"who"),mastery:R("Mazen gets on well with his manager because they communicate clearly. He also supports a new colleague who is learning the job.","Why does Mazen get on well with his manager?","لماذا ينسجم مازن مع مديره؟",["They communicate clearly.","They are neighbours.","They have the same job."],"They communicate clearly."),production:Prod("mediation","Read three short relationship notes and relay who can help with a stated need.","اقرأ ثلاث ملاحظات قصيرة عن العلاقات وانقل من يستطيع المساعدة في حاجة محددة.",evals.mediate)},
    {title:"Build a Balanced Team",titleAr:"كوّن فريقاً متوازناً",canDo:["write","produce"],grammar:["TOO_ALSO_RELATION","COMPARATIVE_ADJECTIVES","SUPERLATIVE_ADJECTIVES"],lex:["TEAM_N01","MEMBER_N01","SUITABLE_ADJ01"],chunks:["GOOD_AT","BEST_CHOICE"],inputSkill:"reading",masterySkill:"reading",input:R("A team needs an organiser and a presenter. Layla is good at planning, while Faris is the most confident speaker. Together, they are a suitable pair.","Why are Layla and Faris a suitable pair?","لماذا ليلى وفارس ثنائي مناسب؟",["They have different useful strengths.","They are both presenters.","They are the oldest members."],"They have different useful strengths."),practice:P("Rana is good ___ solving practical problems.",["at","in","for"],"at"),mastery:R("The project needs careful records. Zain is more organised than the others and checks every detail.","Who is the best choice for keeping records?","من الخيار الأفضل لحفظ السجلات؟",["Zain","The least organised member","No one"],"Zain"),production:Prod("writing","Recommend two people for a small team. Compare their qualities and explain each role.","رشّح شخصين لفريق صغير. قارن صفاتهما واشرح دور كل منهما.",evals.write,[70,100])}
  ],
  mission:{title:"Choose the Best Person for a Team",titleAr:"اختر أفضل شخص لفريق",scenario:"A community project needs two new members. Understand the profiles, discuss the candidates, make a choice and explain it.",reading:R("Rasha is patient and reliable, and she has the most experience with children. Tarek is creative and confident, but he is new to the area.","Who has more experience with children?","من لديه خبرة أكبر مع الأطفال؟",["Rasha","Tarek","Both"],"Rasha"),audio:I("Bilal is quieter than the other candidates, but he is the most organised and always finishes tasks on time.","بلال أهدأ من المرشحين الآخرين، لكنه الأكثر تنظيماً وينهي المهام دائماً في الوقت.","What is Bilal's strongest stated quality?","ما أقوى صفة مذكورة لبلال؟",["Organisation","Confidence","Creativity"],"Organisation"),interaction:{prompt:"Discuss at least three candidates and agree on two team members.",promptAr:"ناقش ثلاثة مرشحين على الأقل واتفق على عضوين للفريق.",evaluation:evals.speak},production:{prompt:"Describe the chosen people and compare their useful qualities.",promptAr:"صف الشخصين المختارين وقارن صفاتهما المفيدة.",evaluation:evals.speak},mediation:{prompt:"Relay the essential strengths and limitations from the candidate profiles to the team leader.",promptAr:"انقل نقاط القوة والقيود الأساسية من ملفات المرشحين إلى قائد الفريق.",evaluation:evals.mediate},writing:{prompt:"Write a recommendation naming the best choices, their roles and clear reasons.",promptAr:"اكتب توصية تذكر أفضل الخيارات وأدوارهم وأسباباً واضحة.",evaluation:evals.write,wordGuide:[80,110]}}
});

const U4=buildUnit({
  id:"A2-U4",title:"Home and Neighbourhood",titleAr:"المنزل والحي",recycleFrom:["A1-U3","A1-U8","A2-U3"],unlocks:"A2-U5",
  objectives:{listen:"LISTENING.UNDERSTAND_HOUSING_INFO",read:"READING.COMPARE_HOUSING",produce:"PRODUCTION.DESCRIBE_HOME_AREA",interact:"INTERACTION.DISCUSS_HOUSING_PROBLEM",write:"WRITING.WRITE_HOUSING_RECOMMENDATION",mediate:"MEDIATION.RELAY_HOUSING_OPTIONS",mission:"ACTION.CHOOSE_HOME"},
  grammar:[
    ["THERE_WAS_WERE","there was / there were","كان يوجد / كانت توجد",1,"There was a balcony.","كانت توجد شرفة."],
    ["QUANTIFIERS_AREA","some, any, a lot of, not much/many","محددات الكمية للأماكن",2,"There are a lot of shops nearby.","توجد متاجر كثيرة قربنا."],
    ["HOUSING_COMPARATIVES","comparatives for homes and areas","المقارنة بين المنازل والأحياء",3,"The flat is cheaper than the house.","الشقة أرخص من المنزل."],
    ["TOO_ADJECTIVE","too + adjective","أكثر من اللازم",4,"The kitchen is too small.","المطبخ صغير أكثر من اللازم."],
    ["ADJECTIVE_ENOUGH","adjective + enough","صفة + بما يكفي",4,"The room is bright enough.","الغرفة مضيئة بما يكفي."],
    ["HOUSING_REQUESTS","Could you ...? / Can we ...?","طلبات مهذبة لمشكلة سكن",5,"Could you check the heating?","هل يمكنك فحص التدفئة؟"]
  ],
  lexicon:[
    ["BALCONY_N01","balcony","noun","شرفة",1,"The flat had a small balcony.","كانت للشقة شرفة صغيرة."],
    ["HEATING_N01","heating","noun","تدفئة",1,"The heating was broken.","كانت التدفئة معطلة."],
    ["MOVE_V01","move","verb","ينتقل",1,"We moved last month.","انتقلنا الشهر الماضي."],
    ["NEARBY_ADV01","nearby","adverb","قريب",2,"There is a pharmacy nearby.","توجد صيدلية قريبة."],
    ["FACILITY_N01","facility","noun","مرفق",2,"The area has good sports facilities.","في المنطقة مرافق رياضية جيدة."],
    ["CONVENIENT_ADJ01","convenient","adjective","مريح / ملائم",2,"The location is convenient.","الموقع ملائم."],
    ["SPACIOUS_ADJ01","spacious","adjective","واسع",3,"The house is more spacious.","المنزل أوسع."],
    ["PEACEFUL_ADJ01","peaceful","adjective","هادئ",3,"This street is peaceful.","هذا الشارع هادئ."],
    ["CROWDED_ADJ01","crowded","adjective","مزدحم",3,"The centre is crowded.","المركز مزدحم."],
    ["NOISY_ADJ01","noisy","adjective","صاخب",4,"The bedroom is too noisy.","غرفة النوم صاخبة أكثر من اللازم."],
    ["BRIGHT_ADJ01","bright","adjective","مضيء",4,"The office is bright enough.","المكتب مضيء بما يكفي."],
    ["SPACE_N01","space","noun","مساحة",4,"There isn't enough space.","لا توجد مساحة كافية."],
    ["LEAK_N01","leak","noun","تسرّب",5,"There is a leak under the sink.","يوجد تسرّب تحت الحوض."],
    ["LANDLORD_N01","landlord","noun","مالك العقار",5,"Call the landlord.","اتصل بمالك العقار."],
    ["REPAIR_V01","repair","verb","يصلح",5,"Can you repair the door?","هل يمكنك إصلاح الباب؟"],
    ["OPTION_N01","option","noun","خيار",6,"Compare the two options.","قارن الخيارين."],
    ["RENT_N01","rent","noun","إيجار",6,"The rent includes water.","يشمل الإيجار الماء."],
    ["RECOMMEND_V01","recommend","verb","يوصي",6,"Which home do you recommend?","بأي منزل توصي؟"]
  ],
  chunks:[
    ["USED_TO_BE_THERE","There used to be ...","كان يوجد سابقاً...",1,false],
    ["WITHIN_WALKING_DISTANCE","within walking distance","على مسافة مشي",2],
    ["CLOSE_TO","close to","قريب من",2],
    ["COMPARED_WITH","compared with","مقارنةً بـ",3],
    ["TOO_FAR_FROM","too far from","بعيد أكثر من اللازم عن",4],
    ["ENOUGH_SPACE_FOR","enough space for","مساحة كافية لـ",4],
    ["THERE_IS_A_PROBLEM_WITH","There is a problem with ...","توجد مشكلة في...",5],
    ["BEST_VALUE","best value","أفضل قيمة",6]
  ],
  lessons:[
    {title:"The Old and New Home",titleAr:"المنزل القديم والجديد",canDo:["listen","produce"],grammar:["THERE_WAS_WERE"],lex:["BALCONY_N01","HEATING_N01","MOVE_V01"],chunks:["USED_TO_BE_THERE"],input:I("Our old flat was small. There was one bedroom and there wasn't a balcony. We moved because the heating was unreliable.","كانت شقتنا القديمة صغيرة. كانت فيها غرفة نوم واحدة ولم تكن فيها شرفة. انتقلنا لأن التدفئة لم تكن موثوقة.","Why did the family move?","لماذا انتقلت العائلة؟",["The heating was unreliable.","The balcony was large.","There were too many bedrooms."],"The heating was unreliable."),practice:P("There ___ two bathrooms in the old house.",["were","was","are"],"were"),mastery:I("The building was quiet, and there were two parks nearby. There wasn't a lift.","What was missing?","ما الذي كان مفقوداً؟",["A lift","Parks","Quiet rooms"],"A lift"),production:Prod("spokenProduction","Describe a previous home or a fictional old home using there was/were.","صف منزلاً سابقاً أو منزلاً قديماً خيالياً مستخدماً there was/were.",evals.speak)},
    {title:"What Is Nearby?",titleAr:"ماذا يوجد بالقرب؟",canDo:["listen","produce"],grammar:["QUANTIFIERS_AREA"],lex:["NEARBY_ADV01","FACILITY_N01","CONVENIENT_ADJ01"],chunks:["WITHIN_WALKING_DISTANCE","CLOSE_TO"],input:I("The area is convenient. There are a lot of cafés and some small shops. There isn't much traffic at night.","المنطقة ملائمة. توجد مقاهٍ كثيرة وبعض المتاجر الصغيرة. لا توجد حركة مرور كثيرة ليلاً.","What is the traffic like at night?","كيف هي حركة المرور ليلاً؟",["There isn't much.","There is a lot.","There is none at any time."],"There isn't much."),practice:P("There are ___ good facilities near the flat.",["some","any","much"],"some"),mastery:I("There aren't many buses after ten, but the station is within walking distance.","What transport limitation is mentioned?","ما قيد النقل المذكور؟",["Few late buses","No station","Heavy daytime traffic"],"Few late buses"),production:Prod("spokenProduction","Describe the services and transport near your home or a fictional home.","صف الخدمات والنقل قرب منزلك أو منزل خيالي.",evals.speak)},
    {title:"Compare Two Areas",titleAr:"قارن منطقتين",canDo:["read","mediate"],grammar:["HOUSING_COMPARATIVES"],lex:["SPACIOUS_ADJ01","PEACEFUL_ADJ01","CROWDED_ADJ01"],chunks:["COMPARED_WITH"],inputSkill:"reading",masterySkill:"reading",input:R("Green Street is quieter and cheaper than Central Road, but Central Road is closer to the university and has more shops.","Which area is closer to the university?","أي منطقة أقرب إلى الجامعة؟",["Central Road","Green Street","Both"],"Central Road"),practice:P("The house is more spacious ___ the flat.",["than","then","that"],"than"),mastery:R("Area A is more peaceful, while Area B is more convenient for buses. Area B is also more crowded at weekends.","Which area suits someone who values quiet?","أي منطقة تناسب من يقدّر الهدوء؟",["Area A","Area B","Both equally"],"Area A"),production:Prod("mediation","Read two neighbourhood cards and relay the main advantage and disadvantage of each.","اقرأ بطاقتي حيين وانقل الميزة والعيب الرئيسيين لكل منهما.",evals.mediate)},
    {title:"Too Small or Big Enough?",titleAr:"صغير جداً أم كبير بما يكفي؟",canDo:["listen","interact"],grammar:["TOO_ADJECTIVE","ADJECTIVE_ENOUGH"],lex:["NOISY_ADJ01","BRIGHT_ADJ01","SPACE_N01"],chunks:["TOO_FAR_FROM","ENOUGH_SPACE_FOR"],input:I("The living room is bright enough, but the kitchen is too small for a family of five. The street is also too noisy at night.","غرفة المعيشة مضيئة بما يكفي، لكن المطبخ صغير جداً لعائلة من خمسة أشخاص. الشارع أيضاً صاخب جداً ليلاً.","What is acceptable?","ما الشيء المقبول؟",["The living room's light","The kitchen size","The night noise"],"The living room's light"),practice:P("Is the room warm ___ for a baby?",["enough","too","more"],"enough"),mastery:I("The flat is close enough to work, but it is too expensive and there isn't enough storage space.","Which problem is about money?","أي مشكلة تتعلق بالمال؟",["It is too expensive.","It is close to work.","It lacks storage."],"It is too expensive."),production:Prod("spokenInteraction","Discuss whether a home is suitable, using too and enough with reasons.","ناقش ما إذا كان المنزل مناسباً مستخدماً too وenough مع الأسباب.",evals.speak)},
    {title:"Report a Housing Problem",titleAr:"أبلغ عن مشكلة سكن",canDo:["read","interact"],grammar:["HOUSING_REQUESTS"],lex:["LEAK_N01","LANDLORD_N01","REPAIR_V01"],chunks:["THERE_IS_A_PROBLEM_WITH"],inputSkill:"reading",masterySkill:"reading",input:R("Hello, there is a problem with the kitchen tap. It has leaked since this morning. Could you send someone to check it today?", "What does the writer request?","ماذا يطلب الكاتب؟",["Someone to check the tap","A new kitchen","Lower rent"],"Someone to check the tap"),practice:P("Could you ___ the broken window?",["repair","repaired","repairing"],"repair"),mastery:R("The heating is not working, and the flat is very cold. Can you tell me when a technician can come?", "What information does the tenant need?","ما المعلومة التي يحتاجها المستأجر؟",["The technician's arrival time","The cost of a new flat","The landlord's address"],"The technician's arrival time"),production:Prod("spokenInteraction","Report a housing problem politely, explain its effect and request action.","أبلغ عن مشكلة سكن بأدب واشرح أثرها واطلب إجراءً.",evals.speak)},
    {title:"Recommend a Home",titleAr:"أوصِ بمنزل",canDo:["write","produce"],grammar:["HOUSING_COMPARATIVES","TOO_ADJECTIVE","ADJECTIVE_ENOUGH"],lex:["OPTION_N01","RENT_N01","RECOMMEND_V01"],chunks:["BEST_VALUE"],inputSkill:"reading",masterySkill:"reading",input:R("Flat A costs $500 and is close to work, but it is small. Flat B costs $560, has two bedrooms and includes heating. For a couple with a child, Flat B offers better value.","Why is Flat B recommended?","لماذا يوصى بالشقة ب؟",["It has more suitable space and included heating.","It is cheaper.","It is closer to work."],"It has more suitable space and included heating."),practice:P("This option offers the best ___ for a family.",["value","valuable","valued"],"value"),mastery:R("House X has a garden but is far from transport. Flat Y has no garden, but it is cheaper and close enough to the station.","Which option is more convenient for commuting?","أي خيار أنسب للتنقل؟",["Flat Y","House X","Neither"],"Flat Y"),production:Prod("writing","Compare two housing options and recommend one for a stated person's needs.","قارن خيارَي سكن وأوصِ بأحدهما وفق احتياجات شخص محدد.",evals.write,[75,105])}
  ],
  mission:{title:"Choose Between Two Homes",titleAr:"اختر بين منزلين",scenario:"A friend is moving. Compare two unseen listings, discuss needs, identify a possible problem and recommend the better home.",reading:R("Riverside Flat: two bedrooms, quiet street, no lift, $620 monthly. Centre Studio: one room, near buses and shops, fifth floor with a lift, $510 monthly.","Which home has two bedrooms?","أي منزل فيه غرفتا نوم؟",["Riverside Flat","Centre Studio","Both"],"Riverside Flat"),audio:I("The studio is convenient, but it is too small for two people who work from home. The riverside flat is larger and quiet enough for online meetings.","الاستوديو ملائم، لكنه صغير جداً لشخصين يعملان من المنزل. شقة النهر أكبر وهادئة بما يكفي للاجتماعات عبر الإنترنت.","Which home is better for online meetings?","أي منزل أفضل للاجتماعات عبر الإنترنت؟",["Riverside Flat","Centre Studio","Both equally"],"Riverside Flat"),interaction:{prompt:"Ask about the mover's needs and discuss the advantages and disadvantages of both homes.",promptAr:"اسأل عن احتياجات الشخص المنتقل وناقش مزايا وعيوب المنزلين.",evaluation:evals.speak},production:{prompt:"Present a clear recommendation with comparisons and a practical reason.",promptAr:"قدّم توصية واضحة تتضمن مقارنات وسبباً عملياً.",evaluation:evals.speak},mediation:{prompt:"Relay the rent, location, space and access details from both listings without adding facts.",promptAr:"انقل تفاصيل الإيجار والموقع والمساحة والوصول من الإعلانين من دون إضافة معلومات.",evaluation:evals.mediate},writing:{prompt:"Write the friend a recommendation comparing both homes and mentioning one possible problem.",promptAr:"اكتب لصديقك توصية تقارن المنزلين وتذكر مشكلة محتملة واحدة.",evaluation:evals.write,wordGuide:[85,115]}}
});

const built=[U1,U2,U3,U4];
export const packageData={
  canDo:Object.fromEntries(built.flatMap(x=>Object.values(x.canDo).map(id=>[id,id]))),
  units:built.map(x=>x.unit),
  grammar:Object.fromEntries(built.map(x=>[x.unit.id,x.records.grammar])),
  lexicon:Object.fromEntries(built.map(x=>[x.unit.id,x.records.lexicon])),
  chunks:Object.fromEntries(built.map(x=>[x.unit.id,x.records.chunks]))
};
