// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using System.Diagnostics;
using System.ComponentModel;
using System.Text.Json;

namespace Meltype.Composition;

public sealed class GalmojiConverter
{
    private readonly object _sync = new();
    private Process? _node;
    private StreamWriter? _nodeInput;
    private StreamReader? _nodeOutput;

    public string Convert(string input, GalmojiOptions options)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(options);
        if (!options.Enabled || input.Length == 0) return input;
        options.Normalize();
        return TryConvertWithNode(input, options) ?? input;
    }

    private string? TryConvertWithNode(string input, GalmojiOptions options)
    {
        lock (_sync)
        {
            try
            {
                EnsureNode();
                var request = JsonSerializer.Serialize(new
                {
                    input,
                    options = new
                    {
                        layers = new
                        {
                            latin = options.Latin,
                            digit = options.Digit,
                            hiragana = options.Hiragana,
                            katakana = options.Katakana,
                            kanji = options.Kanji,
                            symbol = options.Symbol,
                        },
                        splitPolicy = options.SplitPolicy.ToString().ToLowerInvariant(),
                        variant = options.Variant,
                        styleStandalone = options.StyleStandalone,
                        maxDepth = options.MaxDepth,
                        seed = options.Seed,
                        preserveUrlsAndEmoji = options.PreserveUrlsAndEmoji,
                        dictionary = options.Dictionary,
                    },
                });
                _nodeInput!.WriteLine(request);
                _nodeInput.Flush();
                var responseTask = _nodeOutput!.ReadLineAsync();
                if (!responseTask.Wait(TimeSpan.FromSeconds(2)))
                    throw new IOException("galjp runtime の応答がタイムアウトしました。");
                var response = responseTask.GetAwaiter().GetResult();
                if (response is null) throw new IOException("galjp runtime が終了しました。");
                using var document = JsonDocument.Parse(response);
                if (document.RootElement.TryGetProperty("error", out var error))
                {
                    Diagnostics.Log.Warn($"galjp の変換に失敗しました: {error.GetString()}");
                    return null;
                }
                return document.RootElement.GetProperty("result").GetString();
            }
            catch (Exception ex) when (ex is InvalidOperationException or IOException or JsonException or Win32Exception)
            {
                Diagnostics.Log.Warn($"galjp runtime を利用できません。Meltype の入力を継続します: {ex.Message}");
                StopNode();
                return null;
            }
        }
    }

    private void EnsureNode()
    {
        if (_node is { HasExited: false }) return;
        StopNode();
        var script = Environment.GetEnvironmentVariable("GALTYPE_GALJP_RUNTIME");
        script ??= Path.Combine(AppContext.BaseDirectory, "galjp-runtime", "index.mjs");
        if (!File.Exists(script))
        {
            for (var directory = new DirectoryInfo(AppContext.BaseDirectory); directory is not null; directory = directory.Parent)
            {
                var repositoryScript = Path.Combine(directory.FullName, "tools", "galjp-runtime", "index.mjs");
                if (!File.Exists(repositoryScript)) continue;
                script = repositoryScript;
                break;
            }
        }
        if (!File.Exists(script)) throw new FileNotFoundException("galjp runtime が見つかりません。", script);
        _node = Process.Start(new ProcessStartInfo
        {
            FileName = "node",
            Arguments = $"\"{script}\"",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        }) ?? throw new InvalidOperationException("galjp runtime を起動できません。");
        _nodeInput = _node.StandardInput;
        _nodeOutput = _node.StandardOutput;
    }

    private void StopNode()
    {
        _nodeInput?.Dispose();
        _nodeOutput?.Dispose();
        if (_node is { HasExited: false }) _node.Kill();
        _node?.Dispose();
        _node = null;
        _nodeInput = null;
        _nodeOutput = null;
    }

}
