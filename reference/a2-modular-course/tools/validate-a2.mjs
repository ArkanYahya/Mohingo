import {readFileSync} from "node:fs";
import {resolve,dirname} from "node:path";
import {fileURLToPath} from "node:url";
import {buildCourse} from "./build-a2.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const read=relative=>JSON.parse(readFileSync(resolve(root,relative),"utf8"));
const {manifest,bundle}=buildCourse(root,{writeOutput:false});
const fail=message=>{throw Error(message);};
const unique=(records,label)=>{const seen=new Set();for(const record of records){if(!record?.id)fail(`${label} without id`);if(seen.has(record.id))fail(`Duplicate ${label}: ${record.id}`);seen.add(record.id);}return seen;};
const grammar=unique(bundle.grammar,"grammar"),lexicon=unique(bundle.lexicon,"lexicon"),chunks=unique(bundle.chunks,"chunk"),unitIds=unique(bundle.units,"unit");
const canDos=new Set(Object.values(bundle.domain.CAN_DO));
const skills=new Set(Object.values(bundle.domain.SKILLS)),modes=new Set(Object.values(bundle.domain.MODES)),types=new Set(Object.values(bundle.domain.ACTIVITY_TYPES));
const media=new Set(Object.keys(bundle.mediaSpecifications)),activityIds=new Set();
const assessmentIds=new Set();

const multiset=value=>value.reduce((m,x)=>m.set(String(x),(m.get(String(x))||0)+1),new Map());
const sameMultiset=(a,b)=>{const x=multiset(a),y=multiset(b);return x.size===y.size&&[...x].every(([k,v])=>y.get(k)===v);};

function validateActivity(activity,{lessonId,assessment=false}={}){
  const targetSet=assessment?assessmentIds:activityIds;
  if(!activity?.id)fail("Activity without id");
  if(targetSet.has(activity.id)||activityIds.has(activity.id)&&assessment)fail(`Duplicate activity ${activity.id}`);
  targetSet.add(activity.id);
  if(lessonId&&(!activity.id.startsWith(`${lessonId}-`)||activity.lessonId!==lessonId))fail(`${activity.id}: placement mismatch in ${lessonId}`);
  if(!skills.has(activity.skill)||!types.has(activity.type)||!modes.has(activity.mode))fail(`${activity.id}: invalid skill, type or mode`);
  if(!Array.isArray(activity.canDo)||activity.canDo.length===0)fail(`${activity.id}: missing Can-Do`);
  for(const objective of activity.canDo)if(!canDos.has(objective))fail(`${activity.id}: unknown Can-Do ${objective}`);
  if(["audioChoice","textChoice"].includes(activity.type)){
    if(!Array.isArray(activity.options)||activity.options.length<2)fail(`${activity.id}: choice needs options`);
    if(!activity.options.includes(activity.answer))fail(`${activity.id}: answer is not an option`);
    if(activity.type==="audioChoice"&&!activity.audioTranscript)fail(`${activity.id}: missing transcript`);
    if(activity.type==="textChoice"&&!activity.sourceText)fail(`${activity.id}: missing source text`);
  }
  if(activity.type==="gap"&&(!activity.options?.includes(activity.answer)||!activity.text?.includes("___")))fail(`${activity.id}: invalid gap`);
  if(activity.type==="order"&&(!Array.isArray(activity.tokens)||!Array.isArray(activity.answer)||!sameMultiset(activity.tokens,activity.answer)))fail(`${activity.id}: order answer must use exactly the supplied tokens`);
  if(activity.type==="match"&&(!Array.isArray(activity.pairs)||activity.pairs.length<3||activity.pairs.some(pair=>pair.length!==2||pair.some(x=>!x))))fail(`${activity.id}: invalid match pairs`);
  if(["speak","write"].includes(activity.type)&&!Array.isArray(activity.evaluation))fail(`${activity.id}: missing performance rubric`);
  if(activity.audioTranscript&&!media.has(`audio-${activity.id.toLowerCase()}`))fail(`${activity.id}: missing media specification`);
}

for(const kind of ["grammar","lexicon","chunks"])for(const file of manifest.registries[kind]){
  const module=read(file);
  if(module.kind!==kind||!unitIds.has(module.unitId))fail(`${file}: invalid registry module header`);
  for(const record of module.records){
    if(!String(record.introducedIn).startsWith(`${module.unitId}-L`))fail(`${record.id}: introducedIn mismatch`);
    if(kind==="grammar"&&(!record.form||!record.meaningAr||!record.examples?.[0]?.en||!record.examples?.[0]?.ar))fail(`${record.id}: incomplete bilingual grammar record`);
    if(kind==="lexicon"&&(record.cefr!=="A2"||record.receptive!==true||typeof record.productive!=="boolean"||!record.meaning||!record.examples?.[0]?.en||!record.examples?.[0]?.ar))fail(`${record.id}: incomplete lexical-sense record`);
    if(kind==="chunks"&&(!record.text||!record.arabic||record.cefr!=="A2"))fail(`${record.id}: incomplete bilingual chunk`);
  }
}

