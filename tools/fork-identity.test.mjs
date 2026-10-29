// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

const read = file => fs.readFileSync(new URL(`../${file}`, import.meta.url), 'utf8');

test('Windows IME registration agrees across native code, host and installers', () => {
  const header = read('native/tip/Globals.h');
  const identifiers = ['CLSID_TextService', 'GUID_Profile'].map(name => {
    const values = header.match(new RegExp(`${name} = ([^;]+);`))[1].match(/0x[0-9a-f]+/gi)
      .map(value => Number.parseInt(value, 16));
    return `${values[0].toString(16).padStart(8, '0')}-${values[1].toString(16).padStart(4, '0')}-${values[2].toString(16).padStart(4, '0')}-${values.slice(3, 5).map(value => value.toString(16).padStart(2, '0')).join('')}-${values.slice(5).map(value => value.toString(16).padStart(2, '0')).join('')}`.toUpperCase();
  });
  assert.notEqual(identifiers[0], '417D801B-A9BD-4C26-BD16-356A825A6998');
  assert.notEqual(identifiers[1], '21F643F4-72D5-4946-BF70-0A126AB52D05');
  for (const file of ['src/Meltype/Tip/TipServer.cs', 'src/Meltype.Tests/TipEndToEnd.cs', 'packaging/galtype-ime.ps1']) {
    for (const identifier of identifiers) assert.ok(read(file).includes(identifier), `${file}: ${identifier}`);
  }
  assert.ok(read('native/tip/Register-Tip.ps1').includes(identifiers[0]));
});

test('native IME and managed server use the same fork-specific pipe name', () => {
  for (const file of ['src/Meltype/Tip/TipServer.cs', 'native/tip/Pipe.cpp']) {
    assert.ok(read(file).includes('Galtype.Tip.'), file);
    assert.ok(!read(file).includes('Meltype.Tip.'), file);
  }
});

test('installation and removal do not target upstream processes or data', () => {
  for (const file of ['Install-Galtype.ps1', 'Uninstall-Galtype.ps1', 'packaging/install.ps1', 'packaging/uninstall.ps1', 'packaging/Galtype.iss']) {
    const source = read(file);
    assert.doesNotMatch(source, /Get-Process\s+(?:Meltype|AutoIME)\b|\/IM\s+(?:Meltype|AutoIME|meltype_mozc_helper)\.exe/i, file);
    assert.doesNotMatch(source, /Programs\\Meltype|Programs\\AutoIME|'Meltype\.lnk'|'AutoIME\.lnk'/i, file);
  }
});

test('exit messages and startup registration are isolated from upstream', () => {
  assert.ok(read('src/Meltype/ExitSignal.cs').includes('"Galtype.ExitSignal"'));
  assert.ok(read('src/Meltype/ExitSignal.cs').includes('"Galtype.Exit"'));
  assert.doesNotMatch(read('src/Meltype/ExitSignal.cs'), /"Meltype\.Exit/);
  assert.doesNotMatch(read('src/Meltype/Startup.cs'), /"Meltype"|Meltype\.lnk/);
});
