import {mkdirSync,writeFileSync} from "node:fs";
import {dirname,resolve} from "node:path";
import {fileURLToPath,pathToFileURL} from "node:url";
import {buildCourse} from "./build-a1.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const {bundle}=buildCourse(root,{writeOutput:false});
const unitRank=id=>{const match=String(id).match(/^A1-U(\d+)(?:-L(\d+))?/);return match?[Number(match[1]),Number(match[2]||0)]:[999,999];};
const notLater=(introduced,used)=>{const a=unitRank(introduced),b=unitRank(used);return a[0]<b[0]||(a[0]===b[0]&&a[1]<=b[1]);};
const registries={grammar:new Map(bundle.grammar.map(r=>[r.id,r])),lexicon:new Map(bundle.lexicon.map(r=>[r.id,r])),chunks:new Map(bundle.chunks.map(r=>[r.id,r]))};
const validUnits=new Set(bundle.units.map(unit=>unit.id));
const errors=[],warnings=[];

for(const [kind,index] of Object.entries(registries))for(const record of index.values()){
  if(!record.introducedIn)errors.push(`${record.id}: missing introducedIn`);
  if(unitRank(record.introducedIn)[0]>=4){
    if(kind!=="chunks"&&(!Array.isArray(record.examples)||record.examples.length===0))errors.push(`${record.id}: missing authored example`);
    if(kind==="chunks"&&(!record.text||!record.arabic))errors.push(`${record.id}: incomplete bilingual chunk`);
    if(kind==="lexicon"&&(record.receptive!==true||typeof record.productive!=="boolean"))errors.push(`${record.id}: missing receptive/productive status`);
  }
  for(const recycleId of record.recycledIn||[]){
    const unitId=String(recycleId).match(/^A1-U\d+/)?.[0];
    if(recycleId!=="ALL"&&(!unitId||!validUnits.has(unitId)))errors.push(`${record.id}: unknown recycledIn ${recycleId}`);
  }
}

const unitReports=[];
for(const unit of bundle.units){
  const skills={},modes={},objectiveEvidence={};
  for(const lesson of unit.lessons){
    for(const kind of ["grammar","lexicon","chunks"])for(const id of lesson[kind]||[]){
      const record=registries[kind].get(id);
      if(record&&!notLater(record.introducedIn,lesson.id)){
        const message=`${lesson.id}: forward ${kind} reference ${id} introduced in ${record.introducedIn}`;
        if(unitRank(unit.id)[0]<4)warnings.push(`legacy: ${message}`);else errors.push(message);
      }
    }
    for(const activity of lesson.activities){
      skills[activity.skill]=(skills[activity.skill]||0)+1;
      modes[activity.mode]=(modes[activity.mode]||0)+1;
      if(activity.mode==="mastery")for(const objective of activity.canDo)objectiveEvidence[objective]=(objectiveEvidence[objective]||0)+1;
    }
  }
  for(const objective of unit.mastery.requiredObjectives||[])if(!objectiveEvidence[objective])errors.push(`${unit.id}: no mastery evidence for ${objective}`);
  if(unitRank(unit.id)[0]>=4){
    for(const skill of ["listening","reading","writing","spokenInteraction","mediation"])if(!skills[skill])errors.push(`${unit.id}: missing skill ${skill}`);
    if(!unit.lessons.some(lesson=>lesson.lessonType==="mission"))errors.push(`${unit.id}: missing mission lesson`);
  }
  unitReports.push({id:unit.id,lessons:unit.lessons.length,activities:unit.lessons.reduce((n,l)=>n+l.activities.length,0),skills,modes,requiredObjectives:(unit.mastery.requiredObjectives||[]).length,masteryEvidence:objectiveEvidence});
}

const learningSignatures=new Set();
for(const unit of bundle.units)for(const lesson of unit.lessons)for(const activity of lesson.activities){
  for(const value of [activity.audioTranscript,activity.sourceText])if(value)learningSignatures.add(String(value).trim().toLowerCase());
}
for(const section of Object.values(bundle.finalAssessment.sections))for(const activity of section.activities){
  for(const value of [activity.audioTranscript,activity.sourceText])if(value&&learningSignatures.has(String(value).trim().toLowerCase()))errors.push(`${activity.id}: repeats learning input exactly`);
}

const headwords=new Map();
for(const record of bundle.lexicon){const key=`${record.headword.toLowerCase()}|${record.partOfSpeech}`;(headwords.get(key)||headwords.set(key,[]).get(key)).push(record);}
for(const [key,records] of headwords)if(records.length>1){
  const meanings=new Set(records.map(r=>r.meaning));
  if(meanings.size===1)warnings.push(`${key}: legacy/duplicate surface senses ${records.map(r=>r.id).join(", ")}`);
}

const assessmentCounts=Object.fromEntries(Object.entries(bundle.finalAssessment.sections).map(([name,section])=>[name,section.activities.length]));
const report={
  status:errors.length?"failed":"passed",
  contentVersion:bundle.contentVersion,
  generatedAt:new Date().toISOString(),
  principlesChecked:["no forward content references","all required objectives have mastery evidence","U4-U12 cover receptive, productive and mediation skills","new registry records contain bilingual teaching data","recycledIn targets exist","final assessment does not exactly reuse learning inputs"],
  totals:{units:bundle.units.length,lessons:unitReports.reduce((n,u)=>n+u.lessons,0),lessonActivities:unitReports.reduce((n,u)=>n+u.activities,0),grammar:bundle.grammar.length,lexicon:bundle.lexicon.length,chunks:bundle.chunks.length,media:Object.keys(bundle.mediaSpecifications).length,finalMissionActivities:bundle.finalMission.activities.length,assessment:assessmentCounts},
  lexicalProfile:{receptive:bundle.lexicon.filter(x=>x.receptive).length,productive:bundle.lexicon.filter(x=>x.productive).length,chunks:bundle.chunks.length},
  units:unitReports,
  warnings,
  errors
};
const output=resolve(root,"quality/a1-quality-report.json");mkdirSync(dirname(output),{recursive:true});writeFileSync(output,`${JSON.stringify(report,null,2)}\n`,"utf8");
if(errors.length)throw Error(`Quality audit failed with ${errors.length} error(s). See quality/a1-quality-report.json`);
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href)console.log(JSON.stringify({status:report.status,warnings:warnings.length,totals:report.totals},null,2));
