/*
 * Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.blackberry.settings;

import android.os.Bundle;
import android.os.SystemProperties;
import android.provider.Settings;

import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;

import androidx.preference.ListPreference;
import androidx.preference.Preference;
import androidx.preference.PreferenceFragmentCompat;
import androidx.preference.SeekBarPreference;
import androidx.preference.SwitchPreference;

import java.io.File;

public class DeviceSettingsActivity extends CollapsingToolbarBaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (savedInstanceState == null) {
            getSupportFragmentManager()
                    .beginTransaction()
                    .replace(com.android.settingslib.collapsingtoolbar.R.id.content_frame,
                            new DeviceSettingsFragment())
                    .commit();
        }
    }

    public static class DeviceSettingsFragment extends PreferenceFragmentCompat
            implements Preference.OnPreferenceChangeListener {

        private static final String KEY_KEYBOARD_TOUCHPAD_ENABLED =
                "keyboard_touchpad_enabled";
        private static final String PROP_KEYBOARD_TOUCHPAD_POWER_DISABLED =
                "persist.vendor.touchkeypad.disabled";
        private static final String KEY_PIN_INPUT =
                "keyboard_pin_input";
        private static final String KEY_SHOW_IME =
                "show_ime_with_hard_keyboard";
        private static final String KEY_IME_SWITCHER =
                "ime_switcher_shortcut";
        private static final String KEY_ADPT_KEYBOARD_BRIGHTNESS =
                "keyboard_adaptive_brightness";
        private static final String KEY_KEYBOARD_HIGH_BRIGHTNESS_OFF =
                "keyboard_backlight_high_brightness_off";
        private static final String KEY_KEYBOARD_BRIGHTNESS =
                "keyboard_brightness";
        private static final String KEY_KEYBOARD_TIMEOUT =
                "keyboard_backlight_timeout";
        private static final String KEY_KEYBOARD_ONLY_PRESSED =
                "keyboard_backlight_only_when_pressed";
        private static final String KEY_KEYBOARD_ON_TOUCH =
                "keyboard_backlight_on_touch";
        private static final String KEY_ADPT_BUTTON_BRIGHTNESS =
                "button_adaptive_brightness";
        private static final String KEY_BUTTON_BRIGHTNESS =
                "button_brightness";
        private static final String KEY_BUTTON_TIMEOUT =
                "button_backlight_timeout";
        private static final String KEY_BUTTON_ONLY_PRESSED =
                "button_only_when_pressed";
        private static final String KEY_BUTTON_ON_KEYBOARD_TOUCH =
                "button_backlight_on_keyboard_touch";
        private static final String KEY_HOST_DT2W =
                "host_dt2w_enable";
        private static final String PROP_HOST_DT2W =
                "persist.vendor.focaltech.host_dt2w";
        private static final String SYSFS_HOST_DT2W =
                "/sys/devices/virtual/tp_device/tp_gesture/host_dt2w_enable";
        private static final String KEY_TOUCHSCREEN_CATEGORY =
                "touchscreen_category";

        @Override
        public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
            setPreferencesFromResource(R.xml.device_settings, rootKey);

            // Keyboard touchpad power
            SwitchPreference touchpadEnabled =
                    findPreference(KEY_KEYBOARD_TOUCHPAD_ENABLED);
            if (touchpadEnabled != null) {
                touchpadEnabled.setChecked(!SystemProperties.getBoolean(
                        PROP_KEYBOARD_TOUCHPAD_POWER_DISABLED, false));
                touchpadEnabled.setOnPreferenceChangeListener(this);
            }

            // Lockscreen PIN with keyboard
            SwitchPreference pinInput = findPreference(KEY_PIN_INPUT);
            if (pinInput != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "keyboard_pin_input", 1);
                pinInput.setChecked(current == 1);
                pinInput.setOnPreferenceChangeListener(this);
            }

            // Show on-screen keyboard with hardware keyboard
            SwitchPreference showIme = findPreference(KEY_SHOW_IME);
            if (showIme != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        Settings.Secure.SHOW_IME_WITH_HARD_KEYBOARD, 0);
                showIme.setChecked(current == 1);
                showIme.setOnPreferenceChangeListener(this);
            }

            // IME switcher shortcut
            ListPreference imeSwitcher = findPreference(KEY_IME_SWITCHER);
            if (imeSwitcher != null) {
                int currentValue = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "ime_switcher_shortcut", 0);
                imeSwitcher.setValue(String.valueOf(currentValue));
                imeSwitcher.setSummary(imeSwitcher.getEntry());
                imeSwitcher.setOnPreferenceChangeListener(this);
            }

            // Adaptive keyboard brightness
            SwitchPreference kbdAdptBright = findPreference(KEY_ADPT_KEYBOARD_BRIGHTNESS);
            if (kbdAdptBright != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "keyboard_adaptive_brightness", 0);
                kbdAdptBright.setChecked(current == 1);
                kbdAdptBright.setOnPreferenceChangeListener(this);
            }

            // Independent high-screen-brightness cutoff
            SwitchPreference kbdHighBrightnessOff =
                    findPreference(KEY_KEYBOARD_HIGH_BRIGHTNESS_OFF);
            if (kbdHighBrightnessOff != null) {
                int legacyAdaptive = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        KEY_ADPT_KEYBOARD_BRIGHTNESS, 0);
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        KEY_KEYBOARD_HIGH_BRIGHTNESS_OFF, legacyAdaptive);
                kbdHighBrightnessOff.setChecked(current == 1);
                kbdHighBrightnessOff.setOnPreferenceChangeListener(this);
            }

            // Keyboard brightness (0.0 - 1.0 stored, 0-100 displayed)
            SeekBarPreference kbdBright = findPreference(KEY_KEYBOARD_BRIGHTNESS);
            if (kbdBright != null) {
                float current = Settings.Secure.getFloat(
                        getContext().getContentResolver(),
                        "keyboard_brightness", -1.0f);
                kbdBright.setValue(current >= 0 ? Math.round(current * 100) : 100);
                kbdBright.setOnPreferenceChangeListener(this);
            }

            // Keyboard backlight timeout
            ListPreference kbdTimeout = findPreference(KEY_KEYBOARD_TIMEOUT);
            if (kbdTimeout != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "keyboard_backlight_timeout", 10000);
                kbdTimeout.setValue(String.valueOf(current));
                kbdTimeout.setSummary(kbdTimeout.getEntry());
                kbdTimeout.setOnPreferenceChangeListener(this);
            }

            // Keyboard backlight only when pressed
            SwitchPreference kbdPressed = findPreference(KEY_KEYBOARD_ONLY_PRESSED);
            if (kbdPressed != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "keyboard_backlight_only_when_pressed", 0);
                kbdPressed.setChecked(current == 1);
                kbdPressed.setOnPreferenceChangeListener(this);
            }

            // Keyboard backlight also when touched
            SwitchPreference kbdOnTouch = findPreference(KEY_KEYBOARD_ON_TOUCH);
            if (kbdOnTouch != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "keyboard_backlight_on_touch", 0);
                final boolean onlyWhenPressed =
                        kbdPressed != null && kbdPressed.isChecked();
                kbdOnTouch.setChecked(!onlyWhenPressed || current == 1);
                kbdOnTouch.setOnPreferenceChangeListener(this);
            }

            // Adaptive button brightness
            SwitchPreference btnAdptBright = findPreference(KEY_ADPT_BUTTON_BRIGHTNESS);
            if (btnAdptBright != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "button_adaptive_brightness", 0);
                btnAdptBright.setChecked(current == 1);
                btnAdptBright.setOnPreferenceChangeListener(this);
            }

            // Button brightness (0.0 - 1.0 stored, 0-100 displayed)
            SeekBarPreference btnBright = findPreference(KEY_BUTTON_BRIGHTNESS);
            if (btnBright != null) {
                float current = Settings.Secure.getFloat(
                        getContext().getContentResolver(),
                        "button_brightness", -1.0f);
                btnBright.setValue(current >= 0 ? Math.round(current * 100) : 100);
                btnBright.setOnPreferenceChangeListener(this);
            }

            // Button timeout
            ListPreference btnTimeout = findPreference(KEY_BUTTON_TIMEOUT);
            if (btnTimeout != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "button_backlight_timeout", 10000);
                btnTimeout.setValue(String.valueOf(current));
                btnTimeout.setSummary(btnTimeout.getEntry());
                btnTimeout.setOnPreferenceChangeListener(this);
            }

            // Button only when pressed
            SwitchPreference btnPressed = findPreference(KEY_BUTTON_ONLY_PRESSED);
            if (btnPressed != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "button_backlight_only_when_pressed", 0);
                btnPressed.setChecked(current == 1);
                btnPressed.setOnPreferenceChangeListener(this);
            }

            // Navigation button backlight also when keyboard is touched
            SwitchPreference btnOnKeyboardTouch = findPreference(KEY_BUTTON_ON_KEYBOARD_TOUCH);
            if (btnOnKeyboardTouch != null) {
                int current = Settings.Secure.getInt(
                        getContext().getContentResolver(),
                        "button_backlight_on_keyboard_touch", 0);
                final boolean onlyWhenPressed =
                            btnPressed != null && btnPressed.isChecked();
                btnOnKeyboardTouch.setChecked(!onlyWhenPressed || current == 1);
                btnOnKeyboardTouch.setOnPreferenceChangeListener(this);
            }

            // FocalTech host-side double-tap-to-wake compatibility mode
            Preference touchscreenCategory =
                    findPreference(KEY_TOUCHSCREEN_CATEGORY);
            SwitchPreference hostDt2w = findPreference(KEY_HOST_DT2W);
            if (hostDt2w != null) {
                if (new File(SYSFS_HOST_DT2W).exists()) {
                    hostDt2w.setChecked(SystemProperties.getBoolean(
                            PROP_HOST_DT2W, false));
                    hostDt2w.setOnPreferenceChangeListener(this);
                } else if (touchscreenCategory != null) {
                    // Hide this FocalTech-only category on other panels.
                    getPreferenceScreen().removePreference(touchscreenCategory);
                }
            }
        }

        private void updateOnTouchPreference(
                String preferenceKey, boolean onlyWhenPressed) {
            SwitchPreference onTouch = findPreference(preferenceKey);
            if (onTouch == null) {
                return;
            }

            final boolean savedOnTouch = Settings.Secure.getInt(
                    getContext().getContentResolver(),
                    preferenceKey, 0) == 1;

            // Without press-only mode, keyboard touch is already treated as general
            // user activity and therefore effectively turns the backlight on.
            // Show that effective state without changing the saved preference.
            onTouch.setChecked(!onlyWhenPressed || savedOnTouch);
        }

        @Override
        public boolean onPreferenceChange(Preference preference, Object newValue) {
            String key = preference.getKey();

            switch (key) {
                case KEY_KEYBOARD_TOUCHPAD_ENABLED: {
                    boolean enabled = (boolean) newValue;

                    // The persistent vendor property remains the source of truth
                    // used by init to power the capacitive keyboard on or off.
                    SystemProperties.set(
                            PROP_KEYBOARD_TOUCHPAD_POWER_DISABLED,
                            enabled ? "0" : "1");

                    // Publish an observable framework setting after changing the
                    // property. SystemUI observes this URI and then rereads the
                    // property to update the QS tile.
                    Settings.Global.putInt(
                            getContext().getContentResolver(),
                            KEY_KEYBOARD_TOUCHPAD_ENABLED,
                            enabled ? 1 : 0);
                    return true;
                }
                case KEY_PIN_INPUT: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "keyboard_pin_input",
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_SHOW_IME: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            Settings.Secure.SHOW_IME_WITH_HARD_KEYBOARD,
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_IME_SWITCHER: {
                    int value = Integer.parseInt((String) newValue);
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "ime_switcher_shortcut", value);
                    ListPreference lp = (ListPreference) preference;
                    int idx = lp.findIndexOfValue((String) newValue);
                    lp.setSummary(lp.getEntries()[idx]);
                    return true;
                }
                case KEY_ADPT_KEYBOARD_BRIGHTNESS: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "keyboard_adaptive_brightness",
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_KEYBOARD_HIGH_BRIGHTNESS_OFF: {
                    return Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            KEY_KEYBOARD_HIGH_BRIGHTNESS_OFF,
                            (boolean) newValue ? 1 : 0);
                }
                case KEY_KEYBOARD_BRIGHTNESS: {
                    int percent = (int) newValue;
                    Settings.Secure.putFloat(
                            getContext().getContentResolver(),
                            "keyboard_brightness", percent / 100.0f);
                    return true;
                }
                case KEY_KEYBOARD_TIMEOUT: {
                    int value = Integer.parseInt((String) newValue);
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "keyboard_backlight_timeout", value);
                    ListPreference lp = (ListPreference) preference;
                    int idx = lp.findIndexOfValue((String) newValue);
                    lp.setSummary(lp.getEntries()[idx]);
                    return true;
                }
                case KEY_KEYBOARD_ONLY_PRESSED: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "keyboard_backlight_only_when_pressed",
                            checked ? 1 : 0);
                    updateOnTouchPreference(KEY_KEYBOARD_ON_TOUCH, checked);
                    return true;
                }
                case KEY_KEYBOARD_ON_TOUCH: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "keyboard_backlight_on_touch",
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_ADPT_BUTTON_BRIGHTNESS: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "button_adaptive_brightness",
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_BUTTON_BRIGHTNESS: {
                    int percent = (int) newValue;
                    Settings.Secure.putFloat(
                            getContext().getContentResolver(),
                            "button_brightness", percent / 100.0f);
                    return true;
                }
                case KEY_BUTTON_TIMEOUT: {
                    int value = Integer.parseInt((String) newValue);
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "button_backlight_timeout", value);
                    ListPreference lp = (ListPreference) preference;
                    int idx = lp.findIndexOfValue((String) newValue);
                    lp.setSummary(lp.getEntries()[idx]);
                    return true;
                }
                case KEY_BUTTON_ONLY_PRESSED: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "button_backlight_only_when_pressed",
                            checked ? 1 : 0);
                    updateOnTouchPreference(KEY_BUTTON_ON_KEYBOARD_TOUCH, checked);
                    return true;
                }
                case KEY_BUTTON_ON_KEYBOARD_TOUCH: {
                    boolean checked = (boolean) newValue;
                    Settings.Secure.putInt(
                            getContext().getContentResolver(),
                            "button_backlight_on_keyboard_touch",
                            checked ? 1 : 0);
                    return true;
                }
                case KEY_HOST_DT2W: {
                    boolean enabled = (boolean) newValue;
                    SystemProperties.set(PROP_HOST_DT2W, enabled ? "1" : "0");
                    return true;
                }
            }
            return false;
        }
    }
}
