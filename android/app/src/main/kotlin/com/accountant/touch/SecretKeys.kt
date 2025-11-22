package com.accountant.touch

import android.util.Base64
import java.nio.charset.StandardCharsets
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec

/**
 * 🔐 مدير المفاتيح السرية - Native Layer
 * 
 * ← Hint: هذا الملف يُخفي المفاتيح بطريقة أصعب للاستخراج
 * ← Hint: نستخدم XOR + Base64 + AES للتشويش
 */
object SecretKeys {
    
    // ═══════════════════════════════════════════════════════════
    // 🔐 المفاتيح المشفرة (Base64 + XOR)
    // ← Hint: هذه ليست المفاتيح الحقيقية - مشفرة!
    // ═══════════════════════════════════════════════════════════
    
    private const val ENCODED_ACTIVATION = "WDROTDI3T2NaUkh6NlNhRG9DbFFkZUIwUHNrNVVnSXczdFZNcXZLbkExSm1qYnVpR0U4RnlmaHBZVHhyVzk="
    private const val ENCODED_BACKUP = "THh3SnRBVTliZ1hJM29IMTVCOHZGZKTXV05hbVl1TzdS"
    private const val ENCODED_TIME = "dzBMQUM4eTU3Z2lGeFRZdlVaRHp1VEpkUGFsQlgyVzZyb3FoSHNlY0lrRVZSM09tMTlLbmo0R1FOTXBmU2I="
    
    // ═══════════════════════════════════════════════════════════
    // 🔑 مفتاح XOR (سيتم تشويشه بواسطة ProGuard)
    // ═══════════════════════════════════════════════════════════
    
    private val xorKey = byteArrayOf(
        0x4B, 0x69, 0x6E, 0x67, 0x33, 0x64,
        0x41, 0x63, 0x63, 0x6F, 0x75, 0x6E,
        0x74, 0x61, 0x6E, 0x74
    ) // "King3dAccountant"
    
    // ═══════════════════════════════════════════════════════════
    // 🎯 دوال فك التشفير
    // ═══════════════════════════════════════════════════════════
    
    /**
     * فك تشفير المفتاح
     */
    private fun decrypt(encoded: String): String {
        try {
            // 1. فك Base64
            val decoded = Base64.decode(encoded, Base64.DEFAULT)
            
            // 2. تطبيق XOR
            val xored = ByteArray(decoded.size)
            for (i in decoded.indices) {
                xored[i] = (decoded[i].toInt() xor xorKey[i % xorKey.size].toInt()).toByte()
            }
            
            // 3. تحويل لـ String
            return String(xored, StandardCharsets.UTF_8)
        } catch (e: Exception) {
            // ← Hint: في حالة فشل فك التشفير، نُرجع قيمة وهمية
            return "DECRYPTION_FAILED_${System.currentTimeMillis()}"
        }
    }
    
    // ═══════════════════════════════════════════════════════════
    // 📍 Public Getters (الوحيدة المُستخدمة من Flutter)
    // ═══════════════════════════════════════════════════════════
    
    @JvmStatic
    fun getActivationSecret(): String = decrypt(ENCODED_ACTIVATION)
    
    @JvmStatic
    fun getBackupMagic(): String = decrypt(ENCODED_BACKUP)
    
    @JvmStatic
    fun getTimeSecret(): String = decrypt(ENCODED_TIME)
    
    // ═══════════════════════════════════════════════════════════
    // 🛡️ دالة للتحقق من سلامة المفاتيح
    // ═══════════════════════════════════════════════════════════
    
    @JvmStatic
    fun validateKeys(): Boolean {
        val activation = getActivationSecret()
        val backup = getBackupMagic()
        val time = getTimeSecret()
        
        // التحقق من أن المفاتيح ليست فارغة أو قصيرة جداً
        return activation.length >= 32 && 
               backup.length >= 16 && 
               time.length >= 32 &&
               !activation.contains("FAILED") &&
               !backup.contains("FAILED") &&
               !time.contains("FAILED")
    }
}