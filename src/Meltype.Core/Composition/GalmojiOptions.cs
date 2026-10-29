// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using System.ComponentModel;

namespace Meltype.Composition;

public enum GalmojiSplitPolicy
{
    [Description("横方向のみ")] Horizontal,
    [Description("読みやすさ優先")] Balanced,
    [Description("積極的")] Aggressive,
}

public sealed class GalmojiOptions
{
    public bool Enabled { get; set; } = true;
    public bool Latin { get; set; } = true;
    public bool Digit { get; set; } = true;
    public bool Hiragana { get; set; } = true;
    public bool Katakana { get; set; } = true;
    public bool Kanji { get; set; } = true;
    public bool Symbol { get; set; } = true;
    public GalmojiSplitPolicy SplitPolicy { get; set; } = GalmojiSplitPolicy.Balanced;
    public bool Variant { get; set; } = true;
    public bool StyleStandalone { get; set; } = true;
    public int MaxDepth { get; set; } = 2;
    public string? Seed { get; set; }
    public bool PreserveUrlsAndEmoji { get; set; } = true;
    public Dictionary<string, string> Dictionary { get; set; } = [];

    /// <summary>Copies the current application settings for one conversion operation.</summary>
    /// <example><code>GalmojiOptions.FromSettings(settings);</code></example>
    public static GalmojiOptions FromSettings(Config.Settings settings) => new()
    {
        Enabled = settings.GalmojiEnabled,
        Latin = settings.GalmojiLatin,
        Digit = settings.GalmojiDigit,
        Hiragana = settings.GalmojiHiragana,
        Katakana = settings.GalmojiKatakana,
        Kanji = settings.GalmojiKanji,
        Symbol = settings.GalmojiSymbol,
        SplitPolicy = settings.GalmojiSplitPolicy,
        Variant = settings.GalmojiVariant,
        StyleStandalone = settings.GalmojiStyleStandalone,
        MaxDepth = settings.GalmojiMaxDepth,
        Seed = settings.GalmojiSeed,
        PreserveUrlsAndEmoji = settings.GalmojiPreserveUrlsAndEmoji,
        Dictionary = settings.GalmojiDictionary,
    };

    public GalmojiOptions Clone() => new()
    {
        Enabled = Enabled,
        Latin = Latin,
        Digit = Digit,
        Hiragana = Hiragana,
        Katakana = Katakana,
        Kanji = Kanji,
        Symbol = Symbol,
        SplitPolicy = SplitPolicy,
        Variant = Variant,
        StyleStandalone = StyleStandalone,
        MaxDepth = MaxDepth,
        Seed = Seed,
        PreserveUrlsAndEmoji = PreserveUrlsAndEmoji,
        Dictionary = new(Dictionary),
    };

    public void Normalize()
    {
        if (!Enum.IsDefined(SplitPolicy)) SplitPolicy = GalmojiSplitPolicy.Balanced;
        MaxDepth = Math.Clamp(MaxDepth, 0, 8);
        Dictionary ??= [];
    }
}
