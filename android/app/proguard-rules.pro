# O plugin google_mlkit_text_recognition referencia os reconhecedores de
# outros alfabetos mesmo quando só o latino é usado. Como não incluímos
# essas dependências opcionais, o R8 só precisa ignorá-las.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
