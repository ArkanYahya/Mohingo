const C={
  EXIT_LISTEN:"A1.EXIT.LISTENING.UNDERSTAND_EVERYDAY_INFO",
  EXIT_READ:"A1.EXIT.READING.UNDERSTAND_SIMPLE_TEXTS",
  EXIT_WRITE:"A1.EXIT.WRITING.WRITE_SIMPLE_CONNECTED_TEXT",
  EXIT_INTERACT:"A1.EXIT.INTERACTION.HANDLE_SIMPLE_EXCHANGE",
  EXIT_SPEAK:"A1.EXIT.PRODUCTION.DESCRIBE_FAMILIAR_MATTER",
  EXIT_MEDIATE:"A1.EXIT.MEDIATION.RELAY_SIMPLE_INFORMATION",
  EXIT_MISSION:"A1.EXIT.ACTION.COMPLETE_MULTI_STEP_MISSION"
};

const act=(id,type,skill,canDo,data)=>({id,type,mode:"mastery",skill,canDo:Array.isArray(canDo)?canDo:[canDo],...data});
const audio=(id,canDo,prompt,promptAr,options,answer,audioTranscript,extra={})=>act(id,"audioChoice","listening",canDo,{prompt,promptAr,options,answer,audioTranscript,...extra});
const choice=(id,canDo,prompt,promptAr,options,answer,sourceText,extra={})=>act(id,"textChoice","reading",canDo,{prompt,promptAr,options,answer,sourceText,...extra});
const speak=(id,skill,canDo,prompt,promptAr,evaluation,extra={})=>act(id,"speak",skill,canDo,{prompt,promptAr,evaluation,accepted:[],fallbackSkill:"writing",fallbackCountsFor:"accessOnly",...extra});
const write=(id,skill,canDo,prompt,promptAr,evaluation,wordGuide,extra={})=>act(id,"write",skill,canDo,{prompt,promptAr,evaluation,wordGuide,accepted:[],...extra});

