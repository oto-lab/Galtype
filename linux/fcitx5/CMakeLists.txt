# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yukishiro
#
# Galtype の fcitx5 のアドオン。linux/build.sh が fcitx5 の開発用のパッケージ (fcitx5-modules-dev) があるときにビルドする。
#   cmake -S linux/fcitx5 -B build/fcitx5 -DGALTYPE_DIR=/opt/galtype && cmake --build build/fcitx5
cmake_minimum_required(VERSION 3.16)
project(fcitx5-galtype LANGUAGES CXX)

find_package(Fcitx5Core 5.0 REQUIRED)
find_package(Fcitx5Utils 5.0 REQUIRED)

# 本体 (libGaltypeNative.so) と Mozc のヘルパーを入れた場所 (install.sh と同じ)
set(GALTYPE_DIR "/opt/galtype" CACHE PATH "libGaltypeNative.so を入れた場所")

add_library(galtype MODULE meltype.cpp)
set_target_properties(galtype PROPERTIES PREFIX "" CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
# fcitx5 5.1.16 以降の fcitx-utils/log.h は std::source_location を使うため、C++20 が要る
if(Fcitx5Core_VERSION VERSION_GREATER_EQUAL 5.1.16)
    set_target_properties(galtype PROPERTIES CXX_STANDARD 20)
endif()
target_compile_definitions(galtype PRIVATE GALTYPE_DIR="${GALTYPE_DIR}")
target_link_libraries(galtype PRIVATE Fcitx5::Core Fcitx5::Utils ${CMAKE_DL_LIBS})

# テスト (fcitx5 のテスト用のフロントエンドでキーを送り、確定した文字を確かめる)。
#   cmake -S linux/fcitx5 -B build -DBUILD_TESTING=ON && cmake --build build && GALTYPE_DIR=<libGaltypeNative.so の場所> ctest --test-dir build
option(BUILD_TESTING "テストをビルドする" OFF)
if(BUILD_TESTING)
    enable_testing()
    find_package(Fcitx5ModuleTestFrontend REQUIRED)
    # fcitx5 のデータの場所 (build/test/addon、build/test/inputmethod) に設定ファイルを置く
    configure_file(galtype-addon.conf ${CMAKE_CURRENT_BINARY_DIR}/test/addon/galtype.conf COPYONLY)
    configure_file(test/testfrontend.conf ${CMAKE_CURRENT_BINARY_DIR}/test/addon/testfrontend.conf COPYONLY)
    configure_file(test/testui.conf ${CMAKE_CURRENT_BINARY_DIR}/test/addon/testui.conf COPYONLY)
    configure_file(test/testim.conf ${CMAKE_CURRENT_BINARY_DIR}/test/addon/testim.conf COPYONLY)
    file(READ galtype.conf GALTYPE_IM_CONF)
    string(REPLACE "@DIR@" "${GALTYPE_DIR}" GALTYPE_IM_CONF "${GALTYPE_IM_CONF}")
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/test/inputmethod/galtype.conf "${GALTYPE_IM_CONF}")
    file(COPY /usr/share/fcitx5/addon/keyboard.conf DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/test/addon)
    get_target_property(FCITX5_CORE_LOCATION Fcitx5::Core LOCATION)
    get_filename_component(FCITX5_LIB_DIR ${FCITX5_CORE_LOCATION} DIRECTORY)
    add_executable(testgaltype test/testmeltype.cpp)
    set_target_properties(testgaltype PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
    # fcitx5 5.1.16 以降の fcitx-utils/log.h は std::source_location を使うため、C++20 が要る
    if(Fcitx5Core_VERSION VERSION_GREATER_EQUAL 5.1.16)
        set_target_properties(testgaltype PROPERTIES CXX_STANDARD 20)
    endif()
    target_compile_definitions(testgaltype PRIVATE
        FCITX5_GALTYPE_BINARY_DIR="${CMAKE_CURRENT_BINARY_DIR}"
        FCITX5_SYSTEM_ADDON_DIR="${FCITX5_LIB_DIR}/fcitx5")
    target_link_libraries(testgaltype PRIVATE Fcitx5::Core Fcitx5::Utils Fcitx5::Module::TestFrontend)
    add_dependencies(testgaltype galtype)
    add_test(NAME testgaltype COMMAND testgaltype)

    add_executable(testterminal test/testterminal.cpp)
    set_target_properties(testterminal PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
    if(Fcitx5Core_VERSION VERSION_GREATER_EQUAL 5.1.16)
        set_target_properties(testterminal PROPERTIES CXX_STANDARD 20)
    endif()
    target_compile_definitions(testterminal PRIVATE
        FCITX5_GALTYPE_BINARY_DIR="${CMAKE_CURRENT_BINARY_DIR}"
        FCITX5_SYSTEM_ADDON_DIR="${FCITX5_LIB_DIR}/fcitx5")
    target_link_libraries(testterminal PRIVATE Fcitx5::Core Fcitx5::Utils Fcitx5::Module::TestFrontend)
    add_dependencies(testterminal galtype)
    add_test(NAME testterminal COMMAND testterminal)
endif()
