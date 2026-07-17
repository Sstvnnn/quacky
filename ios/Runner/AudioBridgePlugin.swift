import Flutter
import UIKit
import AVFoundation

public class AudioBridgePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var methodsChannel: FlutterMethodChannel?
  private var micEventChannel: FlutterEventChannel?
  private var speakerChannel: FlutterMethodChannel?

  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()

  private let micTargetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000.0, channels: 1, interleaved: false)!
  private let speakerTargetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000.0, channels: 1, interleaved: false)!

  private var micSink: FlutterEventSink?
  private var isRecording = false
  private var isSpeakerInitialized = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AudioBridgePlugin()

    instance.methodsChannel = FlutterMethodChannel(name: "quacky/audio/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.methodsChannel!)

    instance.micEventChannel = FlutterEventChannel(name: "quacky/audio/mic", binaryMessenger: registrar.messenger())
    instance.micEventChannel?.setStreamHandler(instance)

    instance.speakerChannel = FlutterMethodChannel(name: "quacky/audio/speaker", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.speakerChannel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startRecording":
      do {
        try startRecording()
        result(nil)
      } catch {
        result(FlutterError(code: "MIC_START_FAILED", message: error.localizedDescription, details: nil))
      }

    case "stopRecording":
      stopRecording()
      result(nil)

    case "isAecAvailable":
      result(true)

    case "initSpeaker":
      do {
        try initSpeaker()
        result(nil)
      } catch {
        result(FlutterError(code: "SPEAKER_INIT_FAILED", message: error.localizedDescription, details: nil))
      }

    case "writePcm":
      guard let args = call.arguments as? [String: Any],
            let flutterData = args["data"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing audio data", details: nil))
        return
      }
      writePcm(flutterData.data)
      result(nil)

    case "flushSpeaker":
      flushSpeaker()
      result(nil)

    case "disposeSpeaker":
      disposeSpeaker()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    micSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    micSink = nil
    return nil
  }

  private func startRecording() throws {
    if isRecording { return }

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
    try audioSession.setActive(true)

    let inputNode = audioEngine.inputNode
    let inputFormat = inputNode.inputFormat(forBus: 0)

    guard let converter = AVAudioConverter(from: inputFormat, to: micTargetFormat) else {
      throw NSError(domain: "AudioBridgePlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create mic audio converter"])
    }

    inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
      guard let self = self, self.isRecording else { return }

      let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
        outStatus.pointee = .haveData
        return buffer
      }

      let targetBuffer = AVAudioPCMBuffer(pcmFormat: self.micTargetFormat, frameCapacity: 1024)!
      var error: NSError?

      converter.convert(to: targetBuffer, error: &error, withInputFrom: inputCallback)

      if let error = error {
        print("Mic conversion error: \(error)")
        return
      }

      if let channelData = targetBuffer.int16ChannelData {
        let length = Int(targetBuffer.frameLength) * 2
        let data = Data(bytes: channelData[0], count: length)

        DispatchQueue.main.async {
          self.micSink?(data)
        }
      }
    }

    if !audioEngine.isRunning {
      try audioEngine.start()
    }

    isRecording = true
  }

  private func stopRecording() {
    if !isRecording { return }
    audioEngine.inputNode.removeTap(onBus: 0)
    isRecording = false

    if !playerNode.isPlaying {
      audioEngine.stop()
    }
  }

  private func initSpeaker() throws {
    if isSpeakerInitialized { return }

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
    try audioSession.setActive(true)

    audioEngine.attach(playerNode)

    let mainMixer = audioEngine.mainMixerNode
    audioEngine.connect(playerNode, to: mainMixer, format: speakerTargetFormat)

    if !audioEngine.isRunning {
      try audioEngine.start()
    }

    playerNode.play()
    isSpeakerInitialized = true
  }

  private func writePcm(_ data: Data) {
    guard isSpeakerInitialized, playerNode.isPlaying else { return }

    let frameCount = UInt32(data.count / 2)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: speakerTargetFormat, frameCapacity: frameCount) else {
      return
    }

    buffer.frameLength = frameCount

    data.withUnsafeBytes { rawBufferPointer in
      if let baseAddress = rawBufferPointer.baseAddress {
        let sourceInt16 = baseAddress.assumingMemoryBound(to: Int16.self)
        if let targetInt16 = buffer.int16ChannelData?[0] {
          targetInt16.initialize(from: sourceInt16, count: Int(frameCount))
        }
      }
    }

    playerNode.scheduleBuffer(buffer, completionHandler: nil)
  }

  private func flushSpeaker() {
    if isSpeakerInitialized {
      playerNode.stop()
      playerNode.play()
    }
  }

  private func disposeSpeaker() {
    if isSpeakerInitialized {
      playerNode.stop()
      audioEngine.detach(playerNode)
      isSpeakerInitialized = false

      if !isRecording {
        audioEngine.stop()
      }
    }
  }
}
