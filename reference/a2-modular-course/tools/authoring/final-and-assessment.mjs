const E={
  listen:"A2.FINAL.LISTENING.INTEGRATED_ROUTINE_INFO",
  read:"A2.FINAL.READING.INTEGRATED_PRACTICAL_TEXTS",
  interact:"A2.FINAL.INTERACTION.MANAGE_ROUTINE_SITUATIONS",
  produce:"A2.FINAL.PRODUCTION.CONNECT_SHORT_DESCRIPTION",
  write:"A2.FINAL.WRITING.CONNECTED_PRACTICAL_TEXT",
  mediate:"A2.FINAL.MEDIATION.RELAY_PRACTICAL_INFORMATION",
  action:"A2.FINAL.ACTION.HOST_VISITOR"
};

const rubrics={
  speaking:["taskCompletion","intelligibility","appropriateLanguage","interaction","accuracy"],
  production:["taskCompletion","organisation","intelligibility","appropriateLanguage","accuracy"],
  writing:["taskCompletion","clarity","organisation","appropriateLanguage","accuracy"],
  mediation:["selectRelevantInformation","clarity","audienceAwareness","accuracy"]
};

const choice=(id,skill,canDo,source,prompt,promptAr,options,answer)=>({
  id,lessonId:"A2-FINAL-MISSION",type:skill==="listening"?"audioChoice":"textChoice",mode:"mastery",skill,canDo,
  ...(skill==="listening"?{audioTranscript:source}:{sourceText:source}),prompt,promptAr,options,answer
});
const performance=(id,skill,canDo,prompt,promptAr,evaluation,wordGuide)=>({
  id,lessonId:"A2-FINAL-MISSION",type:skill==="writing"?"write":"speak",mode:"mastery",skill,canDo,prompt,promptAr,evaluation,accepted:[],
  ...(wordGuide?{wordGuide}:{}),...(["spokenInteraction","spokenProduction","mediation"].includes(skill)?{fallbackSkill:"writing",fallbackCountsFor:"accessOnly"}:{})
});

export const finalCanDo={
  listen:{id:E.listen,descriptor:"Can understand the essential point and selected details in clear, short A2-level practical speech.",descriptorAr:"يفهم الفكرة الأساسية وتفاصيل مختارة في كلام عملي قصير وواضح بمستوى A2.",skills:["listening"],level:"A2"},
  read:{id:E.read,descriptor:"Can locate and connect relevant information across short practical A2 texts.",descriptorAr:"يعثر على المعلومات ذات الصلة ويربطها عبر نصوص عملية قصيرة بمستوى A2.",skills:["reading"],level:"A2"},
  interact:{id:E.interact,descriptor:"Can manage routine exchanges, ask follow-up questions and negotiate a simple solution.",descriptorAr:"يدير تبادلات روتينية ويسأل أسئلة متابعة ويتفاوض على حل بسيط.",skills:["spokenInteraction"],level:"A2"},
  produce:{id:E.produce,descriptor:"Can give a connected short description or account with simple reasons and sequencing.",descriptorAr:"يقدم وصفاً أو رواية قصيرة مترابطة مع أسباب وتسلسل بسيطين.",skills:["spokenProduction"],level:"A2"},
  write:{id:E.write,descriptor:"Can write a connected practical message or narrative of roughly 80–120 words.",descriptorAr:"يكتب رسالة عملية أو سرداً مترابطاً من نحو 80–120 كلمة.",skills:["writing"],level:"A2"},
  mediate:{id:E.mediate,descriptor:"Can relay the main point and essential practical details of simple texts, instructions and plans.",descriptorAr:"ينقل الفكرة الرئيسية والتفاصيل العملية الأساسية من نصوص وتعليمات وخطط بسيطة.",skills:["mediation"],level:"A2"},
  action:{id:E.action,descriptor:"Can host a visitor by planning, explaining and solving routine practical problems.",descriptorAr:"يستضيف زائراً عبر التخطيط والشرح وحل المشكلات العملية الروتينية.",skills:["listening","reading","spokenInteraction","spokenProduction","writing","mediation"],level:"A2"}
};

