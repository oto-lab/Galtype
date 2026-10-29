// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lnkiai
//
// Galtype IME (TSF のテキストサービス) の共通の定義。

#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <msctf.h>
#include <ctffunc.h>
#include <olectl.h>
#include <string>
#include <vector>

namespace galtype {

// テキストサービスの CLSID (COM のクラス)
// {CB3A7F51-C145-492F-AA7B-FED5330A7DB5}
inline constexpr CLSID CLSID_TextService = {0xcb3a7f51, 0xc145, 0x492f, {0xaa, 0x7b, 0xfe, 0xd5, 0x33, 0x0a, 0x7d, 0xb5}};

// 日本語のキーボードとしてのプロファイル
// {B52F0FDF-86A6-4EEB-83E9-EEE13706A2D7}
inline constexpr GUID GUID_Profile = {0xb52f0fdf, 0x86a6, 0x4eeb, {0x83, 0xe9, 0xee, 0xe1, 0x37, 0x06, 0xa2, 0xd7}};

// 下線の種類: 打っている途中 / 変換した文節 / 選んでいる文節
// {31382AEB-F66A-4D3D-A99E-D3C0F7863F2F}
inline constexpr GUID GUID_AttrInput = {0x31382aeb, 0xf66a, 0x4d3d, {0xa9, 0x9e, 0xd3, 0xc0, 0xf7, 0x86, 0x3f, 0x2f}};
// {8C3C5261-A5F6-4342-ACB5-9AD4A4C8819F}
inline constexpr GUID GUID_AttrConverted = {0x8c3c5261, 0xa5f6, 0x4342, {0xac, 0xb5, 0x9a, 0xd4, 0xa4, 0xc8, 0x81, 0x9f}};
// {F0286FAE-1559-4D6A-AEDA-C57A7686ACC1}
inline constexpr GUID GUID_AttrTarget = {0xf0286fae, 0x1559, 0x4d6a, {0xae, 0xda, 0xc5, 0x7a, 0x76, 0x86, 0xac, 0xc1}};

inline constexpr LANGID kLangId = MAKELANGID(LANG_JAPANESE, SUBLANG_JAPANESE_JAPAN);
inline constexpr wchar_t kDisplayName[] = L"Galtype";

extern HINSTANCE g_module;
extern LONG g_locks;

inline void DllAddRef() { InterlockedIncrement(&g_locks); }
inline void DllRelease() { InterlockedDecrement(&g_locks); }

// 文字コードの変換
std::string ToUtf8(const std::wstring& text);
std::wstring FromUtf8(const std::string& text);

// デバッグ用のログ (%LOCALAPPDATA%\Galtype\tip.log、GALTYPE_TIP_LOG=1 のときだけ)
void TipLog(const wchar_t* format, ...);

}  // namespace galtype
