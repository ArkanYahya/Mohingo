# 0008: Speech audio is pre-generated at authoring time and bundled, not synthesized on the device

**Status:** Accepted (2026-09-22)

## Context

Every learning feature that speaks — lesson conversations, listening tasks, partner turns in speaking tasks, model texts, key phrases, vocabulary and grammar playback — reads a verbatim curriculum-bundle string through `TextToSpeechService`, which until now wrapped the phone's own text-to-speech engine (`flutter_tts`). The bundle shipped no audio at all (ADR 0004, `docs/DATA_MODEL.md`). The product owner found the resulting voices robotic and unprofessional on real phones.

Three options were researched (see `docs/superpowers/specs/2026-09-22-bundled-audio-design.md`):

1. **An online engine when connected, the device engine offline.** Rejected. A cloud engine inside the app needs an API key in the binary, which `docs/SECURITY.md` forbids, or a proxy, which ADR 0004 forbids. The keyless endpoints (Google Translate, Edge read-aloud) are unofficial, unlicensed for app use, and break without notice. It would also make the same lesson sound different online and offline.
2. **A better built-in engine.** Rejected as the fix. Higher-quality system voices exist but the user must download them in system settings, Siri voices are closed to third-party apps, iOS 26 ignores voice selection by language, and mid-range Android phones keep the voice the owner complained about. Bundling an open on-device neural engine (Kokoro ~215 MB, Piper, Supertonic) was also rejected: heavier than the audio itself, slower than real time on many phones, and pointless when every string is known in advance.
3. **Pre-generate every clip at authoring time and bundle it.** Chosen, with one correction to the owner's proposal: not Google Translate, whose audio carries no licence, but a licensed engine.

The census behind the decision: 3,140 unique speakable strings across A1 and A2, ~161k characters, ~3.2 hours of speech, roughly 50 MB at 32 kbps mono AAC. Well under Google Play's 200 MB mobile-data threshold and Apple's 200 MB cellular threshold.

## Decision

- Every speakable bundle string ships as an audio clip under `assets/audio/en/<LEVEL>/`, with a per-level `manifest.json` keyed by a normalised-text hash and a role (teacher, a dialogue speaker, or the partner voice). Format: mono AAC-LC `.m4a`, 32 kbps, 24 kHz.
- Clips are produced by a Python authoring tool in `tool/audio/`, run only on the authoring machine, never in the app. The engine is **Kokoro-82M v1.0** (Apache 2.0) via `kokoro-onnx`: free, no account, deterministic, permissive licence for the output. The engine is a module boundary; a cloud engine such as Google Chirp 3 HD may be added later, and its key then lives only in the tool (`docs/SECURITY.md`).
- Audio generated with Apple or Google *system* voices is never bundled: Apple states system voices cannot be commercialised, and Google's engine terms give no licence either.
- The app plays clips through `audioplayers`; the device engine stays only as a fallback for text that has no clip. "Slower" becomes playback rate. Pitch no longer applies.
- The level gate suite requires a released level to ship a manifest matching its `contentVersion`, a clip for every speakable string in the role the app asks for, no orphan files, and a 60 MB per-level budget.

## Alternatives considered

- **Runtime synthesis with the best installed voice** (select by the `quality` flag, deep-link to voice download). Cheap, keeps the low floor. Not chosen; the clip fallback path still benefits from it later if wanted.
- **Google Cloud Chirp 3 HD as the generator.** Better voices, free within 1M characters a month, official terms allow using the audio in applications, but needs a Google Cloud project with a billing account. Kept as the documented upgrade path; the tool's engine boundary exists for it.
- **ElevenLabs / OpenAI TTS.** Paid per character; ElevenLabs' free tier has no commercial licence. Not needed at this quality bar.
- **On-demand audio packs** (Play Asset Delivery, Background Assets). Deferred to when the total would cross the 200 MB threshold; contradicts ADR 0004's "everything bundled" for v1 today.

## Consequences

- The app download grows by roughly 50 MB for A1 and A2 together. Each new level adds its audio; `docs/LEVEL_STANDARD.md` records the cost and the budget.
- `docs/DATA_MODEL.md` and `docs/TECH_STACK.md` no longer say the bundle ships no audio; the `ttsSource` media specifications remain modelled and unused.
- Adding or editing a spoken string in a bundle is not done until the level's audio is regenerated (`python tool/audio/generate_audio.py --level A1`) and the gate passes. `contentVersion` and the manifest move together.
- Two-person A2 listening transcripts without speaker labels play in one voice; marking turns is a content change for a later batch.
- The bilingual rule is untouched: only English is spoken, as before.
- Not verified on a real device in this environment, like every other device-dependent guarantee (README "Known limitations").
