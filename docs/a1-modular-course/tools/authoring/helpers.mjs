export const grammarRecord=(id,form,meaningAr,introducedIn,exampleEn,exampleAr,extra={})=>({id,form,meaningAr,introducedIn,examples:exampleEn?[{en:exampleEn,ar:exampleAr}]:[],...extra});
export const lexicalRecord=(id,headword,partOfSpeech,arabic,introducedIn,example,recycledIn=[],productive=true,meaning=headword)=>({id,headword,partOfSpeech,arabic,cefr:"A1",receptive:true,productive,meaning,examples:[example],introducedIn,recycledIn});
export const chunkRecord=(id,text,arabic,introducedIn,recycledIn=[],productive=true)=>({id,text,arabic,cefr:"A1",introducedIn,productive,recycledIn});

const audioChoice=(id,lessonId,mode,canDo,item)=>({id,lessonId,type:"audioChoice",mode,skill:"listening",canDo,prompt:item.prompt,promptAr:item.promptAr,options:item.options,answer:item.answer,audioTranscript:item.transcript,...(item.extra||{})});
const textChoice=(id,lessonId,mode,skill,canDo,item)=>({id,lessonId,type:"textChoice",mode,skill,canDo,prompt:item.prompt,promptAr:item.promptAr,options:item.options,answer:item.answer,...(item.extra||{})});
const practiceActivity=(id,lessonId,canDo,item)=>{
  if(item.type==="match")return {id,lessonId,type:"match",mode:"practice",skill:item.skill||"reading",canDo,prompt:item.prompt,promptAr:item.promptAr,pairs:item.pairs};
  if(item.type==="order")return {id,lessonId,type:"order",mode:"practice",skill:item.skill||"reading",canDo,prompt:item.prompt,promptAr:item.promptAr,tokens:item.tokens,answer:item.answer};
  if(item.type==="gap")return {id,lessonId,type:"gap",mode:"practice",skill:item.skill||"reading",canDo,prompt:item.prompt,promptAr:item.promptAr,text:item.text,options:item.options,answer:item.answer};
  return textChoice(id,lessonId,"practice",item.skill||"reading",canDo,item);
};
const production=(id,lessonId,canDo,item)=>({id,lessonId,type:item.skill==="writing"?"write":item.type||"speak",mode:"mastery",skill:item.skill||"spokenProduction",canDo,prompt:item.prompt,promptAr:item.promptAr,accepted:item.accepted||[],evaluation:item.evaluation,fallbackSkill:item.fallbackSkill,...(item.wordGuide?{wordGuide:item.wordGuide}:{}),...(item.fields?{fields:item.fields}:{})});

export function buildLesson(unitId,index,spec){
  const id=`${unitId}-L${index}`;
  const encounterSkill=spec.encounterCheck.skill||"listening";
  return {
    id,title:spec.title,titleAr:spec.titleAr,lessonType:spec.lessonType||"encounter-focus-practice",
    canDo:spec.canDo,grammar:spec.grammar||[],lexicon:spec.lexicon||[],chunks:spec.chunks||[],
    ...(spec.pedagogyNote?{pedagogyNote:spec.pedagogyNote}:{}),
    ...(spec.encounter?{encounter:spec.encounter}:{}),
    ...(spec.readingText?{readingText:spec.readingText}:{}),
    activities:[
      encounterSkill==="listening"?audioChoice(`${id}-A01`,id,"encounter",spec.encounterCheck.canDo||spec.canDo,spec.encounterCheck):textChoice(`${id}-A01`,id,"encounter",encounterSkill,spec.encounterCheck.canDo||spec.canDo,spec.encounterCheck),
      practiceActivity(`${id}-A02`,id,spec.practice1.canDo||spec.canDo,spec.practice1),
      practiceActivity(`${id}-A03`,id,spec.practice2.canDo||spec.canDo,spec.practice2),
      audioChoice(`${id}-A04`,id,"mastery",spec.masteryListen.canDo||spec.canDo,spec.masteryListen),
      production(`${id}-A05`,id,spec.production.canDo||spec.canDo,spec.production)
    ]
  };
}

export function buildUnit(spec){
  const lessons=spec.lessons.map((lesson,index)=>buildLesson(spec.id,index+1,lesson));
  const missionId=`${spec.id}-L7`;
  lessons.push({id:missionId,title:spec.mission.title,titleAr:spec.mission.titleAr,lessonType:"mission",canDo:spec.mission.canDo,grammar:[],lexicon:[],chunks:[],scenario:spec.mission.scenario,...(spec.mission.privacyNote?{privacyNote:spec.mission.privacyNote}:{}),activities:spec.mission.activities.map((a,index)=>({id:`${missionId}-A${String(index+1).padStart(2,"0")}`,lessonId:missionId,mode:"mastery",...a}))});
  return {id:spec.id,title:spec.title,titleAr:spec.titleAr,levelRole:"core",estimatedMinutes:spec.estimatedMinutes||[80,110],countsTowardA1Mastery:true,lessons,mastery:{requiredObjectives:spec.requiredObjectives,requiredSkillGroups:[["listening","reading"],["spokenInteraction","spokenProduction","writing"],["mediation"]],minimumObjectiveScore:0.75,missionRequired:true,retry:"targeted-by-objective",unlocks:spec.unlocks}};
}

export const missionAudio=(canDo,prompt,promptAr,options,answer,transcript,extra={})=>({type:"audioChoice",skill:"listening",canDo,prompt,promptAr,options,answer,audioTranscript:transcript,...extra});
export const missionChoice=(skill,canDo,prompt,promptAr,options,answer,extra={})=>({type:"textChoice",skill,canDo,prompt,promptAr,options,answer,...extra});
export const missionSpeak=(skill,canDo,prompt,promptAr,evaluation,extra={})=>({type:"speak",skill,canDo,prompt,promptAr,accepted:[],evaluation,fallbackSkill:"writing",...extra});
export const missionWrite=(canDo,prompt,promptAr,evaluation,wordGuide)=>({type:"write",skill:"writing",canDo,prompt,promptAr,accepted:[],evaluation,wordGuide});
export const missionForm=(canDo,prompt,promptAr,fields,evaluation)=>({type:"form",skill:"writing",canDo,prompt,promptAr,fields,evaluation});
