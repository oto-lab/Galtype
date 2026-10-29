#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 otoneko.
"""Check the packaged NativeAOT and Galjp runtime with no Node.js on PATH."""

import argparse
import ctypes
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("library", type=Path)
    parser.add_argument("runtime", type=Path)
    args = parser.parse_args()
    library = args.library.resolve(strict=True)
    runtime = args.runtime.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="galtype-runtime-") as directory:
        os.environ["GALTYPE_DATA_DIR"] = directory
        os.environ["GALTYPE_GALJP_RUNTIME"] = str(runtime / "index.mjs")
        os.environ["PATH"] = ""
        (Path(directory) / "config.json").write_text(json.dumps({
            "GalmojiEnabled": True, "LiveConversion": False, "LearningEnabled": False,
        }), encoding="utf-8")
        expected = json.loads(subprocess.run(
            [str(runtime / "node"), str(runtime / "index.mjs")],
            input=json.dumps({"input": "がっこう", "options": {"preserveUrlsAndEmoji": True}}) + "\n",
            text=True, capture_output=True, check=True, timeout=10,
        ).stdout)["result"]
        assert expected != "がっこう", "Packaged Galjp did not transform the input"
        lib = ctypes.CDLL(str(library))
        lib.meltype_create.restype = ctypes.c_void_p
        lib.meltype_destroy.argtypes = [ctypes.c_void_p]
        lib.meltype_free.argtypes = [ctypes.c_void_p]
        lib.meltype_handle_key.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                         ctypes.c_char_p, ctypes.c_char_p]
        lib.meltype_handle_key.restype = ctypes.c_void_p
        session = lib.meltype_create()
        assert session, "NativeAOT session could not be created"

        def key(vk, scalar=0):
            pointer = lib.meltype_handle_key(session, vk, scalar, 0, None, None)
            assert pointer, "NativeAOT returned no result"
            try:
                return json.loads(ctypes.string_at(pointer).decode("utf-8"))
            finally:
                lib.meltype_free(pointer)

        try:
            for char in "gakkou":
                result = key(ord(char.upper()), ord(char))
            assert result["view"]["text"] == expected, result
            result = key(0x0D)
            assert result["commits"][0]["text"] == expected, result
            print("PASS: packaged Node.js and NativeAOT transform preedit and committed text without PATH")
        finally:
            lib.meltype_destroy(session)


if __name__ == "__main__":
    main()
