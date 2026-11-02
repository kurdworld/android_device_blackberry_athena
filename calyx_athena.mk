#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Device
$(call inherit-product, device/blackberry/athena/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/calyx/config/common_phone.mk)

PRODUCT_BRAND := BlackBerry
PRODUCT_DEVICE := athena
PRODUCT_MANUFACTURER := TCL Technology
PRODUCT_MODEL := BlackBerry KEY2
PRODUCT_NAME := calyx_athena

# need to keep old FPs from oreo for play certification