export const finalMission={
  id:"A2-FINAL-MISSION",title:"Host a Visitor",titleAr:"استضافة زائر",levelRole:"level-capstone",lessonType:"mission",estimatedMinutes:[35,50],
  scenario:"A friend is visiting for two days. Build the plan from new messages and notices, explain the neighbourhood, handle food, health and technology problems, then write a follow-up.",
  canDo:Object.values(E),prerequisites:["A2-U1","A2-U2","A2-U3","A2-U4","A2-U5","A2-U6","A2-U7","A2-U8","A2-U9","A2-U10","A2-U11","A2-U12"],
  activities:[
    choice("A2-FINAL-MISSION-A01","reading",[E.read,E.action],"Visitor message: I arrive Friday at 17:40. I prefer a quiet room, cannot eat nuts, and need reliable Wi-Fi for a meeting Saturday at 09:00. I leave Sunday at 16:15.","Which three needs affect the plan?","ما الاحتياجات الثلاثة التي تؤثر في الخطة؟",["Quiet room, nut-free food, reliable Wi-Fi","Late breakfast, a car, live music","A large party, seafood, no internet"],"Quiet room, nut-free food, reliable Wi-Fi"),
    choice("A2-FINAL-MISSION-A02","reading",[E.read,E.action],"Neighbourhood notice: The west bus stop is closed this weekend. Use the library stop instead. The pharmacy closes at 18:00 on Saturday; the urgent-care centre is open until 22:00.","Where should the visitor take the bus?","من أين ينبغي للزائر ركوب الحافلة؟",["The library stop","The west stop","The pharmacy"],"The library stop"),
    choice("A2-FINAL-MISSION-A03","listening",[E.listen,E.action],"Your train is delayed by twenty-five minutes and will now arrive at eighteen oh five. The platform is unchanged.","What is the revised arrival time?","ما وقت الوصول المعدل؟",["18:05","17:40","18:25"],"18:05"),
    choice("A2-FINAL-MISSION-A04","listening",[E.listen,E.action],"The café can prepare the vegetable dish without nuts, but you must order it before noon because the evening kitchen is very busy.","What condition applies to the nut-free dish?","ما الشرط المتعلق بالطبق الخالي من المكسرات؟",["Order it before noon","Collect it after midnight","Choose a meat dish"],"Order it before noon"),
    performance("A2-FINAL-MISSION-A05","spokenInteraction",[E.interact,E.action],"Welcome the visitor, confirm arrival and departure details, and ask at least three connected questions about needs or preferences.","رحّب بالزائر وأكد تفاصيل الوصول والمغادرة واسأل ثلاثة أسئلة مترابطة على الأقل عن الاحتياجات أو التفضيلات.",rubrics.speaking),
    performance("A2-FINAL-MISSION-A06","spokenInteraction",[E.interact,E.action],"Role-play one problem: the restaurant order is unsafe, the Wi-Fi fails before the meeting, or the visitor feels unwell. Clarify the problem and agree on a practical solution using the supplied facts.","مثّل مشكلة واحدة: الطلب غير آمن أو تعطل الواي فاي قبل الاجتماع أو شعر الزائر بالتعب. وضّح المشكلة واتفق على حل عملي مستخدماً الحقائق المقدمة.",rubrics.speaking),
    performance("A2-FINAL-MISSION-A07","spokenProduction",[E.produce,E.action],"Present the two-day itinerary in a clear order. Include transport, two activities, food arrangements and one Plan B.","قدّم برنامج اليومين بترتيب واضح. ضمّن النقل ونشاطين وترتيبات الطعام وخطة بديلة واحدة.",rubrics.production),
    performance("A2-FINAL-MISSION-A08","spokenProduction",[E.produce,E.action],"Describe the neighbourhood to the visitor, comparing two areas and explaining the location of four useful services.","صف الحي للزائر وقارن منطقتين واشرح موقع أربع خدمات مفيدة.",rubrics.production),
    performance("A2-FINAL-MISSION-A09","mediation",[E.mediate,E.action],"Relay the revised train time, unchanged platform and replacement bus stop from the notices. Preserve all numbers exactly.","انقل وقت القطار المعدل ورقم الرصيف غير المتغير ومحطة الحافلة البديلة من الإشعارات. حافظ على جميع الأرقام بدقة.",rubrics.mediation),
    performance("A2-FINAL-MISSION-A10","mediation",[E.mediate,E.action],"Relay the visitor's food need and the café's ordering condition to another person without adding medical or dietary claims.","انقل حاجة الزائر الغذائية وشرط الطلب في المقهى إلى شخص آخر من دون إضافة ادعاءات طبية أو غذائية.",rubrics.mediation),
    performance("A2-FINAL-MISSION-A11","writing",[E.write,E.action],"Write the visitor the final practical plan: arrival, transport change, accommodation, activities, food arrangement and what to do if Wi-Fi fails.","اكتب للزائر الخطة العملية النهائية: الوصول وتغيير النقل والإقامة والأنشطة وترتيب الطعام وما ينبغي فعله إذا تعطل الواي فاي.",rubrics.writing,[90,120]),
    performance("A2-FINAL-MISSION-A12","writing",[E.write,E.action],"After the visit, write a friendly follow-up message. Mention two past events, one opinion, thanks and a future invitation.","بعد الزيارة اكتب رسالة متابعة ودودة. اذكر حدثين ماضيين ورأياً واحداً وشكراً ودعوة مستقبلية.",rubrics.writing,[80,110])
  ],
  mastery:{requiredObjectives:Object.values(E),requiredSkillGroups:[["listening","reading"],["spokenInteraction","spokenProduction","writing"],["mediation"]],minimumObjectiveScore:.75,minimumEvidencePerObjective:2,productiveEvidenceRequired:true,practiceCounts:false,retry:"targeted-by-objective"}
};

