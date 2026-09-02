import {createHash} from "node:crypto";
import {readFileSync} from "node:fs";
import {resolve,dirname} from "node:path";
import {fileURLToPath} from "node:url";
import {buildCourse} from "./build-a1.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const read=relative=>JSON.parse(readFileSync(resolve(root,relative),"utf8"));
const digest=relative=>createHash("sha256").update(readFileSync(resolve(root,relative))).digest("hex");
const {manifest,bundle}=buildCourse(root,{writeOutput:false});
const unique=(records,label)=>{const seen=new Set();for(const record of records){if(!record.id)throw Error(`${label} without id`);if(seen.has(record.id))throw Error(`Duplicate ${label}: ${record.id}`);seen.add(record.id);}return seen;};
const grammar=unique(bundle.grammar,"grammar"),lexicon=unique(bundle.lexicon,"lexicon"),chunks=unique(bundle.chunks,"chunk"),units=unique(bundle.units,"unit");
const activityIds=new Set(),canDos=new Set(Object.values(bundle.domain.CAN_DO)),skills=new Set(Object.values(bundle.domain.SKILLS)),modes=new Set(Object.values(bundle.domain.MODES)),types=new Set(Object.values(bundle.domain.ACTIVITY_TYPES)),media=new Set(Object.keys(bundle.mediaSpecifications));

function validateChoice(activity){
  if(["audioChoice","textChoice"].includes(activity.type)){
    if(!Array.isArray(activity.options)||activity.options.length<2)throw Error(`${activity.id}: choice needs at least two options`);
    if(!activity.options.includes(activity.answer))throw Error(`${activity.id}: answer is not an option`);
  }
}

function validateActivity(activity,{lessonId}={}){
  if(activityIds.has(activity.id))throw Error(`Duplicate activity ${activity.id}`);
  activityIds.add(activity.id);
  if(lessonId&&(!activity.id.startsWith(`${lessonId}-`)||activity.lessonId!==lessonId))throw Error(`${activity.id} placed in ${lessonId}`);
  if(!modes.has(activity.mode)||!skills.has(activity.skill)||!types.has(activity.type)||!activity.canDo?.length)throw Error(`Invalid activity ${activity.id}`);
  for(const canDo of activity.canDo)if(!canDos.has(canDo))throw Error(`${activity.id}: unknown Can-Do ${canDo}`);
  if(activity.optionMode==="media")for(const option of activity.options||[])if(!media.has(option))throw Error(`${activity.id}: unknown media ${option}`);
  validateChoice(activity);
}

for(const kind of ["grammar","lexicon","chunks"]){
  for(const file of manifest.registries[kind]){
    const module=read(file);
    if(module.kind!==kind)throw Error(`${file}: kind mismatch`);
    for(const record of module.records)if(!String(record.introducedIn).startsWith(`${module.unitId}-`))throw Error(`${record.id} is in ${file} but introduced in ${record.introducedIn}`);
  }
}

for(const unit of bundle.units){
  const evidence=new Set(unit.lessons.flatMap(lesson=>lesson.activities.filter(activity=>activity.mode==="mastery").flatMap(activity=>activity.canDo||[])));
  for(const objective of unit.mastery.requiredObjectives||[])if(!evidence.has(objective))throw Error(`${unit.id} lacks mastery evidence: ${objective}`);
  for(const lesson of unit.lessons){
    if(!lesson.id.startsWith(`${unit.id}-`))throw Error(`${lesson.id} placed in ${unit.id}`);
    for(const id of lesson.grammar||[])if(!grammar.has(id))throw Error(`${lesson.id}: unknown grammar ${id}`);
    for(const id of lesson.lexicon||[])if(!lexicon.has(id))throw Error(`${lesson.id}: unknown lexicon ${id}`);
    for(const id of lesson.chunks||[])if(!chunks.has(id))throw Error(`${lesson.id}: unknown chunk ${id}`);
    for(const activity of lesson.activities)validateActivity(activity,{lessonId:lesson.id});
  }
}

const q=manifest.qualityExpectations;
const lessonCount=bundle.units.reduce((sum,unit)=>sum+unit.lessons.length,0);
if(units.size!==q.unitCount)throw Error(`units: expected ${q.unitCount}, got ${units.size}`);
if(lessonCount!==q.lessonCount)throw Error(`lessons: expected ${q.lessonCount}, got ${lessonCount}`);
for(const id of q.coreUnitIds){
  const unit=bundle.units.find(item=>item.id===id);
  if(!unit)throw Error(`Missing core unit ${id}`);
  const count=unit.lessons.reduce((sum,lesson)=>sum+lesson.activities.length,0);
  if(unit.lessons.length!==q.coreLessonsPerUnit||count!==q.coreActivitiesPerUnit)throw Error(`${id}: expected ${q.coreLessonsPerUnit} lessons/${q.coreActivitiesPerUnit} activities, got ${unit.lessons.length}/${count}`);
}

if(!bundle.finalMission||bundle.finalMission.id!=="A1-FINAL-MISSION")throw Error("Missing final mission");
if(bundle.finalMission.activities.length!==q.finalMissionActivities)throw Error(`Final mission activities: expected ${q.finalMissionActivities}`);
for(const activity of bundle.finalMission.activities)validateActivity(activity);
const missionActivityIds=new Set(bundle.finalMission.activities.map(activity=>activity.id));
for(const stage of bundle.finalMission.stages)for(const id of stage.activityIds)if(!missionActivityIds.has(id))throw Error(`${stage.id}: unknown activity ${id}`);

if(!bundle.finalAssessment||bundle.finalAssessment.id!=="A1-FINAL-ASSESSMENT")throw Error("Missing final assessment");
for(const [sectionName,expected] of Object.entries(q.assessment)){
  const section=bundle.finalAssessment.sections[sectionName];
  if(!section)throw Error(`Missing assessment section ${sectionName}`);
  if(section.activities.length!==expected)throw Error(`${sectionName}: expected ${expected} tasks, got ${section.activities.length}`);
  for(const activity of section.activities)validateActivity(activity);
}
if(bundle.finalAssessment.scoring.decisionRule.noSingleOverallAverage!==true)throw Error("Final decision must not use a single compensating average");
if(bundle.domain.MASTERY_POLICY.practiceCountsAsMastery!==false)throw Error("Practice must not count as mastery");

const baseline=read("quality/baseline-u0-u3.sha256.json");
for(const [file,expected] of Object.entries(baseline.files))if(digest(file)!==expected)throw Error(`Completed source changed unexpectedly: ${file}`);

const actual={
  units:units.size,
  lessons:lessonCount,
  lessonActivities:bundle.units.reduce((sum,unit)=>sum+unit.lessons.reduce((n,lesson)=>n+lesson.activities.length,0),0),
  finalMissionActivities:bundle.finalMission.activities.length,
  assessmentActivities:Object.values(bundle.finalAssessment.sections).reduce((sum,section)=>sum+section.activities.length,0),
  grammar:grammar.size,
  lexicon:lexicon.size,
  chunks:chunks.size,
  media:media.size,
  allActivityIds:activityIds.size
};
console.log(JSON.stringify({status:"valid",contentVersion:bundle.contentVersion,baselineProtectedFiles:Object.keys(baseline.files).length,...actual},null,2));
