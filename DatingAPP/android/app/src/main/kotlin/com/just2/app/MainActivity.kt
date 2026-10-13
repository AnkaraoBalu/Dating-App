package com.just2.app

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.facetec.sdk.FaceTecInitializationError
import com.facetec.sdk.FaceTecSDK
import com.facetec.sdk.FaceTecSDKInstance
import com.facetec.sdk.FaceTecSessionRequestProcessor
import com.facetec.sdk.FaceTecSessionResult
import com.facetec.sdk.FaceTecSessionStatus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val deviceKeyIdentifier = "dRbnBk7c4UYUsDSYRoe3xbSLOk3C3W2m"
    private var sdkInstance: FaceTecSDKInstance? = null
    private var pendingResult: MethodChannel.Result? = null
    private var initializationInProgress = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "startLiveness") {
                    result.notImplemented()
                } else if (pendingResult != null) {
                    result.error("SESSION_ACTIVE", "A FaceTec session is already active.", null)
                } else {
                    pendingResult = result
                    initializeAndStart()
                }
            }
    }

    private fun initializeAndStart() {
        sdkInstance?.let {
            it.start3DLiveness(this, SessionProcessor())
            return
        }
        if (initializationInProgress) return
        initializationInProgress = true
        FaceTecSDK.initializeWithSessionRequest(
            this,
            deviceKeyIdentifier,
            SessionProcessor(),
            object : FaceTecSDK.InitializeCallback {
                override fun onSuccess(instance: FaceTecSDKInstance) {
                    initializationInProgress = false
                    sdkInstance = instance
                    instance.start3DLiveness(this@MainActivity, SessionProcessor())
                }

                override fun onError(error: FaceTecInitializationError) {
                    initializationInProgress = false
                    finishWithError("FACETEC_INIT", "FaceTec initialization failed: $error")
                }
            },
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val sessionResult: FaceTecSessionResult? =
            FaceTecSDK.getActivitySessionResult(requestCode, resultCode, data)
        if (sessionResult != null) {
            val sessionCompleted = sessionResult.status == FaceTecSessionStatus.SESSION_COMPLETED
            pendingResult?.success(sessionCompleted)
            pendingResult = null
        }
    }

    private fun finishWithError(code: String, message: String) {
        pendingResult?.error(code, message, null)
        pendingResult = null
    }

    private inner class SessionProcessor : FaceTecSessionRequestProcessor {
        override fun onSessionRequest(
            sessionRequestBlob: String,
            callback: FaceTecSessionRequestProcessor.Callback,
        ) {
            FACETEC_IO.execute {
                var connection: HttpURLConnection? = null
                try {
                    connection = URL(TESTING_API_ENDPOINT).openConnection() as HttpURLConnection
                    connection.requestMethod = "POST"
                    connection.connectTimeout = 20_000
                    connection.readTimeout = 120_000
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.setRequestProperty("X-Device-Key", deviceKeyIdentifier)
                    connection.setRequestProperty(
                        "X-Testing-API-Header",
                        FaceTecSDK.getTestingAPIHeader(),
                    )
                    connection.outputStream.use { output ->
                        output.write(
                            JSONObject().put("requestBlob", sessionRequestBlob)
                                .toString().toByteArray(Charsets.UTF_8),
                        )
                    }
                    val status = connection.responseCode
                    val responseStream =
                        if (status in 200..299) connection.inputStream else connection.errorStream
                    val body = responseStream?.bufferedReader()?.use { it.readText() }.orEmpty()
                    if (status !in 200..299) {
                        throw IllegalStateException("FaceTec Testing API returned HTTP $status")
                    }
                    val responseBlob = JSONObject(body).optString("responseBlob")
                    if (responseBlob.isBlank()) {
                        throw IllegalStateException("FaceTec response did not include responseBlob")
                    }
                    mainHandler.post { callback.processResponse(responseBlob) }
                } catch (error: Exception) {
                    Log.e("Just2FaceTec", "FaceTec test session request failed", error)
                    mainHandler.post {
                        callback.abortOnCatastrophicError()
                        finishWithError(
                            "FACETEC_REQUEST",
                            "FaceTec test request failed. Check network and test account setup.",
                        )
                    }
                } finally {
                    connection?.disconnect()
                }
            }
        }
    }

    companion object {
        private const val CHANNEL = "just2/facetec"
        private const val TESTING_API_ENDPOINT =
            "https://api.facetec.com/api/v4/biometrics/process-request"
        private val FACETEC_IO = Executors.newSingleThreadExecutor()
    }
}