export const finalMission={
  id:"A1-FINAL-MISSION",
  title:"A Day in a New City",
  titleAr:"يوم في مدينة جديدة",
  status:"required-capstone",
  estimatedMinutes:[20,30],
  sourcePolicy:"All names, schedules, maps, menus and problems are fictional and unseen in earlier lessons.",
  scenario:"Register for a short activity, meet people, navigate to three places, buy something, solve a small problem and arrange a later meeting.",
  canDo:Object.values(C),
  stages:[
    {id:"A1-FINAL-MISSION-S1",title:"Register",titleAr:"سجّل",activityIds:["A1-FINAL-MISSION-A01","A1-FINAL-MISSION-A02"]},
    {id:"A1-FINAL-MISSION-S2",title:"Meet People",titleAr:"تعرّف على أشخاص",activityIds:["A1-FINAL-MISSION-A03","A1-FINAL-MISSION-A04"]},
    {id:"A1-FINAL-MISSION-S3",title:"Find the Places",titleAr:"اعثر على الأماكن",activityIds:["A1-FINAL-MISSION-A05","A1-FINAL-MISSION-A06"]},
    {id:"A1-FINAL-MISSION-S4",title:"Buy What You Need",titleAr:"اشتر ما تحتاجه",activityIds:["A1-FINAL-MISSION-A07","A1-FINAL-MISSION-A08"]},
    {id:"A1-FINAL-MISSION-S5",title:"Solve a Problem",titleAr:"حل مشكلة",activityIds:["A1-FINAL-MISSION-A09","A1-FINAL-MISSION-A10"]},
    {id:"A1-FINAL-MISSION-S6",title:"Make the Next Plan",titleAr:"رتب الخطة التالية",activityIds:["A1-FINAL-MISSION-A11","A1-FINAL-MISSION-A12"]}
  ],
  activities:[
    audio("A1-FINAL-MISSION-A01",[C.EXIT_LISTEN,C.EXIT_MISSION],"Which registration time is available?","أي وقت متاح للتسجيل؟",["09:30","10:30","12:00"],"10:30","The nine-thirty group is full. You can join the group at ten thirty."),
    act("A1-FINAL-MISSION-A02","form","writing",[C.EXIT_WRITE,C.EXIT_MISSION],{prompt:"Complete the fictional registration card.",promptAr:"أكمل بطاقة التسجيل الخيالية.",fields:["name","spelling","country","city","preferredTime"],evaluation:"complete-coherent-fictional-registration"}),
    speak("A1-FINAL-MISSION-A03","spokenInteraction",[C.EXIT_INTERACT,C.EXIT_MISSION],"Introduce yourself to Sam, ask two personal questions and use one repair phrase if needed.","عرّف نفسك إلى سام واسأله سؤالين شخصيين واستخدم عبارة إصلاح عند الحاجة.","introduction-two-questions-repair"),
    audio("A1-FINAL-MISSION-A04",[C.EXIT_LISTEN,C.EXIT_MISSION],"Which profile belongs to Sam?","أي ملف يخص سام؟",["from Canada; lives in Erbil; teacher","from Italy; lives in Basra; engineer","from Canada; lives in Baghdad; doctor"],"from Canada; lives in Erbil; teacher","Hi, I'm Sam. I'm from Canada, but I live in Erbil now. I'm a teacher."),
    choice("A1-FINAL-MISSION-A05",[C.EXIT_READ,C.EXIT_MISSION],"Which route reaches the information office first?","أي مسار يصل إلى مكتب المعلومات أولاً؟",["straight, left at bank, office beside pharmacy","right at café, past station, office opposite park","left at library, cross street, office at hospital"],"straight, left at bank, office beside pharmacy","Map note: From the activity centre, go straight to the bank. Turn left. The information office is next to the pharmacy."),
    speak("A1-FINAL-MISSION-A06","mediation",[C.EXIT_MEDIATE,C.EXIT_MISSION],"Explain the route to Sam and include the closed front entrance: use the side entrance.","اشرح المسار لسام واذكر أن المدخل الأمامي مغلق وأن عليه استخدام المدخل الجانبي.","route-plus-access-change"),
    choice("A1-FINAL-MISSION-A07",[C.EXIT_READ,C.EXIT_MISSION],"Choose one rain jacket and one drink within a $30 budget.","اختر سترة مطر وشراباً ضمن ميزانية 30 دولاراً.",["blue jacket $24 + water $2","black jacket $29 + juice $3","coat $35 + tea $1"],"blue jacket $24 + water $2","City shop: blue rain jacket $24; black jacket $29; warm coat $35. Café: water $2; juice $3; tea $1."),
    speak("A1-FINAL-MISSION-A08","spokenInteraction",[C.EXIT_INTERACT,C.EXIT_MISSION],"Ask for the blue jacket in medium, confirm the price and pay by card.","اطلب السترة الزرقاء بمقاس متوسط وأكد السعر وادفع بالبطاقة.","product-size-price-payment"),
    audio("A1-FINAL-MISSION-A09",[C.EXIT_LISTEN,C.EXIT_MISSION],"What problem must be solved?","ما المشكلة التي يجب حلها؟",["Sam has a headache and the jacket is the wrong size.","The train is late and Sam is hungry.","The café is closed and the bag is broken."],"Sam has a headache and the jacket is the wrong size.","I have a headache, and this jacket is large. We asked for medium."),
    speak("A1-FINAL-MISSION-A10","mediation",[C.EXIT_MEDIATE,C.EXIT_MISSION],"Tell the assistant the correct jacket request, then relay the pharmacy's simple advice to Sam: rest and drink water.","أخبر الموظف بطلب السترة الصحيح ثم انقل لسام نصيحة الصيدلية البسيطة: الراحة وشرب الماء.","two-part-problem-mediation"),
    speak("A1-FINAL-MISSION-A11","spokenInteraction",[C.EXIT_INTERACT,C.EXIT_MISSION],"Arrange a meeting with Sam tomorrow: agree on activity, place and time, then respond to one time change.","رتب لقاءً مع سام غداً: اتفق على النشاط والمكان والوقت ثم استجب لتغيير واحد في الوقت.","future-arrangement-and-change"),
    write("A1-FINAL-MISSION-A12","writing",[C.EXIT_WRITE,C.EXIT_MISSION],"Write a 45–60-word final message confirming tomorrow's activity, place, time, weather preparation and one item Sam should bring.","اكتب رسالة نهائية من 45–60 كلمة تؤكد نشاط الغد ومكانه ووقته والاستعداد للطقس وشيئاً يحضره سام.","capstone-confirmation-message",[45,60])
  ],
  scoring:{
    completionRequired:true,
    requiredSkillGroups:[["listening","reading"],["spokenInteraction","writing"],["mediation"]],
    criteria:["taskCompletion","meaningComprehensible","appropriateA1Language","informationAccuracy"],
    minimumCriterionScore:0.6,
    speechAccuracyWeight:0.2,
    noSingleAverageCompensation:true
  }
};

