import {mkdirSync,writeFileSync} from "node:fs";
import {dirname,resolve} from "node:path";
import {fileURLToPath,pathToFileURL} from "node:url";
import {packageData as p14} from "./authoring/a2-u1-u4.mjs";
import {packageData as p58} from "./authoring/a2-u5-u8.mjs";
import {packageData as p912} from "./authoring/a2-u9-u12.mjs";
import {finalCanDo,finalMission,finalAssessment} from "./authoring/final-and-assessment.mjs";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const write=(relative,value)=>{const target=resolve(root,relative);mkdirSync(dirname(target),{recursive:true});writeFileSync(target,`${JSON.stringify(value,null,2)}\n`,"utf8");};
const packages=[p14,p58,p912];
const units=packages.flatMap(p=>p.units);
const allCanDo=Object.assign({},...packages.map(p=>p.canDo),Object.fromEntries(Object.values(finalCanDo).map(x=>[x.id,x.id])));
const recordsByUnit=Object.fromEntries(units.map(unit=>[unit.id,Object.fromEntries(["grammar","lexicon","chunks"].map(kind=>[kind,packages.find(p=>p[kind][unit.id])?.[kind][unit.id]||[]]))]));

// Scheduled, explicit cross-unit recycling. Each target revisits three bands from
// the preceding three units; remaining late-course records are revisited in the capstone.
const bands={grammar:[[0,2],[2,4],[4,6]],lexicon:[[0,6],[6,12],[12,18]],chunks:[[0,3],[3,6],[6,8]]};
for(let targetIndex=1;targetIndex<units.length;targetIndex++)for(let distance=1;distance<=3;distance++){
  const sourceIndex=targetIndex-distance;
  if(sourceIndex<0)continue;
  const targetLesson=units[targetIndex].lessons[[0,2,4][distance-1]];
  for(const kind of ["grammar","lexicon","chunks"]){
    const [start,end]=bands[kind][distance-1];
    for(const record of recordsByUnit[units[sourceIndex].id][kind].slice(start,end)){
      if(!targetLesson[kind].includes(record.id))targetLesson[kind].push(record.id);
      record.recycledIn=[...new Set([...(record.recycledIn||[]),targetLesson.id])];
    }
  }
}
for(const kind of ["grammar","lexicon","chunks"]){
  finalMission[kind]=[];
  for(const unit of units)for(const record of recordsByUnit[unit.id][kind]){
    if(!(record.recycledIn||[]).length){record.recycledIn=[finalMission.id];finalMission[kind].push(record.id);}
  }
}

const stripLessonId=activity=>Object.fromEntries(Object.entries(activity).filter(([key])=>key!=="lessonId"));
const compatibleMission={
  id:finalMission.id,
  title:finalMission.title,
  titleAr:finalMission.titleAr,
  status:"required-capstone",
  estimatedMinutes:finalMission.estimatedMinutes,
  sourcePolicy:"All names, schedules, notices, service problems and visitor details are fictional and unseen in earlier lessons.",
  scenario:finalMission.scenario,
  canDo:finalMission.canDo,
  stages:[
    {id:"A2-FINAL-MISSION-S1",title:"Read the Visitor's Needs",titleAr:"اقرأ احتياجات الزائر",activityIds:["A2-FINAL-MISSION-A01","A2-FINAL-MISSION-A02"]},
    {id:"A2-FINAL-MISSION-S2",title:"Understand the Changes",titleAr:"افهم التغييرات",activityIds:["A2-FINAL-MISSION-A03","A2-FINAL-MISSION-A04"]},
    {id:"A2-FINAL-MISSION-S3",title:"Welcome and Solve",titleAr:"رحّب وحل المشكلة",activityIds:["A2-FINAL-MISSION-A05","A2-FINAL-MISSION-A06"]},
    {id:"A2-FINAL-MISSION-S4",title:"Present the Visit",titleAr:"قدّم برنامج الزيارة",activityIds:["A2-FINAL-MISSION-A07","A2-FINAL-MISSION-A08"]},
    {id:"A2-FINAL-MISSION-S5",title:"Relay Essential Details",titleAr:"انقل التفاصيل الأساسية",activityIds:["A2-FINAL-MISSION-A09","A2-FINAL-MISSION-A10"]},
    {id:"A2-FINAL-MISSION-S6",title:"Write and Follow Up",titleAr:"اكتب وتابع",activityIds:["A2-FINAL-MISSION-A11","A2-FINAL-MISSION-A12"]}
  ],
  activities:finalMission.activities.map(stripLessonId),
  scoring:{completionRequired:true,requiredSkillGroups:finalMission.mastery.requiredSkillGroups,criteria:["taskCompletion","meaningComprehensible","appropriateA2Language","informationAccuracy"],minimumCriterionScore:.75,speechAccuracyWeight:.2,noSingleAverageCompensation:true}
};