const objectivePool={
  travel:"A2.U6.INTERACTION.BOOK_CHANGE_TRAVEL",health:"A2.U7.LISTENING.UNDERSTAND_HEALTH_ADVICE",tech:"A2.U9.LISTENING.UNDERSTAND_TECH_INSTRUCTIONS",story:"A2.U10.READING.FOLLOW_STORY_REVIEW",weather:"A2.U11.LISTENING.UNDERSTAND_WEATHER_PROBLEM",event:"A2.U12.READING.FOLLOW_INVITATION_MESSAGE",work:"A2.U8.READING.FOLLOW_COURSE_JOB_TEXT",food:"A2.U5.INTERACTION.MANAGE_FOOD_SERVICE",home:"A2.U4.READING.COMPARE_HOUSING",people:"A2.U3.LISTENING.UNDERSTAND_PERSON_DESCRIPTION",past:"A2.U2.READING.FOLLOW_SHORT_NARRATIVE",life:"A2.U1.LISTENING.UNDERSTAND_LIFE_UPDATE"
};

const promptAr={
  "What changed?":"ما الذي تغير؟",
  "When is the tablet taken?":"متى يُتناول القرص؟",
  "What should happen before restarting?":"ماذا ينبغي فعله قبل إعادة التشغيل؟",
  "Why does the game start earlier?":"لماذا تبدأ المباراة مبكراً؟",
  "What does the speaker request?":"ماذا يطلب المتحدث؟",
  "What number appears on the bill?":"ما الرقم الظاهر في الفاتورة؟",
  "Which home is quieter?":"أي منزل أكثر هدوءاً؟",
  "What is Leila's strongest stated quality?":"ما أقوى صفة مذكورة لليلى؟",
  "What were they doing when help arrived?":"ماذا كانوا يفعلون عندما وصلت المساعدة؟",
  "What is temporary?":"ما الأمر المؤقت؟",
  "What is included?":"ما الذي هو مشمول؟",
  "Which point is least positive?":"أي نقطة هي الأقل إيجابية؟",
  "Where is the alternative meeting point?":"أين نقطة اللقاء البديلة؟",
  "What will be changed?":"ما الذي سيتغير؟",
  "When did the cough start?":"متى بدأ السعال؟",
  "When should the fog clear?":"متى ينبغي أن ينقشع الضباب؟",
  "When are the vegetables added?":"متى تُضاف الخضروات؟",
  "Which ability is required?":"أي قدرة مطلوبة؟",
  "Which option has more bedrooms?":"أي خيار فيه غرف نوم أكثر؟",
  "Which option is more flexible?":"أي خيار أكثر مرونة؟",
  "What must the patient bring?":"ماذا يجب على المريض أن يحضر؟",
  "What is the first step?":"ما الخطوة الأولى؟",
  "Who is the suggested audience?":"من الجمهور المقترح؟",
  "What remains unchanged?":"ما الذي بقي من دون تغيير؟",
  "Which entrance should visitors use?":"أي مدخل ينبغي للزوار استخدامه؟",
  "How many people does it serve?":"كم شخصاً تكفي؟",
  "Who better matches the stated duty?":"من الأنسب للواجب المذكور؟",
  "What happened second?":"ماذا حدث ثانياً؟",
  "Why is the writer using the library?":"لماذا يستخدم الكاتب المكتبة؟",
  "What is not required?":"ما الذي ليس مطلوباً؟",
  "Which bus is realistically available after bag collection?":"أي حافلة متاحة واقعياً بعد استلام الأمتعة؟",
  "When should emergency services be used?":"متى ينبغي استخدام خدمات الطوارئ؟",
  "What should a user do after link failure?":"ماذا ينبغي للمستخدم أن يفعل بعد فشل الرابط؟",
  "What is the purpose of the message?":"ما غرض الرسالة؟",
  "When are showers possible?":"متى يحتمل هطول زخات؟"
};
const ac=(id,skill,obj,source,prompt,options,answer)=>({id,type:skill==="listening"?"audioChoice":"textChoice",section:skill,skill,mode:"assessment",canDo:[obj],...(skill==="listening"?{audioTranscript:source}:{sourceText:source}),prompt,promptAr:promptAr[prompt]||prompt,options,answer});

