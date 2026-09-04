import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = resolve(root, "../full-cefr-curriculum/a1-course-u0-u3.json");
const course = JSON.parse(readFileSync(source,"utf8"));
const write = (relative,value) => {
  const path=resolve(root,relative); mkdirSync(dirname(path),{recursive:true});
  writeFileSync(path,`${JSON.stringify(value,null,2)}\n`,`utf8`);
};
const owner = record => {
  const match=String(record.introducedIn||"").match(/^A1-U(\d+)/);
  if(!match)throw new Error(`Cannot determine owner for ${record.id}`);
  return `A1-U${match[1]}`;
};
const units=course.units.map(unit=>unit.id);
const groupRecords = (records,kind) => {
  const files=[];
  for(const unitId of units){
    const owned=records.filter(record=>owner(record)===unitId);
    const relative=`registries/${kind}/${unitId}.json`;
    write(relative,{moduleSchemaVersion:"1.0.0",unitId,kind,records:owned});
    files.push(relative);
  }
  return files;
};

write("course.json",{
  schemaVersion:course.schemaVersion,
  contentVersion:course.contentVersion,
  locale:course.locale,
  course:course.course
});
write("domain.json",course.domain);
for(const unit of course.units)write(`units/${unit.id}.json`,unit);

const mediaFiles=[];
for(const unit of course.units){
  const refs=new Set(unit.lessons.flatMap(lesson=>lesson.activities.filter(a=>a.optionMode==="media").flatMap(a=>a.options||[])));
  const records=Object.fromEntries([...refs].map(ref=>{
    const spec=course.mediaSpecifications?.[ref];
    if(!spec)throw new Error(`${unit.id} references missing media ${ref}`);
    return [ref,spec];
  }));
  const relative=`media/${unit.id}.json`;
  write(relative,{moduleSchemaVersion:"1.0.0",unitId:unit.id,kind:"media",records});
  mediaFiles.push(relative);
}

const manifest={
  moduleSchemaVersion:"1.0.0",
  curriculumId:course.course.id,
  sourceContentVersion:course.contentVersion,
  entry:{course:"course.json",domain:"domain.json"},
  registries:{
    grammar:groupRecords(course.grammar,"grammar"),
    lexicon:groupRecords(course.lexicon,"lexicon"),
    chunks:groupRecords(course.chunks,"chunks")
  },
  units:course.units.map(unit=>`units/${unit.id}.json`),
  media:mediaFiles,
  output:"dist/a1-course-bundle.json",
  policies:{
    authoringSource:"modules",
    generatedBundleEditable:false,
    stableIdsRequired:true,
    duplicateIdsForbidden:true,
    unresolvedReferencesForbidden:true,
    practiceCountsAsMastery:false
  }
};
write("manifest.json",manifest);
console.log(`Modularized ${course.contentVersion} into ${root}`);
