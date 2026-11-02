/*
 * Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.blackberry.settings;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.os.SystemProperties;
import android.provider.MediaStore;
import android.util.Log;

import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;

import androidx.preference.Preference;
import androidx.preference.PreferenceFragmentCompat;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Collects a diagnostics bundle through the collect_diagnostics init service
 * (tools/collect-diagnostics.sh) and saves it to the Download folder.
 */
public class CollectLogsActivity extends CollapsingToolbarBaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState == null) {
            getSupportFragmentManager()
                    .beginTransaction()
                    .replace(com.android.settingslib.collapsingtoolbar.R.id.content_frame,
                            new CollectLogsFragment())
                    .commit();
        }
    }

    public static class CollectLogsFragment extends PreferenceFragmentCompat {

        private static final String TAG = "CollectLogs";

        private static final String KEY_COLLECT = "collect_logs";
        private static final String KEY_STATUS = "collect_logs_status";
        private static final String KEY_SHARE = "collect_logs_share";

        // Read by init, which starts the collect_diagnostics service
        private static final String PROP_COLLECT = "sys.diagnostics.collect";
        // Set by the service: running, then done or failed
        private static final String PROP_STATUS = "sys.diagnostics.status";
        private static final String STATUS_STARTING = "starting";
        private static final String STATUS_RUNNING = "running";
        private static final String STATUS_DONE = "done";
        private static final String STATUS_FAILED = "failed";

        // Must match OUT in collect-diagnostics-service
        private static final String OUT_DIR = "diagnostics";
        private static final String ARCHIVE_SUFFIX = ".tar.gz";
        private static final String ARCHIVE_MIME_TYPE = "application/gzip";

        private static final long POLL_INTERVAL_MS = 1000;
        private static final long TIMEOUT_MS = 20 * 60 * 1000;

        private final Handler mHandler = new Handler(Looper.getMainLooper());
        private final ExecutorService mExecutor = Executors.newSingleThreadExecutor();
        private final Runnable mPoll = this::poll;

        private Preference mCollect;
        private Preference mStatus;
        private Preference mShare;
        private Uri mSavedUri;
        private long mStartTime;

        @Override
        public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
            setPreferencesFromResource(R.xml.collect_logs, rootKey);
            mCollect = findPreference(KEY_COLLECT);
            mStatus = findPreference(KEY_STATUS);
            mShare = findPreference(KEY_SHARE);
        }

        @Override
        public void onResume() {
            super.onResume();
            // Collection carries on while this screen is closed, so pick it up again.
            String status = SystemProperties.get(PROP_STATUS);
            if (STATUS_STARTING.equals(status) || STATUS_RUNNING.equals(status)) {
                mStartTime = SystemClock.elapsedRealtime();
                showRunning();
                mHandler.post(mPoll);
            } else if (STATUS_DONE.equals(status) && findArchive() != null) {
                save();
            }
        }

        @Override
        public void onPause() {
            super.onPause();
            mHandler.removeCallbacks(mPoll);
        }

        @Override
        public void onDestroy() {
            super.onDestroy();
            mExecutor.shutdown();
        }

        @Override
        public boolean onPreferenceTreeClick(Preference preference) {
            if (KEY_COLLECT.equals(preference.getKey())) {
                startCollecting();
                return true;
            }
            if (KEY_SHARE.equals(preference.getKey()) && mSavedUri != null) {
                Intent send = new Intent(Intent.ACTION_SEND)
                        .setType(ARCHIVE_MIME_TYPE)
                        .putExtra(Intent.EXTRA_STREAM, mSavedUri)
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                startActivity(Intent.createChooser(send, getString(R.string.collect_logs_share)));
                return true;
            }
            return super.onPreferenceTreeClick(preference);
        }

        private void startCollecting() {
            File dir = getOutDir();
            deleteContents(dir);
            if (!dir.isDirectory() && !dir.mkdirs()) {
                Log.e(TAG, "Can't create " + dir);
                showFailed();
                return;
            }
            mSavedUri = null;
            SystemProperties.set(PROP_STATUS, STATUS_STARTING);
            SystemProperties.set(PROP_COLLECT, "1");
            mStartTime = SystemClock.elapsedRealtime();
            showRunning();
            mHandler.postDelayed(mPoll, POLL_INTERVAL_MS);
        }

        private void poll() {
            String status = SystemProperties.get(PROP_STATUS);
            if (STATUS_DONE.equals(status)) {
                save();
            } else if (STATUS_FAILED.equals(status)
                    || SystemClock.elapsedRealtime() - mStartTime > TIMEOUT_MS) {
                Log.e(TAG, "Collection failed, status: " + status);
                showFailed();
            } else {
                mHandler.postDelayed(mPoll, POLL_INTERVAL_MS);
            }
        }

        private void save() {
            File archive = findArchive();
            if (archive == null) {
                Log.e(TAG, "No archive in " + getOutDir());
                showFailed();
                return;
            }
            mStatus.setTitle(R.string.collect_logs_saving);
            Context context = requireContext().getApplicationContext();
            File dir = getOutDir();
            mExecutor.execute(() -> {
                Uri uri = copyToDownloads(context.getContentResolver(), archive);
                deleteContents(dir);
                SystemProperties.set(PROP_STATUS, "");
                mHandler.post(() -> {
                    if (!isAdded()) {
                        return;
                    }
                    if (uri == null) {
                        showFailed();
                    } else {
                        showSaved(uri, archive.getName());
                    }
                });
            });
        }

        private static Uri copyToDownloads(ContentResolver resolver, File archive) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Downloads.DISPLAY_NAME, archive.getName());
            values.put(MediaStore.Downloads.MIME_TYPE, ARCHIVE_MIME_TYPE);
            values.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
            values.put(MediaStore.Downloads.IS_PENDING, 1);
            Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                Log.e(TAG, "Can't create " + archive.getName() + " in Download");
                return null;
            }
            try (InputStream in = new FileInputStream(archive);
                    OutputStream out = resolver.openOutputStream(uri)) {
                in.transferTo(out);
            } catch (IOException e) {
                Log.e(TAG, "Can't copy " + archive + " to Download", e);
                resolver.delete(uri, null, null);
                return null;
            }
            values.clear();
            values.put(MediaStore.Downloads.IS_PENDING, 0);
            resolver.update(uri, values, null, null);
            return uri;
        }

        private File getOutDir() {
            return new File(requireContext().getCacheDir(), OUT_DIR);
        }

        private File findArchive() {
            File[] archives = getOutDir().listFiles((dir, name) -> name.endsWith(ARCHIVE_SUFFIX));
            return archives != null && archives.length > 0 ? archives[0] : null;
        }

        private static void deleteContents(File dir) {
            File[] files = dir.listFiles();
            if (files == null) {
                return;
            }
            for (File file : files) {
                if (file.isDirectory()) {
                    deleteContents(file);
                }
                file.delete();
            }
        }

        private void showRunning() {
            mCollect.setEnabled(false);
            mShare.setVisible(false);
            mStatus.setVisible(true);
            mStatus.setTitle(R.string.collect_logs_running);
            mStatus.setSummary(R.string.collect_logs_running_summary);
        }

        private void showFailed() {
            mCollect.setEnabled(true);
            mShare.setVisible(false);
            mStatus.setVisible(true);
            mStatus.setTitle(R.string.collect_logs_failed);
            mStatus.setSummary(R.string.collect_logs_failed_summary);
        }

        private void showSaved(Uri uri, String name) {
            mSavedUri = uri;
            mCollect.setEnabled(true);
            mStatus.setVisible(true);
            mStatus.setTitle(R.string.collect_logs_saved);
            mStatus.setSummary(getString(R.string.collect_logs_saved_summary, name));
            mShare.setVisible(true);
        }
    }
}
