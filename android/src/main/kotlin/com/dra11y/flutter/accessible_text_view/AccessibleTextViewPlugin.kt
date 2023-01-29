package com.dra11y.flutter.accessible_text_view

import android.content.res.AssetManager
import android.graphics.Typeface
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import java.nio.charset.Charset

@Serializable
data class FontManifestEntry(
  val family: String,
  val fonts: List<Asset>,
) {
  @Serializable
  data class Asset(
    val asset: String,
  )
}

class FontRegistry {
  companion object {
    private const val defaultFontFamily = "MaterialIcons"
    private val registeredTypefaces = mutableMapOf<String, Typeface>()

    fun resolve(family: String?): Typeface? =
      family?.let { registeredTypefaces[it] } ?: Typeface.DEFAULT

    fun registerTypefaces(binding: FlutterPlugin.FlutterPluginBinding) {
      val assetManager: AssetManager = binding.applicationContext.assets
      val manifestPath = binding.flutterAssets.getAssetFilePathByName("FontManifest.json")
      val manifestText = assetManager.open(manifestPath).reader(Charset.forName("utf-8")).readText()
      val manifest = Json.decodeFromString<List<FontManifestEntry>>(manifestText)

      manifest.forEach { entry ->
        val family = entry.family.split("/").last()
        entry.fonts.forEach { font ->
          val assetPath = binding.flutterAssets.getAssetFilePathByName(font.asset)
          Typeface.createFromAsset(assetManager, assetPath)?.let { typeface ->
            registeredTypefaces[family] = typeface
          }
        }
      }
    }
  }
}

/** AccessibleTextViewPlugin */
class AccessibleTextViewPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "accessible_text_view")
    channel.setMethodCallHandler(this)
    FontRegistry.registerTypefaces(flutterPluginBinding)
    flutterPluginBinding.platformViewRegistry
      .registerViewFactory("com.dra11y.flutter/accessible_text_view", AccessibleTextViewFactory(flutterPluginBinding.binaryMessenger))
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
