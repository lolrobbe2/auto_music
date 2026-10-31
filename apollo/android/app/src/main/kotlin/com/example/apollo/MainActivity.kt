package com.example.apollo

import android.os.Bundle
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            val providerInfo = packageManager.resolveContentProvider(
                "com.example.auto_music.artworkcontentprovider",
                0
            )

            Log.i(
                "ArtworkProvider",
                "Resolved provider: ${providerInfo?.name}"
            )

            val provider = contentResolver.acquireContentProviderClient(
                "content://com.example.auto_music.artworkcontentprovider"
            )

            Log.i(
                "ArtworkProvider",
                "Provider client acquired: ${provider != null}"
            )

            provider?.close()
        } catch (exception: Exception) {
            Log.e("ArtworkProvider", "Provider test failed", exception)
        }

        super.onCreate(savedInstanceState)
    }
}