const secureItem=activity=>{
  const item=Object.fromEntries(Object.entries(activity).filter(([key])=>key!=="section"));
  const secured={...item,mode:"mastery",assessmentMode:"secure"};
  if(["audioChoice","textChoice"].includes(activity.type))secured.sourcePolicy="unseen";
  return secured;
};
const section=(name,targetKey)=>({[targetKey]:finalAssessment.sections[name].items.length,activities:finalAssessment.sections[name].items.map(secureItem)});
const compatibleAssessment={
  id:finalAssessment.id,
  title:finalAssessment.title,
  titleAr:finalAssessment.titleAr,
  status:"summative",
  sourcePolicy:"Secure unseen inputs; do not draw prompts or answer options from practice activities.",
  estimatedMinutes:finalAssessment.estimatedMinutes,
  sections:{
    listening:section("listening","targetEvidencePoints"),
    reading:section("reading","targetEvidencePoints"),
    writing:section("writing","targetTasks"),
    speaking:section("speaking","targetTasks"),
    mediation:section("mediation","targetTasks")
  },
  scoring:{
    receptive:{method:"item-score",minimumPerSkill:.75},
    writing:{criteria:["taskCompletion","informationCoverage","comprehensibility","A2Range","A2Accuracy"],minimumTaskCriterionAverage:.75,bothTasksRequired:true},
    speaking:{criteria:["taskCompletion","intelligibility","appropriateLanguage","interaction"],minimumTaskCriterionAverage:.75,minimumCompletedTasks:3,accuracyWeight:.2},
    mediation:{criteria:["essentialInformation","accuracyOfRelay","comprehensibility"],minimumCriterionAverage:.75},
    decisionRule:{noSingleOverallAverage:true,required:["listening","reading","writing","speaking","mediation"],capstoneMissionRequired:true},
    accessibility:{microphoneFallback:"writing",fallbackDoesNotCreateSpeakingEvidence:true}
  }
};
const assessmentCounts=Object.fromEntries(Object.entries(compatibleAssessment.sections).map(([name,value])=>[name,value.activities.length]));

// Output compatibility aliases and omissions intentionally follow the A1 contract.
for(const unit of units){
  unit.countsTowardA1Mastery=unit.countsTowardA2Mastery;
  delete unit.countsTowardA2Mastery;
  delete unit.recycleFrom;
  delete unit.mastery.minimumEvidencePerObjective;
  for(const lesson of unit.lessons)for(const activity of lesson.activities)delete activity.fallbackCountsFor;
}
for(const unit of units)for(const record of recordsByUnit[unit.id].grammar)delete record.recycledIn;

const mediaForActivities=activities=>Object.fromEntries(activities.filter(a=>a.audioTranscript).map(a=>[
  `audio-${a.id.toLowerCase()}`,
  {type:"ttsSource",locale:"en",voiceProfile:"clear-neutral-a2",transcript:a.audioTranscript,activityId:a.id}
]));
const mediaForUnit=unit=>mediaForActivities(unit.lessons.flatMap(lesson=>lesson.activities||[]));

for(const p of packages)for(const unit of p.units){
  const id=unit.id;
  write(`units/${id}.json`,unit);
  for(const kind of ["grammar","lexicon","chunks"])write(`registries/${kind}/${id}.json`,{moduleSchemaVersion:"1.0.0",unitId:id,kind,records:p[kind][id]});
  write(`media/${id}.json`,{moduleSchemaVersion:"1.0.0",unitId:id,kind:"media",records:mediaForUnit(unit)});
}

