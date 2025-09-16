package com.c3.creatorclub

import android.os.Bundle
import android.util.Log
import androidx.annotation.StyleableRes
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterStripe (and some other plugins) require the host Activity to be a FragmentActivity.
// Added lightweight diagnostic logging to verify that an AppCompat/MaterialComponents theme is applied
// when PaymentSheet initialization occurs. Safe to keep in production (debug-level only), remove later if noisy.
class MainActivity : FlutterFragmentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		logThemeDiagnostics()
	}

	private fun logThemeDiagnostics() {
		try {
			val themeResId = theme?.javaClass?.getDeclaredField("mThemeResId")?.let { field ->
				field.isAccessible = true
				field.get(theme)
			}
			Log.d("ThemeCheck", "Activity theme obj=${theme} resId=$themeResId")

			// Probe a few representative AppCompat / Material attributes.
			val attrs = intArrayOf(
				android.R.attr.colorBackground,
				android.R.attr.windowBackground,
				android.R.attr.textColorPrimary,
				android.R.attr.textColorSecondary
			)
			val ta = obtainStyledAttributes(attrs)
			for (i in attrs.indices) {
				val value = ta.peekValue(i)
				Log.d("ThemeCheck", "attr[$i]=${value}")
			}
			ta.recycle()
		} catch (t: Throwable) {
			Log.w("ThemeCheck", "Failed to log theme diagnostics", t)
		}
	}
}
