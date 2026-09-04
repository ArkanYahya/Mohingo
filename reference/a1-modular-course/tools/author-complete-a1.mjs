import {createHash} from "node:crypto";
import {existsSync,mkdirSync,readFileSync,writeFileSync} from "node:fs";
import {dirname,resolve} from "node:path";
import {fileURLToPath,pathToFileURL} from "node:url";
import {packageData as p46} from "./authoring/a1-u4-u6.mjs";
import {packageData as p79} from "./authoring/a1-u7-u9.mjs";
import {packageData as p1012} from "./authoring/a1-u10-u12.mjs";
import {packageData as pFinal} from "./authoring/a1-final.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const read=relative=>JSON.parse(readFileSync(resolve(root,relative),"utf8"));
const write=(relative,value)=>{const target=resolve(root,relative);mkdirSync(dirname(target),{recursive:true});writeFileSync(target,`${JSON.stringify(value,null,2)}\n`,"utf8");};
const hash=relative=>createHash("sha256").update(readFileSync(resolve(root,relative))).digest("hex");
const unitFiles=[0,1,2,3].flatMap(n=>[
  `units/A1-U${n}.json`,`registries/grammar/A1-U${n}.json`,`registries/lexicon/A1-U${n}.json`,`registries/chunks/A1-U${n}.json`,`media/A1-U${n}.json`
]);

function ensureBaseline(){
  const target="quality/baseline-u0-u3.sha256.json";
  if(!existsSync(resolve(root,target)))write(target,{createdFrom:"A1-U0-U3-2026.09.01",purpose:"Guard completed U0-U3 against accidental rewrites",files:Object.fromEntries(unitFiles.map(file=>[file,hash(file)]))});
}

const packages=[p46,p79,p1012];
const allUnits=packages.flatMap(p=>p.units);
const mediaForUnit=unit=>{
  const records={};
  for(const lesson of unit.lessons)for(const activity of lesson.activities||[])if(activity.audioTranscript){
    records[`audio-${activity.id.toLowerCase()}`]={type:"ttsSource",locale:"en",voiceProfile:"clear-neutral-a1",transcript:activity.audioTranscript,activityId:activity.id};
  }
  return records;
};
const mediaForActivities=activities=>Object.fromEntries(activities.filter(a=>a.audioTranscript).map(a=>[`audio-${a.id.toLowerCase()}`,{type:"ttsSource",locale:"en",voiceProfile:"clear-neutral-a1",transcript:a.audioTranscript,activityId:a.id}]));

ensureBaseline();
for(const p of packages)for(const unit of p.units){
  const id=unit.id;
  write(`units/${id}.json`,unit);
  for(const kind of ["grammar","lexicon","chunks"])write(`registries/${kind}/${id}.json`,{moduleSchemaVersion:"1.0.0",unitId:id,kind,records:p[kind][id]});
  write(`media/${id}.json`,{moduleSchemaVersion:"1.0.0",unitId:id,kind:"media",records:mediaForUnit(unit)});
}

write("final/A1-FINAL-MISSION.json",pFinal.finalMission);
write("assessment/A1-FINAL-ASSESSMENT.json",pFinal.finalAssessment);
const finalAudio=[...pFinal.finalMission.activities,...Object.values(pFinal.finalAssessment.sections).flatMap(section=>section.activities)];
write("media/A1-FINAL.json",{moduleSchemaVersion:"1.0.0",unitId:"A1-FINAL",kind:"media",records:mediaForActivities(finalAudio)});

const domain=read("domain.json");
domain.CAN_DO={...domain.CAN_DO,...Object.assign({},...packages.map(p=>p.canDo),pFinal.canDo)};
write("domain.json",domain);

const course=read("course.json");
course.contentVersion="A1-COMPLETE-2026.09.02";
course.course.status="complete-course";
course.course.completedScope=[...Array.from({length:13},(_,i)=>`A1-U${i}`),"A1-FINAL-MISSION","A1-FINAL-ASSESSMENT"];
course.course.pendingScope=[];
course.course.authoredUnitCount=13;
course.course.authoredLessonCount=89;
course.course.finalMissionId="A1-FINAL-MISSION";
course.course.finalAssessmentId="A1-FINAL-ASSESSMENT";
write("course.json",course);

const manifest=read("manifest.json");
manifest.sourceContentVersion=course.contentVersion;
for(const kind of ["grammar","lexicon","chunks"])manifest.registries[kind]=Array.from({length:13},(_,i)=>`registries/${kind}/A1-U${i}.json`);
manifest.units=Array.from({length:13},(_,i)=>`units/A1-U${i}.json`);
manifest.media=[...Array.from({length:13},(_,i)=>`media/A1-U${i}.json`),"media/A1-FINAL.json"];
manifest.finalMission="final/A1-FINAL-MISSION.json";
manifest.finalAssessment="assessment/A1-FINAL-ASSESSMENT.json";
manifest.qualityExpectations={unitCount:13,lessonCount:89,coreUnitIds:Array.from({length:9},(_,i)=>`A1-U${i+4}`),coreLessonsPerUnit:7,coreActivitiesPerUnit:36,finalMissionActivities:12,assessment:{listening:16,reading:16,writing:2,speaking:4,mediation:2}};
write("manifest.json",manifest);

if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  console.log(JSON.stringify({status:"authored",contentVersion:course.contentVersion,addedUnits:allUnits.map(u=>u.id),finalMission:pFinal.finalMission.id,finalAssessment:pFinal.finalAssessment.id},null,2));
}
