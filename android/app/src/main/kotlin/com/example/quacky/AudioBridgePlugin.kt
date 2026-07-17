package com.example.quacky

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class AudioBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var context: Context
    private var methodsChannel: MethodChannel? = null
    private var micEventChannel: EventChannel? = null
    private var speakerChannel: MethodChannel? = null

    private var audioRecord: AudioRecord? = null
    private var acousticEchoCanceler: AcousticEchoCanceler? = null
    private var isRecording = false
    private var micSink: EventChannel.EventSink? = null
    private var executorService: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var audioTrack: AudioTrack? = null

    companion object {
        fun registerWith(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
            val plugin = AudioBridgePlugin()
            plugin.methodsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quacky/audio/methods")
            plugin.methodsChannel?.setMethodCallHandler(plugin)

            plugin.micEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "quacky/audio/mic")
            plugin.micEventChannel?.setStreamHandler(plugin)

            plugin.speakerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quacky/audio/speaker")
            plugin.speakerChannel?.setMethodCallHandler(plugin)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodsChannel = MethodChannel(binding.binaryMessenger, "quacky/audio/methods")
        methodsChannel?.setMethodCallHandler(this)

        micEventChannel = EventChannel(binding.binaryMessenger, "quacky/audio/mic")
        micEventChannel?.setStreamHandler(this)

        speakerChannel = MethodChannel(binding.binaryMessenger, "quacky/audio/speaker")
        speakerChannel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodsChannel?.setMethodCallHandler(null)
        micEventChannel?.setStreamHandler(null)
        speakerChannel?.setMethodCallHandler(null)

        stopRecording()
        disposeSpeaker()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> {
                try {
                    startRecording()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("RECORDING_START_FAILED", e.message, null)
                }
            }
            "stopRecording" -> {
                stopRecording()
                result.success(null)
            }
            "isAecAvailable" -> {
                result.success(AcousticEchoCanceler.isAvailable())
            }
            "initSpeaker" -> {
                try {
                    initSpeaker()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SPEAKER_INIT_FAILED", e.message, null)
                }
            }
            "writePcm" -> {
                val data = call.argument<ByteArray>("data")
                if (data != null && audioTrack != null) {
                    audioTrack?.write(data, 0, data.size)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "PCM data or speaker track is null", null)
                }
            }
            "flushSpeaker" -> {
                flushSpeaker()
                result.success(null)
            }
            "disposeSpeaker" -> {
                disposeSpeaker()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        micSink = events
    }

    override fun onCancel(arguments: Any?) {
        micSink = null
    }

    private fun startRecording() {
        if (isRecording) return

        val sampleRateInHz = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioRecord.getMinBufferSize(sampleRateInHz, channelConfig, audioFormat)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            sampleRateInHz,
            channelConfig,
            audioFormat,
            bufferSize * 2
        )

        if (AcousticEchoCanceler.isAvailable() && audioRecord != null) {
            acousticEchoCanceler = AcousticEchoCanceler.create(audioRecord!!.audioSessionId)
            acousticEchoCanceler?.enabled = true
        }

        audioRecord?.startRecording()
        isRecording = true
        executorService = Executors.newSingleThreadExecutor()

        val readBuffer = ByteArray(2048)
        executorService?.submit {
            while (isRecording) {
                val readResult = audioRecord?.read(readBuffer, 0, readBuffer.size) ?: -1
                if (readResult > 0) {
                    val chunk = readBuffer.copyOf(readResult)
                    mainHandler.post {
                        micSink?.success(chunk)
                    }
                }
            }
        }
    }

    private fun stopRecording() {
        isRecording = false
        executorService?.shutdown()
        executorService = null

        acousticEchoCanceler?.enabled = false
        acousticEchoCanceler?.release()
        acousticEchoCanceler = null

        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }

    private fun initSpeaker() {
        if (audioTrack != null) return

        val sampleRateInHz = 24000
        val channelConfig = AudioFormat.CHANNEL_OUT_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioTrack.getMinBufferSize(sampleRateInHz, channelConfig, audioFormat)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()

        val audioFormatObj = AudioFormat.Builder()
            .setSampleRate(sampleRateInHz)
            .setChannelMask(channelConfig)
            .setEncoding(audioFormat)
            .build()

        audioTrack = AudioTrack(
            audioAttributes,
            audioFormatObj,
            bufferSize * 2,
            AudioTrack.MODE_STREAM,
            AudioManager.AUDIO_SESSION_ID_GENERATE
        )

        audioTrack?.play()
    }

    private fun flushSpeaker() {
        if (audioTrack != null) {
            try {
                audioTrack?.pause()
                audioTrack?.flush()
                audioTrack?.play()
            } catch (e: Exception) {
                print("Failed to flush AudioTrack: ${e.message}")
            }
        }
    }

    private fun disposeSpeaker() {
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
    }
}