for(const unit of bundle.units){
  if(!/^A2-U(?:[1-9]|1[0-2])$/.test(unit.id))fail(`Invalid unit id ${unit.id}`);
  if(unit.lessons.length!==manifest.qualityExpectations.coreLessonsPerUnit)fail(`${unit.id}: expected 7 lessons`);
  const expectedLessonIds=Array.from({length:7},(_,i)=>`${unit.id}-L${i+1}`);
  if(unit.lessons.some((l,i)=>l.id!==expectedLessonIds[i]))fail(`${unit.id}: lesson order/id mismatch`);
  const evidence={},skillCounts={};
  for(const lesson of unit.lessons){
    for(const id of lesson.grammar||[])if(!grammar.has(id))fail(`${lesson.id}: unknown grammar ${id}`);
    for(const id of lesson.lexicon||[])if(!lexicon.has(id))fail(`${lesson.id}: unknown lexicon ${id}`);
    for(const id of lesson.chunks||[])if(!chunks.has(id))fail(`${lesson.id}: unknown chunk ${id}`);
    for(const activity of lesson.activities){
      validateActivity(activity,{lessonId:lesson.id});
      skillCounts[activity.skill]=(skillCounts[activity.skill]||0)+1;
      if(activity.mode==="mastery")for(const objective of activity.canDo)evidence[objective]=(evidence[objective]||0)+1;
    }
  }
  const count=unit.lessons.reduce((n,l)=>n+l.activities.length,0);
  if(count!==manifest.qualityExpectations.coreActivitiesPerUnit)fail(`${unit.id}: expected 36 activities, got ${count}`);
  for(const objective of unit.mastery.requiredObjectives||[])if((evidence[objective]||0)<bundle.domain.MASTERY_POLICY.minimumEvidencePerRequiredObjective)fail(`${unit.id}: ${objective} has only ${evidence[objective]||0} mastery evidence points`);
  for(const skill of ["listening","reading","writing","spokenInteraction","spokenProduction","mediation"])if(!skillCounts[skill])fail(`${unit.id}: missing ${skill}`);
  if(!unit.lessons.some(l=>l.lessonType==="mission"))fail(`${unit.id}: missing mission lesson`);
}

if(bundle.units.length!==manifest.qualityExpectations.unitCount)fail(`Expected 12 units, got ${bundle.units.length}`);
const lessonCount=bundle.units.reduce((n,u)=>n+u.lessons.length,0),lessonActivities=bundle.units.reduce((n,u)=>n+u.lessons.reduce((s,l)=>s+l.activities.length,0),0);
if(lessonCount!==manifest.qualityExpectations.lessonCount)fail("Course lesson count mismatch");

if(bundle.finalMission.id!=="A2-FINAL-MISSION"||bundle.finalMission.activities.length!==manifest.qualityExpectations.finalMissionActivities)fail("Invalid final mission");
const finalEvidence={};
for(const activity of bundle.finalMission.activities){validateActivity(activity);for(const objective of activity.canDo)finalEvidence[objective]=(finalEvidence[objective]||0)+1;}
for(const objective of bundle.finalMission.canDo)if((finalEvidence[objective]||0)<2)fail(`Final mission: insufficient evidence for ${objective}`);
const missionActivityIds=new Set(bundle.finalMission.activities.map(activity=>activity.id));
for(const stage of bundle.finalMission.stages)for(const id of stage.activityIds)if(!missionActivityIds.has(id))fail(`${stage.id}: unknown activity ${id}`);

if(bundle.finalAssessment.id!=="A2-FINAL-ASSESSMENT")fail("Invalid final assessment id");
for(const [sectionName,expected] of Object.entries(manifest.qualityExpectations.assessment)){
  if(sectionName==="total")continue;
  const section=bundle.finalAssessment.sections[sectionName];
  if(!section||section.activities.length!==expected)fail(`${sectionName}: expected ${expected} assessment items`);
  for(const activity of section.activities)validateActivity(activity,{assessment:true});
}
const assessmentTotal=Object.values(bundle.finalAssessment.sections).reduce((sum,section)=>sum+section.activities.length,0);
if(bundle.finalAssessment.scoring.decisionRule.noSingleOverallAverage!==true||bundle.domain.MASTERY_POLICY.practiceCountsAsMastery!==false)fail("Invalid mastery policy");

const learningSources=new Set([...bundle.units.flatMap(u=>u.lessons.flatMap(l=>l.activities)),...bundle.finalMission.activities].flatMap(a=>[a.audioTranscript,a.sourceText]).filter(Boolean).map(x=>x.trim().toLowerCase()));
for(const section of Object.values(bundle.finalAssessment.sections))for(const activity of section.activities)for(const source of [activity.audioTranscript,activity.sourceText])if(source&&learningSources.has(source.trim().toLowerCase()))fail(`${activity.id}: assessment repeats learning input exactly`);

const actual={units:bundle.units.length,lessons:lessonCount,lessonActivities,finalMissionActivities:bundle.finalMission.activities.length,assessmentActivities:assessmentTotal,grammar:grammar.size,lexicon:lexicon.size,chunks:chunks.size,media:media.size,courseActivityIds:activityIds.size,assessmentActivityIds:assessmentIds.size,canDo:canDos.size};
console.log(JSON.stringify({status:"valid",contentVersion:bundle.contentVersion,...actual},null,2));
