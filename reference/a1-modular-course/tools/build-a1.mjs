import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const defaultRoot=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const read=(root,relative)=>JSON.parse(readFileSync(resolve(root,relative),"utf8"));

export function buildCourse(root=defaultRoot,{writeOutput=true}={}){
  const manifest=read(root,"manifest.json");
  const meta=read(root,manifest.entry.course);
  const domain=read(root,manifest.entry.domain);
  const loadRegistry=kind=>manifest.registries[kind].flatMap(file=>read(root,file).records);
  const units=manifest.units.map(file=>read(root,file));
  const mediaSpecifications=Object.assign({},...manifest.media.map(file=>read(root,file).records));
  const bundle={...meta,domain,grammar:loadRegistry("grammar"),lexicon:loadRegistry("lexicon"),chunks:loadRegistry("chunks"),units,mediaSpecifications};
  if(manifest.finalMission)bundle.finalMission=read(root,manifest.finalMission);
  if(manifest.finalAssessment)bundle.finalAssessment=read(root,manifest.finalAssessment);
  if(writeOutput){const output=resolve(root,manifest.output);mkdirSync(dirname(output),{recursive:true});writeFileSync(output,`${JSON.stringify(bundle,null,2)}\n`,`utf8`);}
  return {manifest,bundle};
}

if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  const {manifest,bundle}=buildCourse();
  console.log(JSON.stringify({status:"built",contentVersion:bundle.contentVersion,units:bundle.units.length,output:manifest.output},null,2));
}