const listeningData=[
  [objectivePool.travel,"The 12:20 train now leaves at 12:50 from platform four.","What changed?",["The departure time","The platform","The destination"],"The departure time"],
  [objectivePool.health,"Take one tablet after dinner. Do not take a second tablet before morning.","When is the tablet taken?",["After dinner","Before breakfast","Twice at night"],"After dinner"],
  [objectivePool.tech,"If the screen freezes, save your work before you restart the computer.","What should happen before restarting?",["Save the work","Delete the file","Turn off the network"],"Save the work"],
  [objectivePool.weather,"Rain is likely after five, so the football game will begin an hour earlier at three.","Why does the game start earlier?",["Rain is likely later","The field is closed now","The players arrive late"],"Rain is likely later"],
  [objectivePool.event,"I'd love to come, but I finish work at eight. Could I join for the last hour?", "What does the speaker request?",["To join late","To cancel the event","To change jobs"],"To join late"],
  [objectivePool.food,"We ordered four soups, but only three arrived, and the bill lists five.","What number appears on the bill?",["Five","Four","Three"],"Five"],
  [objectivePool.home,"The flat is cheaper and closer to work, but the house is quieter and has more space.","Which home is quieter?",["The house","The flat","Both"],"The house"],
  [objectivePool.people,"Leila is less experienced than Samir, but she is the most organised candidate.","What is Leila's strongest stated quality?",["Organisation","Experience","Age"],"Organisation"],
  [objectivePool.past,"We were walking to the station when a neighbour offered us a lift.","What were they doing when help arrived?",["Walking to the station","Waiting on a train","Driving a car"],"Walking to the station"],
  [objectivePool.life,"I normally work mornings, but this month I am taking the evening shift.","What is temporary?",["The evening shift","Having a job","Working every month"],"The evening shift"],
  [objectivePool.work,"The course meets Tuesday and Thursday. Materials are included, but transport is not.","What is included?",["Materials","Transport","Meals"],"Materials"],
  [objectivePool.story,"Although the plot was simple, the characters were moving and the ending was excellent.","Which point is least positive?",["The simple plot","The characters","The ending"],"The simple plot"],
  [objectivePool.travel,"If the boat is cancelled, meet the guide at the museum entrance at ten.","Where is the alternative meeting point?",["The museum entrance","The boat office","The hotel"],"The museum entrance"],
  [objectivePool.tech,"Open settings, choose notifications, and turn off the sound for this app only.","What will be changed?",["One app's notification sound","All phone audio","The network password"],"One app's notification sound"],
  [objectivePool.health,"I've had the cough since Friday, and it became worse last night.","When did the cough start?",["Friday","Last night","This morning"],"Friday"],
  [objectivePool.event,"Because the hall is unavailable, the workshop will take place online. The date and time are unchanged.","What changed?",["The format or place","The date","The time"],"The format or place"],
  [objectivePool.weather,"There might be fog early, but it should clear before the buses leave at nine.","When should the fog clear?",["Before nine","After the buses return","At midday only"],"Before nine"],
  [objectivePool.food,"First chop the vegetables. Then heat the oil, and add the vegetables only when it is hot.","When are the vegetables added?",["After the oil is hot","Before chopping","Before heating the oil"],"After the oil is hot"]
];

