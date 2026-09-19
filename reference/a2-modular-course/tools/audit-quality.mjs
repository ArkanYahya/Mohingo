import {mkdirSync,writeFileSync} from "node:fs";
import {dirname,resolve} from "node:path";
import {fileURLToPath,pathToFileURL} from "node:url";
import {buildCourse} from "./build-a2.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const {bundle}=buildCourse(root,{writeOutput:false});
const rank=id=>{const m=String(id).match(/^A2-U(\d+)(?:-L(\d+))?/);return m?[Number(m[1]),Number(m[2]||0)]:[99,99];};
const notLater=(introduced,used)=>{const a=rank(introduced),b=rank(used);return a[0]<b[0]||(a[0]===b[0]&&a[1]<=b[1]);};
const registries={grammar:new Map(bundle.grammar.map(r=>[r.id,r])),lexicon:new Map(bundle.lexicon.map(r=>[r.id,r])),chunks:new Map(bundle.chunks.map(r=>[r.id,r]))};
const errors=[],warnings=[],sourceOwners=new Map();

for(const [kind,index] of Object.entries(registries))for(const record of index.values()){
  if(!record.introducedIn)errors.push(`${record.id}: missing introducedIn`);
  if(kind!=="grammar"&&(!Array.isArray(record.recycledIn)||record.recycledIn.length===0))errors.push(`${record.id}: missing recycling target`);
  if(kind==="lexicon"&&(!record.meaning||!record.examples?.[0]?.ar||record.receptive!==true||typeof record.productive!=="boolean"))errors.push(`${record.id}: incomplete lexical sense`);
  if(kind==="grammar"&&(!record.meaningAr||!record.examples?.[0]?.ar))errors.push(`${record.id}: incomplete bilingual grammar`);
  if(kind==="chunks"&&(!record.text||!record.arabic))errors.push(`${record.id}: incomplete bilingual chunk`);
}

const headwords=new Map();
for(const record of bundle.lexicon){const key=`${record.headword.toLowerCase()}|${record.partOfSpeech}`;(headwords.get(key)||headwords.set(key,[]).get(key)).push(record);}
for(const [key,records] of headwords)if(records.length>1)errors.push(`${key}: duplicate lexical sense records ${records.map(r=>r.id).join(", ")}`);

const unitReports=[];
for(const unit of bundle.units){
  const skills={},modes={},evidence={};
  for(const lesson of unit.lessons){
    for(const kind of ["grammar","lexicon","chunks"])for(const id of lesson[kind]||[]){
      const record=registries[kind].get(id);
      if(!record)errors.push(`${lesson.id}: unresolved ${kind} ${id}`);
      else if(!notLater(record.introducedIn,lesson.id))errors.push(`${lesson.id}: forward ${kind} reference ${id} introduced in ${record.introducedIn}`);
    }
    if(lesson.encounter?.dialogue?.some(line=>!line.en))errors.push(`${lesson.id}: encounter line missing English`);
    for(const activity of lesson.activities){
      skills[activity.skill]=(skills[activity.skill]||0)+1;
      modes[activity.mode]=(modes[activity.mode]||0)+1;
      if(activity.promptAr===activity.prompt)warnings.push(`${activity.id}: Arabic UI prompt equals English prompt`);
      if(["audioChoice","textChoice"].includes(activity.type)&&new Set(activity.options).size!==activity.options.length)errors.push(`${activity.id}: duplicate options`);
      if(activity.mode==="mastery")for(const objective of activity.canDo)evidence[objective]=(evidence[objective]||0)+1;
      for(const source of [activity.audioTranscript,activity.sourceText])if(source){const key=source.trim().toLowerCase();(sourceOwners.get(key)||sourceOwners.set(key,[]).get(key)).push(activity.id);}
    }
  }
  for(const objective of unit.mastery.requiredObjectives)if((evidence[objective]||0)<2)errors.push(`${unit.id}: fewer than two mastery evidence points for ${objective}`);
  for(const skill of ["listening","reading","writing","spokenInteraction","spokenProduction","mediation"])if(!skills[skill])errors.push(`${unit.id}: missing ${skill}`);
  unitReports.push({id:unit.id,lessons:unit.lessons.length,activities:unit.lessons.reduce((n,l)=>n+l.activities.length,0),skills,modes,requiredObjectives:unit.mastery.requiredObjectives.length,masteryEvidence:evidence,recycleFrom:unit.recycleFrom});
}

