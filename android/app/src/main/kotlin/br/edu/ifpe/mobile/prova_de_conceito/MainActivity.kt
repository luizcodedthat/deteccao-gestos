package br.edu.ifpe.mobile.prova_de_conceito // Substitua pelo package name real do seu app

import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker.HandLandmarkerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "br.edu.ifpe.mobile.mediapipe/hand_tracking"
    private var handLandmarker: HandLandmarker? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "extractLandmarks") {
                val imagePath = call.argument<String>("imagePath")

                if (imagePath != null) {
                    try {
                        val points = processImage(imagePath)
                        result.success(points)
                    } catch (e: Exception) {
                        result.error("MEDIAPIPE_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Caminho da imagem é nulo", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun processImage(imagePath: String): List<Map<String, Double>> {
        // 1. Inicializa o modelo (Lazy)
        if (handLandmarker == null) {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumHands(1)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
        }

        // 2. Carrega a imagem do arquivo físico para Bitmap
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw Exception("Não foi possível decodificar a imagem no caminho: $imagePath")

        // 3. Converte para o formato do MediaPipe
        val mpImage = BitmapImageBuilder(bitmap).build()

        // 4. Executa a inferência
        val result = handLandmarker!!.detect(mpImage)

        // 5. Mapeia os resultados de volta para o Flutter
        val pointsList = mutableListOf<Map<String, Double>>()

        if (result.landmarks().isNotEmpty()) {
            val firstHand = result.landmarks()[0]
            for (landmark in firstHand) {
                val pointMap = mapOf(
                    "x" to landmark.x().toDouble(),
                    "y" to landmark.y().toDouble(),
                    "z" to landmark.z().toDouble()
                )
                pointsList.add(pointMap)
            }
        }

        return pointsList
    }
}