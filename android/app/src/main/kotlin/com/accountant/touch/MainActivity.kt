package com.accountant.touch

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.accountant.touch/secrets"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // ═══════════════════════════════════════════════════════════
        // 🔐 قناة اتصال آمنة بين Flutter و Kotlin
        // ═══════════════════════════════════════════════════════════
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getActivationSecret" -> {
                    result.success(SecretKeys.getActivationSecret())
                }
                "getBackupMagic" -> {
                    result.success(SecretKeys.getBackupMagic())
                }
                "getTimeSecret" -> {
                    result.success(SecretKeys.getTimeSecret())
                }
                "validateKeys" -> {
                    result.success(SecretKeys.validateKeys())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
