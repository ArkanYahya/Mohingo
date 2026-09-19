const pad=n=>String(n).padStart(2,"0");
export const gId=slug=>`A2.G.${slug}`;
export const lId=slug=>`A2.LEX.${slug}`;
export const hId=slug=>`A2.CHUNK.${slug}`;

export function recordsFor(spec){
  const grammar=spec.grammar.map(x=>({id:gId(x[0]),form:x[1],meaningAr:x[2],introducedIn:`${spec.id}-L${x[3]}`,examples:[{en:x[4],ar:x[5]}],...(x[6]||{})}));
  const lexicon=spec.lexicon.map(x=>({id:lId(x[0]),headword:x[1],partOfSpeech:x[2],arabic:x[3],cefr:"A2",receptive:true,productive:x[7]??true,meaning:x[8]||x[1],examples:[{en:x[5],ar:x[6]}],introducedIn:`${spec.id}-L${x[4]}`,recycledIn:x[9]||[]}));
  const chunks=spec.chunks.map(x=>({id:hId(x[0]),text:x[1],arabic:x[2],cefr:"A2",introducedIn:`${spec.id}-L${x[3]}`,productive:x[4]??true,recycledIn:x[5]||[]}));
  return {grammar,lexicon,chunks};
}

const choice=(id,lessonId,mode,skill,canDo,item)=>({id,lessonId,type:skill==="listening"?"audioChoice":"textChoice",mode,skill,canDo,prompt:item.prompt,promptAr:item.promptAr,options:item.options,answer:item.answer,...(skill==="listening"?{audioTranscript:item.source}:{sourceText:item.source})});
const practice=(id,lessonId,canDo,item)=>item.type==="order"
  ?{id,lessonId,type:"order",mode:"practice",skill:item.skill||"reading",canDo,prompt:item.prompt,promptAr:item.promptAr,tokens:item.tokens,answer:item.answer}
  :{id,lessonId,type:"gap",mode:"practice",skill:item.skill||"reading",canDo,prompt:item.prompt,promptAr:item.promptAr,text:item.text,options:item.options,answer:item.answer};

function buildLesson(spec,index,lesson,records,objectives){
  const id=`${spec.id}-L${index}`;
  const skill=lesson.inputSkill||"listening";
  const masterySkill=lesson.masterySkill||skill;
  const pairs=(lesson.lex||[]).slice(0,3).map(slug=>{const record=records.lexicon.find(x=>x.id===lId(slug));return [record?.headword||slug,record?.arabic||slug];});
  const canDo=lesson.canDo.map(k=>objectives[k]);
  const prodCanDo=(lesson.production.canDo||lesson.canDo).map(k=>objectives[k]);
  return {id,title:lesson.title,titleAr:lesson.titleAr,lessonType:index===6?"integrated-production":"encounter-focus-practice",canDo,grammar:(lesson.grammar||[]).map(gId),lexicon:(lesson.lex||[]).map(lId),chunks:(lesson.chunks||[]).map(hId),encounter:{dialogue:[{speaker:lesson.speaker||"Narrator",en:lesson.input.source,ar:lesson.input.translationAr}]},activities:[
    choice(`${id}-A01`,id,"encounter",skill,canDo,lesson.input),
    {id:`${id}-A02`,lessonId:id,type:"match",mode:"practice",skill:"reading",canDo,prompt:"Match the key language to its Arabic meaning.",promptAr:"طابق اللغة الأساسية بمعناها العربي.",pairs},
    practice(`${id}-A03`,id,canDo,lesson.practice),
    choice(`${id}-A04`,id,"mastery",masterySkill,canDo,lesson.mastery),
    {id:`${id}-A05`,lessonId:id,type:lesson.production.skill==="writing"?"write":"speak",mode:"mastery",skill:lesson.production.skill,canDo:prodCanDo,prompt:lesson.production.prompt,promptAr:lesson.production.promptAr,evaluation:lesson.production.evaluation,accepted:[],...(lesson.production.wordGuide?{wordGuide:lesson.production.wordGuide}:{}),...(["spokenInteraction","spokenProduction","mediation"].includes(lesson.production.skill)?{fallbackSkill:"writing",fallbackCountsFor:"accessOnly"}:{})}
  ]};
}