const readingData=[
  [objectivePool.work,"Library assistant needed: Saturdays 10–2. Must be able to use email and speak clearly to visitors. Apply by 9 March.","Which ability is required?",["Using email","Driving","Cooking"],"Using email"],
  [objectivePool.home,"Flat A: $480, one bedroom, near buses. Flat B: $530, two bedrooms, no late buses.","Which option has more bedrooms?",["Flat B","Flat A","Both"],"Flat B"],
  [objectivePool.travel,"City Hotel includes breakfast and free cancellation until Thursday. River Rooms is cheaper but bookings cannot be changed.","Which option is more flexible?",["City Hotel","River Rooms","Both"],"City Hotel"],
  [objectivePool.health,"Clinic note: arrive fifteen minutes early and bring your medicine list. You do not need to bring the medicine itself.","What must the patient bring?",["A medicine list","Every medicine","Food"],"A medicine list"],
  [objectivePool.tech,"To reset the app, first save a backup. Next sign out, update the app and sign in again. Never send your password to support.","What is the first step?",["Save a backup","Sign in","Send the password"],"Save a backup"],
  [objectivePool.story,"Review: A warm comedy with excellent actors. The middle is a little slow, but the final scene is very funny. Recommended for families.","Who is the suggested audience?",["Families","Only sports fans","Young children alone"],"Families"],
  [objectivePool.event,"Update: Sunday's picnic begins at noon instead of eleven. The location and food plan are unchanged. Please confirm by Friday.","What remains unchanged?",["Location and food plan","Start time","Reply deadline"],"Location and food plan"],
  [objectivePool.weather,"Path closed after storm damage. Use the north entrance and stay on the marked route. The visitor centre remains open.","Which entrance should visitors use?",["North","The closed path","South"],"North"],
  [objectivePool.food,"Tomato rice serves four: 300 g rice, six tomatoes, a little oil. Boil the rice, cook the tomatoes, then mix them.","How many people does it serve?",["Four","Six","Three"],"Four"],
  [objectivePool.people,"Candidate A is the most experienced. Candidate B is more organised and available every day. The role needs daily record-keeping.","Who better matches the stated duty?",["Candidate B","Candidate A","Neither"],"Candidate B"],
  [objectivePool.past,"First we missed the bus. Then a driver showed us a shorter route, and finally we arrived before the office closed.","What happened second?",["A driver showed a shorter route","They missed the bus","The office closed"],"A driver showed a shorter route"],
  [objectivePool.life,"I usually study at home, but this week I am using the college library because my building is noisy.","Why is the writer using the library?",["The building is noisy","The writer always studies there","The college is closed"],"The building is noisy"],
  [objectivePool.work,"Evening design course: practical projects, Tuesday and Thursday, $120 including software access. No previous qualification required.","What is not required?",["A previous qualification","Attendance twice weekly","The fee"],"A previous qualification"],
  [objectivePool.travel,"Flight arrives 14:30. Airport bus departs 14:45 and 15:15. Collecting bags usually takes twenty minutes.","Which bus is realistically available after bag collection?",["15:15","14:45","Neither"],"15:15"],
  [objectivePool.health,"If the pain gets worse or you develop a fever, call the clinic. For urgent breathing problems, use emergency services.","When should emergency services be used?",["For urgent breathing problems","For every mild pain","To change an appointment"],"For urgent breathing problems"],
  [objectivePool.tech,"Meeting access: use your personal link once. If it fails, request a new link from the organiser. Do not post either link publicly.","What should a user do after link failure?",["Request a new link","Post the old link","Share the password"],"Request a new link"],
  [objectivePool.event,"Thanks for the invitation. Unfortunately, I am away that weekend, so I cannot attend. I hope to join the next event.","What is the purpose of the message?",["To decline politely","To change the venue","To accept immediately"],"To decline politely"],
  [objectivePool.weather,"Forecast: dry morning, showers possible after 14:00, strong wind from 18:00. Outdoor stalls must close if wind reaches the warning level.","When are showers possible?",["After 14:00","Only in the morning","After 18:00 only"],"After 14:00"]
];

const listening=listeningData.map((x,i)=>ac(`A2-FA-LISTEN-${String(i+1).padStart(2,"0")}`,"listening",...x));
const reading=readingData.map((x,i)=>ac(`A2-FA-READ-${String(i+1).padStart(2,"0")}`,"reading",...x));
const perf=(id,section,skill,canDo,prompt,promptAr,evaluation,wordGuide)=>({id,type:skill==="writing"?"write":"speak",section,skill,mode:"assessment",canDo,prompt,promptAr,evaluation,accepted:[],...(wordGuide?{wordGuide}:{}),...(["spokenInteraction","spokenProduction","mediation"].includes(skill)?{fallbackSkill:"writing",fallbackCountsFor:"accessOnly"}:{})});