for(const activity of bundle.finalMission.activities){
  if(activity.promptAr===activity.prompt)warnings.push(`${activity.id}: Arabic UI prompt equals English prompt`);
  for(const source of [activity.audioTranscript,activity.sourceText])if(source){const key=source.trim().toLowerCase();(sourceOwners.get(key)||sourceOwners.set(key,[]).get(key)).push(activity.id);}
}
for(const section of Object.values(bundle.finalAssessment.sections))for(const activity of section.activities){
  if(activity.promptAr===activity.prompt)errors.push(`${activity.id}: assessment Arabic prompt is missing`);
  for(const source of [activity.audioTranscript,activity.sourceText])if(source){const key=source.trim().toLowerCase();if(sourceOwners.has(key))errors.push(`${activity.id}: assessment repeats an instructional source`);}
}
for(const [source,owners] of sourceOwners)if(owners.length>1)warnings.push(`Repeated learning source in ${owners.join(", ")}: ${source.slice(0,90)}`);

const writingTasks=[...bundle.units.flatMap(u=>u.lessons.flatMap(l=>l.activities.filter(a=>a.skill==="writing"))),...bundle.finalMission.activities.filter(a=>a.skill==="writing"),...bundle.finalAssessment.sections.writing.activities];
for(const task of writingTasks)if(!Array.isArray(task.wordGuide)||task.wordGuide[0]<50||task.wordGuide[1]>125)errors.push(`${task.id}: unsuitable A2 writing range`);

const recycledGrammarIds=new Set();
for(const unit of bundle.units)for(const lesson of unit.lessons)for(const id of lesson.grammar||[]){const source=registries.grammar.get(id);if(source&&rank(source.introducedIn)[0]<rank(lesson.id)[0])recycledGrammarIds.add(id);}
const grammarRecycle=recycledGrammarIds.size,lexRecycle=bundle.lexicon.filter(x=>x.recycledIn?.length).length,chunkRecycle=bundle.chunks.filter(x=>x.recycledIn?.length).length;
const assessmentCounts=Object.fromEntries(Object.entries(bundle.finalAssessment.sections).map(([name,section])=>[name,section.activities.length]));
const report={
  status:errors.length?"failed":"passed",contentVersion:bundle.contentVersion,generatedAt:new Date().toISOString(),
  principlesChecked:["stable and resolved references","no forward introduction","two or more mastery evidence points per required objective","six-skill coverage in every unit","bilingual registries and assessment UI","unique lexical senses","scheduled cross-unit recycling","unseen final-assessment inputs","A2 writing ranges","distinct choice options"],
  totals:{units:bundle.units.length,lessons:unitReports.reduce((n,u)=>n+u.lessons,0),lessonActivities:unitReports.reduce((n,u)=>n+u.activities,0),grammar:bundle.grammar.length,lexicon:bundle.lexicon.length,chunks:bundle.chunks.length,media:Object.keys(bundle.mediaSpecifications).length,finalMissionActivities:bundle.finalMission.activities.length,assessment:assessmentCounts},
  lexicalProfile:{receptive:bundle.lexicon.filter(x=>x.receptive).length,productive:bundle.lexicon.filter(x=>x.productive).length,chunks:bundle.chunks.length,scheduledRecycling:{grammar:grammarRecycle,lexicon:lexRecycle,chunks:chunkRecycle}},
  units:unitReports,warnings,errors
};
const output=resolve(root,"quality/a2-quality-report.json");mkdirSync(dirname(output),{recursive:true});writeFileSync(output,`${JSON.stringify(report,null,2)}\n`,"utf8");
if(errors.length)throw Error(`Quality audit failed with ${errors.length} error(s). See quality/a2-quality-report.json`);
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href)console.log(JSON.stringify({status:report.status,warnings:warnings.length,totals:report.totals,scheduledRecycling:report.lexicalProfile.scheduledRecycling},null,2));
