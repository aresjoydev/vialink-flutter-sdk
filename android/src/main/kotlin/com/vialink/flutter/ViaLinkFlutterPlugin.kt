package com.vialink.flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.vialink.sdk.ViaLinkSDK
import com.vialink.sdk.model.DeepLinkData
import com.vialink.sdk.model.PaymentInitiatedArgs
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import kotlinx.coroutines.*

class ViaLinkFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        const val WRAPPER_VERSION = "2.1.0"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var deepLinkChannel: EventChannel
    private lateinit var deferredChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null

    private var deepLinkSink: EventChannel.EventSink? = null
    private var deferredSink: EventChannel.EventSink? = null

    // EventSink 연결 전 수신된 이벤트를 임시 보관
    private var pendingDeepLink: Map<String, Any?>? = null
    private var pendingDeferred: Map<String, Any?>? = null

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.vialink.sdk/methods")
        methodChannel.setMethodCallHandler(this)

        deepLinkChannel = EventChannel(binding.binaryMessenger, "com.vialink.sdk/deeplinks")
        deepLinkChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deepLinkSink = events
                // pending 이벤트 flush
                pendingDeepLink?.let { events?.success(it) }
                pendingDeepLink = null
            }
            override fun onCancel(arguments: Any?) { deepLinkSink = null }
        })

        deferredChannel = EventChannel(binding.binaryMessenger, "com.vialink.sdk/deferred")
        deferredChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deferredSink = events
                pendingDeferred?.let { events?.success(it) }
                pendingDeferred = null
            }
            override fun onCancel(arguments: Any?) { deferredSink = null }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val apiKey = call.argument<String>("apiKey")!!
                ViaLinkSDK.setWrapper("flutter/$WRAPPER_VERSION")
                ViaLinkSDK.init(context!!, apiKey)

                // 네이티브 콜백 → EventSink 연결
                ViaLinkSDK.onDeepLink { data ->
                    val map = data.toMap()
                    if (deepLinkSink != null) deepLinkSink?.success(map)
                    else pendingDeepLink = map
                }
                ViaLinkSDK.onDeferredDeepLink { data ->
                    val map = data.toMap()
                    if (deferredSink != null) deferredSink?.success(map)
                    else pendingDeferred = map
                }

                // 초기 Intent 처리 (콜드 스타트)
                activity?.intent?.let { ViaLinkSDK.handleIntent(it) }

                result.success(null)
            }
            "track" -> {
                val eventName = call.argument<String>("eventName")!!
                @Suppress("UNCHECKED_CAST")
                val data = call.argument<Map<String, Any>>("data")
                ViaLinkSDK.track(eventName, data)
                result.success(null)
            }
            "createLink" -> {
                val path = call.argument<String>("path")!!
                @Suppress("UNCHECKED_CAST")
                val data = call.argument<Map<String, Any>>("data")
                val campaign = call.argument<String>("campaign")
                scope.launch {
                    val linkResult = ViaLinkSDK.createLink(path, data, campaign)
                    linkResult.onSuccess { result.success(it) }
                    linkResult.onFailure { result.error("CREATE_LINK_ERROR", it.message, null) }
                }
            }
            "paymentInitiated" -> {
                val args = call.arguments as? Map<String, Any?>
                if (args == null) {
                    result.error("E_INVALID_ARG", "arguments가 필요합니다.", null)
                    return
                }
                val orderId = args["orderId"] as? String
                val amount = (args["amount"] as? Number)?.toDouble()
                val currency = args["currency"] as? String
                if (orderId == null || amount == null || currency == null) {
                    result.error("E_INVALID_ARG", "orderId/amount/currency가 필요합니다.", null)
                    return
                }
                val linkId = (args["linkId"] as? Number)?.toInt()
                val paymentMethod = args["paymentMethod"] as? String
                @Suppress("UNCHECKED_CAST")
                val metadata = args["metadata"] as? Map<String, Any?>

                val payArgs = PaymentInitiatedArgs(
                    orderId = orderId,
                    amount = amount,
                    currency = currency,
                    linkId = linkId,
                    paymentMethod = paymentMethod,
                    metadata = metadata,
                )

                // ViaLinkSDK.payment.initiated(args)는 suspend
                scope.launch {
                    try {
                        val res = ViaLinkSDK.payment.initiated(payArgs)
                        result.success(
                            mapOf(
                                "success" to res.success,
                                "paymentEventId" to res.paymentEventId,
                            )
                        )
                    } catch (e: Exception) {
                        result.error("E_PAYMENT_FAILED", e.message ?: e.toString(), null)
                    }
                }
            }
            "dispose" -> {
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ActivityAware — App Links Intent 자동 처리
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener { intent ->
            ViaLinkSDK.handleIntent(intent)
            true
        }
    }

    override fun onDetachedFromActivity() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        scope.cancel()
    }
}

// DeepLinkData → Map 변환
private fun DeepLinkData.toMap(): Map<String, Any?> = mapOf(
    "path" to path,
    "params" to params,
    "shortCode" to shortCode
)