const listeningData=[
  ["Where should the listener go?","أين ينبغي أن يذهب المستمع؟",["Room 4","Room 14","Room 40"],"Room 4","Your English class is in room four, next to the library."],
  ["What is the woman's name?","ما اسم المرأة؟",["Nadia Karim","Nora Kareem","Nadia Kamil"],"Nadia Karim","My name is Nadia Karim. Nadia: N-A-D-I-A. Karim: K-A-R-I-M."],
  ["When does the shop close?","متى يغلق المتجر؟",["5:30","6:00","6:30"],"5:30","The shop opens at nine and closes at half past five today."],
  ["Which person is described?","أي شخص موصوف؟",["tall man with short black hair","short woman with long brown hair","tall woman with a red hat"],"tall man with short black hair","My brother is tall. He has short black hair and glasses."],
  ["Where are the keys?","أين المفاتيح؟",["under the small table","on the kitchen table","next to the bed"],"under the small table","The keys aren't on the kitchen table. They're under the small table near the door."],
  ["What does Lina usually do first?","ماذا تفعل لينا عادة أولاً؟",["has breakfast","starts work","walks home"],"has breakfast","I usually have breakfast at seven, then I start work at eight."],
  ["Which activity can both people do?","أي نشاط يستطيع الشخصان فعله؟",["play chess","swim","dance"],"play chess","I can play chess and swim. Sara can play chess, but she can't swim."],
  ["What is the complete order?","ما الطلب الكامل؟",["soup, bread, tea","salad, rice, water","sandwich, soup, juice"],"soup, bread, tea","I'd like a bowl of soup, some bread and one tea, please."],
  ["How much is the purchase?","كم سعر الشراء؟",["$27","$37","$17"],"$27","The shirt is twelve dollars and the trousers are fifteen. That's twenty-seven dollars."],
  ["Where is the pharmacy?","أين الصيدلية؟",["opposite the bank","behind the station","between two cafés"],"opposite the bank","The pharmacy is opposite the bank, on the corner."],
  ["Which bus should the passenger take?","أي حافلة ينبغي أن يستقلها المسافر؟",["bus 18","bus 8","bus 80"],"bus 18","Take bus eighteen from stop six. It goes directly to the airport."],
  ["What symptom does the speaker NOT have?","أي عرض لا يعاني منه المتحدث؟",["fever","cough","headache"],"fever","I have a cough and a headache, but I don't have a fever."],
  ["What should the listener wear?","ماذا ينبغي أن يرتدي المستمع؟",["warm coat and boots","light shirt and hat","jacket and sandals"],"warm coat and boots","It is snowing and very cold. Wear a warm coat and boots."],
  ["What are they doing now?","ماذا يفعلون الآن؟",["waiting inside","walking in the park","travelling by train"],"waiting inside","It's raining, so we're waiting inside the station."],
  ["What is the new meeting arrangement?","ما ترتيب اللقاء الجديد؟",["Sunday at 4 in the café","Saturday at 4 in the park","Sunday at 5 at the station"],"Sunday at 4 in the café","Saturday is difficult. Let's meet at the café on Sunday at four instead."],
  ["Why can't Omar come at six?","لماذا لا يستطيع عمر الحضور في السادسة؟",["he works late","the café is closed","he is travelling"],"he works late","I finish work at seven, so I can't meet at six. Is eight okay?"]
];