const writing=[
  perf("A2-FA-WRITE-01","writing","writing",[E.write],"Write an 80–120-word message to a friend about a recent day out: what happened, one unexpected event, your opinion and a future plan.","اكتب رسالة من 80–120 كلمة إلى صديق عن نزهة قريبة: ما حدث وحدث واحد غير متوقع ورأيك وخطة مستقبلية.",rubrics.writing,[80,120]),
  perf("A2-FA-WRITE-02","writing","writing",[E.write],"Write an 80–120-word practical event update after the venue changes. Include apology, reason, new place and time, one task and a reply request.","اكتب تحديث فعالية عملياً من 80–120 كلمة بعد تغيير المكان. ضمّن اعتذاراً وسبباً والمكان والوقت الجديدين ومهمة وطلب رد.",rubrics.writing,[80,120])
];
const speaking=[
  perf("A2-FA-SPEAK-01","speaking","spokenInteraction",[E.interact],"Answer personal follow-up questions about your current life, recent past and next weekend, then ask two questions back.","أجب عن أسئلة متابعة شخصية حول حياتك الحالية وماضٍ قريب وعطلة الأسبوع القادمة ثم اسأل سؤالين بالمقابل.",rubrics.speaking),
  perf("A2-FA-SPEAK-02","speaking","spokenInteraction",[E.interact],"Role-play a routine service problem: explain the issue, clarify details and agree on a solution.","مثّل مشكلة خدمة روتينية: اشرح المشكلة ووضّح التفاصيل واتفق على حل.",rubrics.speaking),
  perf("A2-FA-SPEAK-03","speaking","spokenProduction",[E.produce],"Compare two supplied options and recommend one for a stated person's needs, giving at least two reasons.","قارن خيارين معروضين وأوصِ بأحدهما لاحتياجات شخص محدد مع سببين على الأقل.",rubrics.production),
  perf("A2-FA-SPEAK-04","speaking","spokenProduction",[E.produce],"Tell a connected short story from four picture prompts using background, sequence, an interruption and an ending.","احك قصة قصيرة مترابطة من أربع صور مستخدماً الخلفية والتسلسل والمقاطعة والنهاية.",rubrics.production)
];
const mediation=[
  perf("A2-FA-MEDIATE-01","mediation","mediation",[E.mediate],"Relay the essential date, time, place, change and required action from a short notice to a friend.","انقل التاريخ والوقت والمكان والتغيير والإجراء المطلوب من إشعار قصير إلى صديق.",rubrics.mediation),
  perf("A2-FA-MEDIATE-02","mediation","mediation",[E.mediate],"Read two simple options and relay the relevant differences for a person with stated cost, access and schedule needs.","اقرأ خيارين بسيطين وانقل الاختلافات ذات الصلة لشخص لديه احتياجات محددة في التكلفة والوصول والجدول.",rubrics.mediation)
];

export const finalAssessment={
  id:"A2-FINAL-ASSESSMENT",title:"A2 Independent Final Assessment",titleAr:"الاختبار النهائي المستقل لمستوى A2",version:"1.0.0",itemPolicy:"unseen-items-not-reused-from-learning-or-missions",estimatedMinutes:[65,90],
  sections:{listening:{items:listening,scoring:"objective"},reading:{items:reading,scoring:"objective"},writing:{items:writing,scoring:"analytic-rubric"},speaking:{items:speaking,scoring:"analytic-rubric"},mediation:{items:mediation,scoring:"analytic-rubric"}},
  exitRule:{minimumPerObjective:.75,weakObjectiveCannotBeHiddenByAverage:true,productiveEvidenceRequired:true,receptiveEvidenceRequired:true,mediationEvidenceRequired:true,finalMissionRequired:true,nativeAccentRequired:false,speechPriority:["taskCompletion","intelligibility","appropriateLanguage","interaction","accuracy"],accuracyWeight:.2},
  counts:{listening:listening.length,reading:reading.length,writing:writing.length,speaking:speaking.length,mediation:mediation.length,total:listening.length+reading.length+writing.length+speaking.length+mediation.length}
};