export function buildUnit(spec){
  const records=recordsFor(spec);
  const objectives=Object.fromEntries(Object.entries(spec.objectives).map(([key,value])=>[key,`A2.${spec.id.split("-")[1]}.${value}`]));
  const lessons=spec.lessons.map((lesson,index)=>buildLesson(spec,index+1,lesson,records,objectives));
  const missionId=`${spec.id}-L7`,m=spec.mission;
  lessons.push({id:missionId,title:`Mission: ${m.title}`,titleAr:`المهمة: ${m.titleAr}`,lessonType:"mission",canDo:Object.values(objectives),grammar:[],lexicon:[],chunks:[],scenario:m.scenario,activities:[
    {...choice(`${missionId}-A01`,missionId,"mastery","reading",[objectives.read,objectives.mission],m.reading)},
    {...choice(`${missionId}-A02`,missionId,"mastery","listening",[objectives.listen,objectives.mission],m.audio)},
    {id:`${missionId}-A03`,lessonId:missionId,type:"speak",mode:"mastery",skill:"spokenInteraction",canDo:[objectives.interact,objectives.mission],prompt:m.interaction.prompt,promptAr:m.interaction.promptAr,evaluation:m.interaction.evaluation,accepted:[],fallbackSkill:"writing",fallbackCountsFor:"accessOnly"},
    {id:`${missionId}-A04`,lessonId:missionId,type:"speak",mode:"mastery",skill:"spokenProduction",canDo:[objectives.produce,objectives.mission],prompt:m.production.prompt,promptAr:m.production.promptAr,evaluation:m.production.evaluation,accepted:[],fallbackSkill:"writing",fallbackCountsFor:"accessOnly"},
    {id:`${missionId}-A05`,lessonId:missionId,type:"speak",mode:"mastery",skill:"mediation",canDo:[objectives.mediate,objectives.mission],prompt:m.mediation.prompt,promptAr:m.mediation.promptAr,evaluation:m.mediation.evaluation,accepted:[],fallbackSkill:"writing",fallbackCountsFor:"accessOnly"},
    {id:`${missionId}-A06`,lessonId:missionId,type:"write",mode:"mastery",skill:"writing",canDo:[objectives.write,objectives.mission],prompt:m.writing.prompt,promptAr:m.writing.promptAr,evaluation:m.writing.evaluation,wordGuide:m.writing.wordGuide,accepted:[]}
  ]});
  return {canDo:objectives,records,unit:{id:spec.id,title:spec.title,titleAr:spec.titleAr,levelRole:"core",estimatedMinutes:[95,130],countsTowardA2Mastery:true,recycleFrom:spec.recycleFrom,lessons,mastery:{requiredObjectives:Object.values(objectives),requiredSkillGroups:[["listening","reading"],["spokenInteraction","spokenProduction","writing"],["mediation"]],minimumObjectiveScore:.75,minimumEvidencePerObjective:2,missionRequired:true,retry:"targeted-by-objective",unlocks:spec.unlocks}}};
}

export const I=(...args)=>{
  const [source,translationAr,prompt,promptAr,options,answer]=args.length===5
    ?[args[0],"",args[1],args[2],args[3],args[4]]
    :args;
  return {source,translationAr,prompt,promptAr,options,answer};
};
export const P=(text,options,answer,prompt="Complete the sentence.",promptAr="أكمل الجملة.")=>({type:"gap",text,options,answer,prompt,promptAr});
export const O=(tokens,answer,prompt="Put the language in the best order.",promptAr="رتب اللغة بالترتيب الأفضل.")=>({type:"order",tokens,answer,prompt,promptAr});
export const R=(source,prompt,promptAr,options,answer)=>({source,translationAr:"",prompt,promptAr,options,answer});
export const Prod=(skill,prompt,promptAr,evaluation,wordGuide,canDo)=>({skill,prompt,promptAr,evaluation,wordGuide,canDo});
