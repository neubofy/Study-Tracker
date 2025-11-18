package com.neubofy.mindful.utils

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import android.util.Log
import java.util.concurrent.Executor
import android.os.Looper

class BiometricHelper(private val context: Context) {

    fun isBiometricAvailable(): Boolean {
        return try {
            val biometricManager = BiometricManager.from(context)
            val canAuthenticate = biometricManager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            )
            canAuthenticate == BiometricManager.BIOMETRIC_SUCCESS
        } catch (e: Exception) {
            Log.e("BiometricHelper", "Error checking biometric", e)
            false
        }
    }

    fun authenticate(reason: String, callback: (Boolean) -> Unit) {
        try {
            if (!isBiometricAvailable()) {
                callback(false)
                return
            }

            val activity = context as? FragmentActivity ?: run {
                Log.e("BiometricHelper", "Context is not a FragmentActivity")
                callback(false)
                return
            }

            val executor = Executor { command ->
                Looper.getMainLooper().post(command)
            }

            val biometricPrompt = BiometricPrompt(
                activity,
                executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        Log.d("BiometricHelper", "Authentication succeeded")
                        callback(true)
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        Log.e("BiometricHelper", "Authentication error: $errString")
                        callback(false)
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        Log.w("BiometricHelper", "Authentication failed")
                        callback(false)
                    }
                }
            )

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Authenticate")
                .setSubtitle(reason)
                .setNegativeButtonText("Cancel")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                .build()

            biometricPrompt.authenticate(promptInfo)
        } catch (e: Exception) {
            Log.e("BiometricHelper", "Error during authentication", e)
            callback(false)
        }
    }
}
