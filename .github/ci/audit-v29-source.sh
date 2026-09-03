#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:?source root required}"
export ROOT
python3 - <<'PY'
from pathlib import Path
import os,re
root=Path(os.environ['ROOT'])
def read(rel):
    p=root/rel
    if not p.exists(): raise SystemExit(f'AUDIT FAIL: missing {rel}')
    return p.read_text()
event=read('app/src/main/java/com/ludusassistant/app/data/EventStore.java'); ocr=read('app/src/main/java/com/ludusassistant/app/vision/OcrEngine.java'); main=read('app/src/main/java/com/ludusassistant/app/MainActivity.java'); obs=read('app/src/main/java/com/ludusassistant/app/data/ObservationEngine.java'); capture=read('app/src/main/java/com/ludusassistant/app/capture/CaptureService.java'); parser=read('app/src/main/java/com/ludusassistant/app/vision/parser/ScreenTextParser.java'); receiver=read('app/src/main/java/com/ludusassistant/app/data/RefreshReceiver.java'); gradle=read('app/build.gradle'); manifest=read('app/src/main/AndroidManifest.xml'); appstore=read('app/src/main/java/com/ludusassistant/app/data/AppStore.java'); guide=read('app/src/main/java/com/ludusassistant/app/data/GuideRepository.java'); hero=read('app/src/main/java/com/ludusassistant/app/hero/HeroRepository.java')
checks=[
('EventStore indexed JSONArray.put is exception-safe',re.search(r'try\\s*\\{\\s*a\\.put\\(i,event\\)',event)is not None),
('EventStore append uses Android JSONArray.put(Object) directly',re.search(r'if\\(!found\\)a\\.put\\(event\\)',event)is not None and 'if(!found){try{a.put(event)' not in event),
('OCR rejects unsupported format with OR guard','image.getFormat()!=android.graphics.PixelFormat.RGBA_8888||image.getPlanes().length==0' in ocr),
('OCR uses reduced 540px working width','int maxW=540' in ocr),
('OCR uses one primary recognizer with failure-only fallback','primary.process(input)' in ocr and 'latin.process(input)' in ocr),
('Capture frame gate is 300ms','lastFrameNs < 300_000_000L' in capture),
('MainActivity hourly runnable is self-referential safely','new Runnable(){ @Override public void run(){ render(); handler.postDelayed(this' in main),
('MainActivity build returns ScrollView','private ScrollView build()' in main),
('MainActivity renders canonical resource catalog','LudusResourceCatalog.definitions()' in main),
('ObservationEngine uses canonical resource catalog','LudusResourceCatalog.definitions()' in obs),
('CaptureService persists fresh account snapshot after observation','snapshots.save(AccountSnapshotBuilder.fromObserved' in capture),
('Install classification precedes generic ad classification',parser.find('EXTERNAL_APP_INSTALL') < parser.find('ADVERTISEMENT')),
('RefreshReceiver does not falsely mark sync complete','markSync()' not in receiver),
('JUnit dependency is present',"testImplementation 'junit:junit:4.13.2'" in gradle),
('MediaProjection permission declared','android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION' in manifest),
('MediaProjection service type declared','android:foregroundServiceType="mediaProjection"' in manifest),
('AppStore persists resource and ledger together','putString(RES,before.toString()).putString(LOG,log.toString()).apply()' in appstore),
('Guide replacement clears refresh-due flag only on actual replacement','putBoolean("refresh_due",false)' in guide),
('Hero catalog contains 100 unique catalog entries',len(re.findall(r'add\\("\\w+","[^"]+"',hero))==100),
('Hero catalog has current 1.37 additions','"1.37.0","NR"' in hero and '"space_invaders"' in hero),
('Real JUnit tests exist',Path(root/'app/src/test/java/com/ludusassistant/app/automation/AutomationPlannerTest.java').exists() and Path(root/'app/src/test/java/com/ludusassistant/app/vision/parser/VisionParserTest.java').exists()),]
failed=[]
for name,ok in checks:
 print(('PASS ' if ok else 'FAIL ')+name)
 if not ok: failed.append(name)
if failed: raise SystemExit('AUDIT FAILED: '+'; '.join(failed))
print(f'AUDIT PASS: {len(checks)} invariants')
PY
