# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
#
# Mira fork (mirzam-tech/azure-iot-sdk, mira/main): registers c/ as ONE ESP-IDF component, so the
# ESP-IDF component manager can consume the SDK as a git dependency with `path: c` (it copies only
# that subtree, which the per-component layout in components/ cannot build from: those reach
# ../../../.. and the azure-sdk-for-c submodule). Included from c/CMakeLists.txt when ESP_PLATFORM.
#
# Compiles: core + mqttv3 (src/sources.cmake), azure-sdk-for-c az_core + az_iot (the same list as
# components/azure-sdk-for-c) and the ESP-IDF az_platform hooks. No MQTT adapter and no crypto
# backend: the application brings its own az_iot_mqtt_iface adapter (X.509 needs no crypto
# backend); --gc-sections drops the features it does not use.
set(_az_c "${CMAKE_CURRENT_LIST_DIR}/../..")
get_filename_component(_az_c "${_az_c}" ABSOLUTE)
set(_az_sdk "${_az_c}/deps/azure-sdk-for-c/sdk")
if(NOT EXISTS "${_az_sdk}/inc/azure/az_core.h")
    message(FATAL_ERROR "azure-iot-sdk: ${_az_sdk} is empty (git submodule update --init c/deps/azure-sdk-for-c)")
endif()

include("${_az_c}/src/sources.cmake")
set(_az_srcs)
foreach(_s IN LISTS AZ_IOT_CORE_SOURCES AZ_IOT_MQTTV3_SOURCES)
    list(APPEND _az_srcs "${_az_c}/src/${_s}")
endforeach()
set(_az_sdk_srcs)
foreach(_s core/az_base64.c core/az_context.c core/az_json_reader.c core/az_json_token.c
           core/az_json_writer.c core/az_log.c core/az_precondition.c core/az_span.c
           iot/az_iot_common.c iot/az_iot_hub_client.c iot/az_iot_hub_client_c2d.c
           iot/az_iot_hub_client_commands.c iot/az_iot_hub_client_methods.c
           iot/az_iot_hub_client_properties.c iot/az_iot_hub_client_sas.c
           iot/az_iot_hub_client_telemetry.c iot/az_iot_hub_client_twin.c
           iot/az_iot_provisioning_client.c iot/az_iot_provisioning_client_sas.c)
    list(APPEND _az_sdk_srcs "${_az_sdk}/src/azure/${_s}")
endforeach()
list(APPEND _az_sdk_srcs "${_az_c}/platforms/esp32/components/azure-sdk-for-c/az_platform_esp_idf.c")

idf_component_register(
    SRCS ${_az_srcs} ${_az_sdk_srcs}
    INCLUDE_DIRS "${_az_c}/inc" "${_az_sdk}/inc"
    PRIV_INCLUDE_DIRS "${_az_c}/src/core"
    PRIV_REQUIRES esp_timer freertos)

# azure-sdk-for-c uses constructs strict warnings reject (as components/azure-sdk-for-c does).
set_source_files_properties(${_az_sdk_srcs} PROPERTIES COMPILE_OPTIONS "-w")