write("final/A2-FINAL-MISSION.json",compatibleMission);
write("assessment/A2-FINAL-ASSESSMENT.json",compatibleAssessment);
const assessmentItems=Object.values(compatibleAssessment.sections).flatMap(section=>section.activities);
write("media/A2-FINAL.json",{moduleSchemaVersion:"1.0.0",unitId:"A2-FINAL",kind:"media",records:mediaForActivities([...compatibleMission.activities,...assessmentItems])});

write("domain.json",{
  SKILLS:{LISTENING:"listening",READING:"reading",WRITING:"writing",SPOKEN_INTERACTION:"spokenInteraction",SPOKEN_PRODUCTION:"spokenProduction",MEDIATION:"mediation"},
  MODES:{ENCOUNTER:"encounter",PRACTICE:"practice",MASTERY:"mastery"},
  ACTIVITY_TYPES:{AUDIO_CHOICE:"audioChoice",TEXT_CHOICE:"textChoice",MATCH:"match",ORDER:"order",GAP:"gap",FORM:"form",SPEAK:"speak",WRITE:"write",DIALOGUE:"dialogue"},
  CAN_DO:allCanDo,
  MASTERY_POLICY:{minimumObjectiveScore:.75,minimumEvidencePerRequiredObjective:2,requireProductiveEvidenceWhereDeclared:true,practiceCountsAsMastery:false,allowSpeechFallbackToWriting:true,speechCriteria:["taskCompletion","intelligibility","appropriateLanguage"],speechAccuracyWeight:.2}
});

write("course.json",{
  schemaVersion:"2.0.0",contentVersion:"A2-COMPLETE-A1-CONTRACT-2026.09.19",locale:{targetLanguage:"en",supportLanguage:"ar",direction:{target:"ltr",support:"rtl"}},
  course:{id:"EN-A2-V1",title:"English A2",titleAr:"اللغة الإنجليزية — المستوى A2",status:"complete-course",completedScope:[...units.map(u=>u.id),compatibleMission.id,compatibleAssessment.id],pendingScope:[],authoredUnitCount:units.length,authoredLessonCount:units.reduce((n,u)=>n+u.lessons.length,0),finalMissionId:compatibleMission.id,finalAssessmentId:compatibleAssessment.id}
});

const unitIds=units.map(u=>u.id);
write("manifest.json",{
  moduleSchemaVersion:"1.0.0",curriculumId:"EN-A2-V1",sourceContentVersion:"A2-COMPLETE-A1-CONTRACT-2026.09.19",entry:{course:"course.json",domain:"domain.json"},
  registries:Object.fromEntries(["grammar","lexicon","chunks"].map(kind=>[kind,unitIds.map(id=>`registries/${kind}/${id}.json`)])),
  units:unitIds.map(id=>`units/${id}.json`),media:[...unitIds.map(id=>`media/${id}.json`),"media/A2-FINAL.json"],
  finalMission:"final/A2-FINAL-MISSION.json",finalAssessment:"assessment/A2-FINAL-ASSESSMENT.json",output:"dist/a2-course-bundle.json",
  policies:{authoringSource:"modules",generatedBundleEditable:false,stableIdsRequired:true,duplicateIdsForbidden:true,unresolvedReferencesForbidden:true,practiceCountsAsMastery:false},
  qualityExpectations:{unitCount:12,lessonCount:84,coreUnitIds:unitIds,coreLessonsPerUnit:7,coreActivitiesPerUnit:36,finalMissionActivities:12,assessment:{listening:18,reading:18,writing:2,speaking:4,mediation:2}}
});

if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  console.log(JSON.stringify({status:"authored",contentVersion:"A2-COMPLETE-A1-CONTRACT-2026.09.19",units:units.length,lessons:units.reduce((n,u)=>n+u.lessons.length,0),finalMission:compatibleMission.id,assessment:{...assessmentCounts,total:Object.values(assessmentCounts).reduce((n,value)=>n+value,0)}},null,2));
}
