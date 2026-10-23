# ONNX Runtime's Java layer is reached from native code by name; R8 strips
# it from a release build and the first inference aborts the process (seen
# in Mohingo itself, 2026-10-23). Same rule as android/app/proguard-rules.pro
# in the app.
-keep class ai.onnxruntime.** { *; }