const readingData=[
  ["Which instruction means the learner must speak?","أي تعليمة تعني أن على المتعلم التحدث؟",["Say your answer.","Choose the picture.","Read the sentence."],"Say your answer.","Lesson screen: 1 Listen to the audio. 2 Say your answer. 3 Choose Continue."],
  ["Which statement about Amal is true?","أي جملة عن أمل صحيحة؟",["She lives in Mosul and is a nurse.","She is from Mosul and lives in Amman.","She is a teacher from Jordan."],"She lives in Mosul and is a nurse.","Amal is from Jordan, but she lives in Mosul. She works at a hospital as a nurse."],
  ["Who is Yasin?","من ياسين؟",["Rima's son","Rima's brother","Rima's father"],"Rima's son","Rima is married to Hassan. They have one son, Yasin, and one daughter, Dalia."],
  ["Which room has two beds?","أي غرفة فيها سريران؟",["Room B","Room A","neither room"],"Room B","Room A has one bed and a desk. Room B has two beds, one table and no desk."],
  ["When is the writer free?","متى يكون الكاتب متفرغاً؟",["Friday after 3","Friday morning","Saturday after 6"],"Friday after 3","I work on Friday morning, but I'm free after three. On Saturday I visit my family all day."],
  ["Which activity does both Sara and Huda like?","أي نشاط تحبه سارة وهدى؟",["films","running","tennis"],"films","Sara likes films and running. Huda likes films and tennis, but she doesn't like running."],
  ["Which meal has no meat?","أي وجبة بلا لحم؟",["cheese sandwich and salad","chicken soup and bread","rice with chicken"],"cheese sandwich and salad","Menu: cheese sandwich; chicken soup; green salad; chicken and rice."],
  ["Can the customer buy the bag and shoes with $40?","هل يستطيع الزبون شراء الحقيبة والحذاء بـ40 دولاراً؟",["Yes, with $4 left.","No, needs $4 more.","Yes, with $6 left."],"Yes, with $4 left.","Blue bag $14. Black shoes $22. Customer budget: $40."],
  ["What is beside the library?","ما المجاور للمكتبة؟",["the café","the bank","the station"],"the café","Town map note: The café is next to the library. The bank is opposite both. The station is behind the bank."],
  ["Which sign tells people not to use the door?","أي إشارة تمنع الناس من استخدام الباب؟",["NO ENTRY—USE SIDE DOOR","EXIT","OPEN 9–5"],"NO ENTRY—USE SIDE DOOR","Signs: A EXIT. B OPEN 9–5. C NO ENTRY—USE SIDE DOOR."],
  ["Which journey arrives earlier?","أي رحلة تصل أبكر؟",["Route A","Route B","same time"],"Route A","Route A: bus leaves 08:10, arrives 09:00. Route B: train leaves 08:30, arrives 09:15."],
  ["What should the patient do before the appointment?","ماذا ينبغي للمريض أن يفعل قبل الموعد؟",["rest and drink water","take two tablets","go to work"],"rest and drink water","Clinic message: Your appointment is at 3:00. Please rest and drink water. Do not take new medicine before you see the doctor."],
  ["Which clothes fit the forecast?","أي ملابس تناسب التوقع؟",["jacket and umbrella","light shirt only","boots and winter coat for hot sun"],"jacket and umbrella","Forecast: warm morning, then rain and cool wind after 2:00."],
  ["What is happening now?","ماذا يحدث الآن؟",["Mona is waiting for a bus.","Mona is walking home.","Mona is buying a ticket."],"Mona is waiting for a bus.","Message: I'm at the bus stop now. I'm waiting for bus 25. It is ten minutes late."],
  ["Which detail has changed?","أي تفصيل تغير؟",["meeting time","meeting place","activity"],"meeting time","Original: Park Café, Tuesday, 5:00. Update: The café and day are the same, but let's meet at 5:30."],
  ["What must Fadi reply with?","بماذا يجب أن يرد فادي؟",["whether 6:00 works and whether he can bring the map","his favourite food","his phone price"],"whether 6:00 works and whether he can bring the map","Hi Fadi. We're meeting at the station at 6:00 tomorrow. Can you bring the town map? Please confirm the time and the map today."]
];

const assessmentListening=listeningData.map((d,i)=>audio(`A1-FINAL-ASSESS-L${String(i+1).padStart(2,"0")}`,C.EXIT_LISTEN,...d,{assessmentMode:"secure",sourcePolicy:"unseen"}));
const assessmentReading=readingData.map((d,i)=>choice(`A1-FINAL-ASSESS-R${String(i+1).padStart(2,"0")}`,C.EXIT_READ,...d,{assessmentMode:"secure",sourcePolicy:"unseen"}));

