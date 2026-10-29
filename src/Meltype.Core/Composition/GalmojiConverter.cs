// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using System.Diagnostics;
using System.ComponentModel;
using System.Text;
using System.Text.Json;

namespace Meltype.Composition;

/// <summary>Converts display and committed text through the shared local Galjp process.</summary>
public sealed class GalmojiConverter
{
    private static readonly object _sync = new();
    private static Process? _node;
    private static StreamWriter? _nodeInput;
    private static StreamReader? _nodeOutput;
    private static DateTimeOffset _retryAfter;

    /// <summary>Returns the input unchanged when disabled or when the local runtime is unavailable.</summary>
    /// <example><code>new GalmojiConverter().Convert("学校", new GalmojiOptions()); // 學木交</code></example>
    public string Convert(string input, GalmojiOptions options)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(options);
        if (!options.Enabled || input.Length == 0) return input;
        options.Normalize();
        return TryConvertWithNode(input, options) ?? input;
    }

    internal CompositionView ConvertView(CompositionView view, GalmojiOptions options) => view with
    {
        Text = Convert(view.Text, options),
        Candidates = view.Candidates.Select(text => Convert(text, options)).ToList(),
        Clauses = view.Clauses?.Select(text => Convert(text, options)).ToList(),
        Committed = view.Committed is null ? null : Convert(view.Committed, options),
        Suggestion = view.Suggestion is null ? null : Convert(view.Suggestion, options),
        Predictions = view.Predictions?.Select(text => Convert(text, options)).ToList(),
    };

    private string? TryConvertWithNode(string input, GalmojiOptions options)
    {
        lock (_sync)
        {
            if (DateTimeOffset.UtcNow < _retryAfter) return null;
            try
            {
                EnsureNode();
                var request = CreateRequest(input, options);
                _nodeInput!.WriteLine(request);
                _nodeInput.Flush();
                var response = _nodeOutput!.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(2)).GetAwaiter().GetResult();
                if (response is null) throw new IOException("galjp runtime が終了しました。");
                using var document = JsonDocument.Parse(response);
                if (document.RootElement.TryGetProperty("error", out var error))
                {
                    Diagnostics.Log.Warn($"galjp の変換に失敗しました: {error.GetString()}");
                    return null;
                }
                return document.RootElement.GetProperty("result").GetString();
            }
            catch (Exception ex) when (ex is InvalidOperationException or IOException or JsonException or Win32Exception or TimeoutException)
            {
                Diagnostics.Log.Warn($"galjp runtime を利用できません。Meltype の入力を継続します: {ex.Message}");
                StopNode();
                _retryAfter = DateTimeOffset.UtcNow.AddSeconds(30);
                return null;
            }
        }
    }

    private static string CreateRequest(string input, GalmojiOptions options)
    {
        // Write primitive values directly so the NativeAOT builds need no reflection metadata.
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartObject();
            writer.WriteString("input", input);
            writer.WriteStartObject("options");
            writer.WriteStartObject("layers");
            writer.WriteBoolean("latin", options.Latin);
            writer.WriteBoolean("digit", options.Digit);
            writer.WriteBoolean("hiragana", options.Hiragana);
            writer.WriteBoolean("katakana", options.Katakana);
            writer.WriteBoolean("kanji", options.Kanji);
            writer.WriteBoolean("symbol", options.Symbol);
            writer.WriteEndObject();
            writer.WriteString("splitPolicy", options.SplitPolicy.ToString().ToLowerInvariant());
            writer.WriteBoolean("variant", options.Variant);
            writer.WriteBoolean("styleStandalone", options.StyleStandalone);
            writer.WriteNumber("maxDepth", options.MaxDepth);
            writer.WriteString("seed", options.Seed);
            writer.WriteBoolean("preserveUrlsAndEmoji", options.PreserveUrlsAndEmoji);
            writer.WriteStartObject("dictionary");
            foreach (var entry in options.Dictionary) writer.WriteString(entry.Key, entry.Value);
            writer.WriteEndObject();
            writer.WriteEndObject();
            writer.WriteEndObject();
        }
        return Encoding.UTF8.GetString(stream.ToArray());
    }

    private static void EnsureNode()
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
        var bundledNode = Path.Combine(Path.GetDirectoryName(script)!, OperatingSystem.IsWindows() ? "node.exe" : "node");
        _node = Process.Start(new ProcessStartInfo
        {
            FileName = File.Exists(bundledNode) ? bundledNode : "node",
            StandardInputEncoding = new UTF8Encoding(false),
            StandardOutputEncoding = Encoding.UTF8,
            Arguments = $"\"{script}\"",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        }) ?? throw new InvalidOperationException("galjp runtime を起動できません。");
        _node.ErrorDataReceived += (_, _) => { };
        _node.BeginErrorReadLine();
        _nodeInput = _node.StandardInput;
        _nodeOutput = _node.StandardOutput;
    }

    private static void StopNode()
    {
        if (_node is { HasExited: false }) _node.Kill();
        _nodeInput?.Dispose();
        _nodeOutput?.Dispose();
        _node?.Dispose();
        _node = null;
        _nodeInput = null;
        _nodeOutput = null;
    }

}
