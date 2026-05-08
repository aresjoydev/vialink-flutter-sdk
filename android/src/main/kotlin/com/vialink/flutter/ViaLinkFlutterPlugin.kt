package com.vialink.flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.vialink.sdk.ViaLinkSDK
import com.vialink.sdk.model.DeepLinkData
import com.vialink.sdk.model.PaymentInitiatedArgs
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*

/// ViaLink Flutter Plugin — Android 네이티브 브릿지
///
/// Pigeon 생성 [ViaLinkHostApi]를 구현하여 네이티브 ViaLinkSDK를 호출합니다.
/// Activity의 Intent를 자동 감지하여 딥링크를 처리합니다.
class ViaLinkFlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.NewIntentListener,
    ViaLinkHostApi {

    companion object {
        private const val WRAPPER_VERSION = "2.0.0"
    }

    private var flutterApi: ViaLinkFlutterApi? = null
    private var activity: Activity? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // ──────────────────────────────────────────────
    // FlutterPlugin
    // ──────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ViaLinkHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = ViaLinkFlutterApi(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ViaLinkHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        scope.cancel()
    }

    // ──────────────────────────────────────────────
    // ActivityAware — Intent 자동 처리
    // ──────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(this)
        // 콜드 스타트 시 초기 Intent 처리
        binding.activity.intent?.let { handleIntentIfNeeded(it) }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    /// Warm Start — 새로운 Intent 수신 시 자동 처리
    override fun onNewIntent(intent: Intent): Boolean {
        return handleIntentIfNeeded(intent)
    }

    private fun handleIntentIfNeeded(intent: Intent): Boolean {
        return try {
            ViaLinkSDK.handleIntent(intent)
        } catch (_: Exception) {
            false
        }
    }

    // ──────────────────────────────────────────────
    // ViaLinkHostApi 구현 (Pigeon)
    // ──────────────────────────────────────────────

    override fun configure(apiKey: String) {
        val context = activity?.applicationContext
            ?: throw IllegalStateException("Activity가 아직 연결되지 않았습니다")

        ViaLinkSDK.setWrapperInternal("flutter/$WRAPPER_VERSION")
        ViaLinkSDK.init(context, apiKey)

        // 네이티브 콜백 → Flutter 이벤트
        ViaLinkSDK.onDeepLink { data ->
            flutterApi?.onDeepLink(data.toPigeon()) {}
        }

        ViaLinkSDK.onDeferredDeepLink { data, error ->
            flutterApi?.onDeferredDeepLink(data?.toPigeon(), error?.message) {}
        }

        // 초기 Intent 처리 (configure 후)
        activity?.intent?.let { handleIntentIfNeeded(it) }
    }

    override fun handleDeepLink(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        ViaLinkSDK.handleIntent(intent)
    }

    override fun track(eventName: String, data: Map<String?, String?>?) {
        val cleanData = data?.entries
            ?.filter { it.key != null && it.value != null }
            ?.associate { it.key!! to (it.value!! as Any) }
        ViaLinkSDK.track(eventName, cleanData)
    }

    override fun getDeepLinkData(): VLDeepLinkData? {
        return ViaLinkSDK.getDeepLinkData()?.toPigeon()
    }

    override fun getDeferredLinkData(): VLDeepLinkData? {
        return ViaLinkSDK.getDeferredLinkData()?.toPigeon()
    }

    override fun awaitDeepLinkData(callback: (Result<VLDeepLinkData?>) -> Unit) {
        scope.launch {
            try {
                val data = ViaLinkSDK.awaitDeepLinkData()
                callback(Result.success(data?.toPigeon()))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun awaitDeferredLinkData(callback: (Result<VLDeepLinkData?>) -> Unit) {
        scope.launch {
            try {
                val data = ViaLinkSDK.awaitDeferredLinkData()
                callback(Result.success(data?.toPigeon()))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun createLink(args: VLCreateLinkArgs, callback: (Result<String>) -> Unit) {
        scope.launch {
            try {
                val dataMap = args.data?.entries
                    ?.filter { it.key != null && it.value != null }
                    ?.associate { it.key!! to (it.value!! as Any) }
                val tagsList = args.tags?.filterNotNull()

                val result = ViaLinkSDK.createLink(
                    path = args.path,
                    data = dataMap,
                    campaign = args.campaign,
                    linkType = args.linkType,
                    iosUrl = args.iosUrl,
                    androidUrl = args.androidUrl,
                    webUrl = args.webUrl,
                    ogTitle = args.ogTitle,
                    ogDescription = args.ogDescription,
                    ogImageUrl = args.ogImageUrl,
                    channel = args.channel,
                    feature = args.feature,
                    tags = tagsList,
                    expiresAt = args.expiresAt,
                )
                result.onSuccess { callback(Result.success(it)) }
                result.onFailure { callback(Result.failure(it)) }
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun trackPayment(args: VLPaymentArgs, callback: (Result<VLPaymentResult>) -> Unit) {
        scope.launch {
            try {
                val metadataMap = args.metadata?.entries
                    ?.filter { it.key != null && it.value != null }
                    ?.associate { it.key!! to (it.value as Any?) }

                val payArgs = PaymentInitiatedArgs(
                    orderId = args.orderId,
                    amount = args.amount,
                    currency = args.currency,
                    linkId = args.linkId?.toInt(),
                    paymentMethod = args.paymentMethod,
                    metadata = metadataMap,
                )
                val result = ViaLinkSDK.trackPayment(payArgs)
                callback(Result.success(
                    VLPaymentResult(
                        success = result.success,
                        paymentEventId = result.paymentEventId,
                    )
                ))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }
}

// ──────────────────────────────────────────────
// DeepLinkData → Pigeon 변환
// ──────────────────────────────────────────────

private fun DeepLinkData.toPigeon(): VLDeepLinkData {
    return VLDeepLinkData(
        path = path,
        params = params.mapKeys { it.key },
        shortCode = shortCode,
        linkId = linkId?.toLong(),
    )
}