export const finalAssessment={
  id:"A1-FINAL-ASSESSMENT",
  title:"A1 Exit Assessment",
  titleAr:"اختبار الخروج من A1",
  status:"summative",
  sourcePolicy:"Secure unseen inputs; do not draw prompts or answer options from practice activities.",
  estimatedMinutes:[45,70],
  sections:{
    listening:{targetEvidencePoints:16,activities:assessmentListening},
    reading:{targetEvidencePoints:16,activities:assessmentReading},
    writing:{targetTasks:2,activities:[
      write("A1-FINAL-ASSESS-W01","writing",C.EXIT_WRITE,"Write 30–50 words to a fictional host: introduce yourself, say where you live, state one preference and ask one question about the visit.","اكتب 30–50 كلمة إلى مضيف خيالي: عرّف بنفسك واذكر أين تسكن وتفضيلاً واحداً واسأل سؤالاً عن الزيارة.","exit-writing-personal-message",[30,50],{assessmentMode:"secure"}),
      write("A1-FINAL-ASSESS-W02","writing",C.EXIT_WRITE,"Write 30–50 words changing a fictional meeting plan. Include the original detail, a reason, the new place or time and a request for confirmation.","اكتب 30–50 كلمة لتغيير خطة لقاء خيالية. اذكر التفصيل الأصلي والسبب والمكان أو الوقت الجديد واطلب التأكيد.","exit-writing-plan-change",[30,50],{assessmentMode:"secure"})
    ]},
    speaking:{targetTasks:4,activities:[
      speak("A1-FINAL-ASSESS-S01","spokenProduction",C.EXIT_SPEAK,"Give your first name or a fictional name, spell it, then say country, city and job or study status.","اذكر اسمك الأول أو اسماً خيالياً وتهجّه، ثم اذكر البلد والمدينة والعمل أو الدراسة.","exit-speaking-personal-profile",{assessmentMode:"secure"}),
      speak("A1-FINAL-ASSESS-S02","spokenInteraction",C.EXIT_INTERACT,"Respond to four short examiner turns: greeting, routine time, preference and simple repair request.","استجب لأربع مداخلات قصيرة: تحية ووقت روتين وتفضيل وطلب إصلاح بسيط.","exit-speaking-short-exchange",{assessmentMode:"secure",examinerTurns:["Good morning.","What time do you start your day?","What do you like doing?","Sorry, please repeat your last answer."]}),
      speak("A1-FINAL-ASSESS-S03","spokenInteraction",C.EXIT_INTERACT,"Role-play one unseen situation: ask for directions, buy a ticket or order a meal; complete at least three interaction turns.","مثّل موقفاً غير مسبوق: اسأل عن اتجاهات أو اشتر تذكرة أو اطلب وجبة، وأكمل ثلاث مداخلات على الأقل.","exit-speaking-situational-interaction",{assessmentMode:"secure",randomScenarioBank:["directions","ticket","meal"]}),
      speak("A1-FINAL-ASSESS-S04","spokenProduction",C.EXIT_SPEAK,"Speak briefly about an unseen weather-and-weekend card: describe now, give a plan and one reason.","تحدث باختصار عن بطاقة طقس وعطلة غير مسبوقة: صف الآن واذكر خطة وسبباً واحداً.","exit-speaking-short-talk",{assessmentMode:"secure"})
    ]},
    mediation:{targetTasks:2,activities:[
      speak("A1-FINAL-ASSESS-M01","mediation",C.EXIT_MEDIATE,"Read a fictional timetable and tell a friend the departure, platform, connection and arrival in simple English.","اقرأ جدولاً خيالياً وانقل لصديق وقت المغادرة والرصيف والتبديل والوصول بإنجليزية بسيطة.","exit-spoken-mediation-travel",{assessmentMode:"secure",sourceCard:"Bus 14—08:00 to Central; Train B—platform 3 at 08:25; arrival 09:10."}),
      write("A1-FINAL-ASSESS-M02","mediation",C.EXIT_MEDIATE,"Write 30–45 words relaying the essential information from a fictional clinic notice: place, time, preparation and one prohibition.","اكتب 30–45 كلمة تنقل المعلومات الأساسية من إشعار عيادة خيالي: المكان والوقت والاستعداد ومنعاً واحداً.","exit-written-mediation-clinic",[30,45],{assessmentMode:"secure",sourceCard:"Clinic B, 2nd floor. Appointment 14:30. Bring ID and water. Do not eat after 13:00."})
    ]}
  },
  scoring:{
    receptive:{method:"item-score",minimumPerSkill:0.6},
    writing:{criteria:["taskCompletion","informationCoverage","comprehensibility","A1Range","A1Accuracy"],minimumTaskCriterionAverage:0.6,bothTasksRequired:true},
    speaking:{criteria:["taskCompletion","intelligibility","appropriateLanguage","interaction"],minimumTaskCriterionAverage:0.6,minimumCompletedTasks:3,accuracyWeight:0.2},
    mediation:{criteria:["essentialInformation","accuracyOfRelay","comprehensibility"],minimumCriterionAverage:0.6},
    decisionRule:{noSingleOverallAverage:true,required:["listening","reading","writing","speaking","mediation"],capstoneMissionRequired:true},
    accessibility:{microphoneFallback:"writing",fallbackDoesNotCreateSpeakingEvidence:true}
  }
};

export const packageData={canDo:C,finalMission,finalAssessment};
