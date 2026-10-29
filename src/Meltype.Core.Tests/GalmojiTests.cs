// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using Meltype.Composition;

namespace Meltype.Tests;

internal static class GalmojiTests
{
    [Test]
    public static void ConvertsGaljpExamples()
    {
        var options = new GalmojiOptions { Enabled = true };

        Assert.Equal("學木交", GalmojiConverter.Convert("学校", options));
        Assert.Equal("ｲ言束頁Ｕτゑ", GalmojiConverter.Convert("信頼してる", options));
    }

    [Test]
    public static void PreservesUrlsByDefault()
    {
        var options = new GalmojiOptions { Enabled = true };

        Assert.Equal("目儿τ https://example.com/学校", GalmojiConverter.Convert("見て https://example.com/学校", options));
    }

    [Test]
    public static void DisabledConversionReturnsInput()
    {
        var options = new GalmojiOptions { Enabled = false };

        Assert.Equal("学校", GalmojiConverter.Convert("学校", options));
    }

    [Test]
    public static void ConvertsExpectedTextAndDeletionLength()
    {
        var destination = new CompositionTests.FakeHost();
        var host = new GalmojiCompositionHost(destination, () => new GalmojiOptions());
        host.CommitText("学校");
        Assert.Equal("學木交", destination.Document);
        host.ReplaceBackward(2, "信頼してる");
        Assert.Equal("ｲ言束頁Ｕτゑ", destination.Document);
        host.DeleteBackward(5);
        Assert.Equal("", destination.Document);
    }

    [Test]
    public static void FirstRunEnablesGalmojiAndSavedChoiceIsRespected()
    {
        var directory = Path.Combine(Path.GetTempPath(), "galtype-first-run-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        try
        {
            var path = Path.Combine(directory, "config.json");
            Assert.True(Meltype.Config.Settings.Load(path).GalmojiEnabled, "First run enables conversion");
            new Meltype.Config.Settings { GalmojiEnabled = false }.Save(path);
            Assert.True(!Meltype.Config.Settings.Load(path).GalmojiEnabled, "Saved opt-out is respected");
        }
        finally { Directory.Delete(directory, recursive: true); }
    }

    [Test]
    public static void ConvertsPreeditCandidatesAndCommittedTextConsistently()
    {
        var view = new CompositionView("学校", ["学校"], 0, true, "", Committed: "学校", Predictions: ["学校"]);
        var converted = GalmojiConverter.ConvertView(view, new GalmojiOptions());
        Assert.Equal("學木交", converted.Text);
        Assert.Equal(converted.Text, converted.Candidates[0]);
        Assert.Equal(converted.Text, converted.Committed);
        Assert.Equal(converted.Text, converted.Predictions![0]);
    }

    [Test]
    public static void ConvertsSessionsBeforeAndAfterEnter()
    {
        var settings = new Meltype.Config.Settings { GalmojiEnabled = true };
        var session = new MeltypeSession(CompositionTests.Detector, new CompositionTests.FakeConverter(), new CompositionOptions(), () => settings);
        SessionResult? result = null;
        foreach (var c in "gakkou") result = session.HandleKey(char.ToUpperInvariant(c), c, false, false, false, false);
        var expected = GalmojiConverter.Convert("がっこう", new GalmojiOptions());
        Assert.Equal(expected, result?.View?.Text);
        result = session.HandleKey(Meltype.Input.VirtualKeys.Return, null, false, false, false, false);
        Assert.Equal(expected, result.Commits.Single().Text);
    }
}
