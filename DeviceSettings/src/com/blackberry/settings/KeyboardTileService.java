/*
 * SPDX-License-Identifier: Apache-2.0
 */

package com.blackberry.settings;

import android.graphics.drawable.Icon;
import android.os.SystemProperties;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

/**
 * Quick Settings tile that turns a keyboard touchpad feature on or off by flipping a "disabled"
 * system property. Init and ViewRootImpl act on the property.
 */
public abstract class KeyboardTileService extends TileService {

    /** Property that is "1" while the feature is switched off. */
    abstract String getDisabledProperty();

    @Override
    public void onStartListening() {
        updateTile();
    }

    @Override
    public void onClick() {
        boolean disabled = SystemProperties.getBoolean(getDisabledProperty(), false);
        SystemProperties.set(getDisabledProperty(), disabled ? "0" : "1");
        updateTile();
    }

    private void updateTile() {
        Tile tile = getQsTile();
        if (tile == null) {
            return;
        }
        boolean enabled = !SystemProperties.getBoolean(getDisabledProperty(), false);
        tile.setIcon(Icon.createWithResource(this, R.drawable.ic_keyboard));
        tile.setState(enabled ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.setSubtitle(getString(enabled ? R.string.tile_on : R.string.tile_off));
        tile.updateTile();
    }

    /** Tile for the whole keyboard touchpad. */
    public static class Touchpad extends KeyboardTileService {
        @Override
        String getDisabledProperty() {
            return "persist.vendor.touchkeypad.disabled";
        }
    }

    /** Tile for keyboard swipe scrolling. */
    public static class Scrolling extends KeyboardTileService {
        @Override
        String getDisabledProperty() {
            return "persist.vendor.touchkeypad.scrolling_disabled";
        }
    }
}
