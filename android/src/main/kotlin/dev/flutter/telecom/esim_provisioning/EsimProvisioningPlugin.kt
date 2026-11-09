package dev.flutter.telecom.esim_provisioning

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import android.telephony.euicc.DownloadableSubscription
import android.telephony.euicc.EuiccManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class EsimProvisioningPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    private val ACTION_DOWNLOAD_SUBSCRIPTION = "dev.flutter.telecom.esim_provisioning.DOWNLOAD_SUBSCRIPTION"
    private var pendingDownloadResult: Result? = null

    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_DOWNLOAD_SUBSCRIPTION) return
            val pending = pendingDownloadResult ?: return
            pendingDownloadResult = null

            val resultCode = resultCode
            val detailedCode = intent.getIntExtra(EuiccManager.EXTRA_EMBEDDED_SUBSCRIPTION_DETAILED_CODE, 0)

            when (resultCode) {
                EuiccManager.EMBEDDED_SUBSCRIPTION_RESULT_OK -> {
                    pending.success(
                        mapOf(
                            "status" to "success",
                            "errorCode" to "none",
                            "message" to "eSIM profile downloaded and activated successfully."
                        )
                    )
                }

                EuiccManager.EMBEDDED_SUBSCRIPTION_RESULT_RESOLVABLE_ERROR -> {
                    // Try to resolve error with user prompt
                    try {
                        val euiccManager = context?.getSystemService(Context.EUICC_SERVICE) as? EuiccManager
                        val currentActivity = activity
                        if (euiccManager != null && currentActivity != null) {
                            euiccManager.startResolutionActivity(
                                currentActivity,
                                4401,
                                intent,
                                PendingIntent.getActivity(
                                    context,
                                    0,
                                    Intent(context, currentActivity::class.java),
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                            )
                        } else {
                            pending.success(
                                mapOf(
                                    "status" to "failed",
                                    "errorCode" to "systemError",
                                    "message" to "Resolvable error without active activity context"
                                )
                            )
                        }
                    } catch (e: Exception) {
                        pending.success(
                            mapOf(
                                "status" to "failed",
                                "errorCode" to "systemError",
                                "message" to "Failed to start resolution activity: ${e.message}"
                            )
                        )
                    }
                }

                else -> {
                    val errorEnum = mapDetailedCodeToEnum(detailedCode)
                    pending.success(
                        mapOf(
                            "status" to "failed",
                            "errorCode" to errorEnum,
                            "message" to "eSIM installation failed with code $resultCode (detailed: $detailedCode)"
                        )
                    )
                }
            }
        }
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "dev.flutter.telecom/esim_provisioning")
        channel.setMethodCallHandler(this)

        val filter = IntentFilter(ACTION_DOWNLOAD_SUBSCRIPTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(downloadReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(downloadReceiver, filter)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context.unregisterReceiver(downloadReceiver)
        } catch (_: Exception) {}
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val euiccManager = context.getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

        when (call.method) {
            "getCapabilities" -> {
                val isSupported = euiccManager != null && euiccManager.isEnabled
                var eid: String? = null
                if (isSupported) {
                    try {
                        eid = euiccManager?.eid
                    } catch (_: SecurityException) {}
                }

                val hasPrivileges = telephonyManager?.hasCarrierPrivileges() ?: false

                val caps = mapOf(
                    "isSupported" to isSupported,
                    "isEnabled" to isSupported,
                    "eid" to eid,
                    "hasCarrierPrivileges" to hasPrivileges,
                    "supportsDirectDownload" to (isSupported && hasPrivileges),
                    "supportsSystemDialog" to isSupported,
                    "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
                )
                result.success(caps)
            }

            "installProfile" -> {
                if (euiccManager == null || !euiccManager.isEnabled) {
                    result.success(
                        mapOf(
                            "status" to "failed",
                            "errorCode" to "unsupportedDevice",
                            "message" to "eSIM (eUICC) is not supported or not enabled on this device"
                        )
                    )
                    return
                }

                val lpa = call.argument<String>("lpa") ?: ""
                val switchAfter = call.argument<Boolean>("switchAfterDownload") ?: true

                val subscription = DownloadableSubscription.forActivationCode(lpa)
                val hasPrivileges = telephonyManager?.hasCarrierPrivileges() ?: false

                if (hasPrivileges) {
                    // Direct silent download for carrier-entitled applications
                    pendingDownloadResult = result
                    val callbackIntent = PendingIntent.getBroadcast(
                        context,
                        0,
                        Intent(ACTION_DOWNLOAD_SUBSCRIPTION),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    )
                    euiccManager.downloadSubscription(subscription, switchAfter, callbackIntent)
                } else {
                    // Launch Android System eSIM Setup Wizard
                    try {
                        val currentActivity = activity
                        val intent = Intent(EuiccManager.ACTION_PROVISION_EMBEDDED_SUBSCRIPTION).apply {
                            putExtra(EuiccManager.EXTRA_EMBEDDED_SUBSCRIPTION_DOWNLOADABLE_SUBSCRIPTION, subscription)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (currentActivity != null) {
                            currentActivity.startActivity(intent)
                        } else {
                            context.startActivity(intent)
                        }
                        result.success(
                            mapOf(
                                "status" to "success",
                                "errorCode" to "none",
                                "message" to "Android system eSIM provisioning wizard opened"
                            )
                        )
                    } catch (e: Exception) {
                        result.success(
                            mapOf(
                                "status" to "failed",
                                "errorCode" to "systemError",
                                "message" to "Failed to launch Android system eSIM dialog: ${e.message}"
                            )
                        )
                    }
                }
            }

            "openCellularSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (_: Exception) {
                    try {
                        val fallback = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(fallback)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun mapDetailedCodeToEnum(detailedCode: Int): String {
        return when (detailedCode) {
            10001 -> "carrierLocked"
            10002 -> "invalidActivationCode"
            10003 -> "insufficientMemory"
            10004 -> "timeout"
            10005 -> "networkError"
            else -> "systemError"
        }
    }
}
