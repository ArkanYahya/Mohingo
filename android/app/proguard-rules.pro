# ONNX Runtime's Java layer is reached from native code by name. R8's
# shrinking of a release build removes or renames what it cannot see called,
# and the first inference then aborts the process from JNI ("JNI DETECTED
# ERROR IN APPLICATION: mid == null") — the app exits the moment a free
# answer with a model answer is checked (first seen on a phone 2026-10-23).
# Keep the whole package. See docs/TECH_STACK.md, "Grading signals", and
# https://onnxruntime.ai/docs/build/android.html (ProGuard rules for R8).
-keep class ai.onnxruntime.** { *; }
