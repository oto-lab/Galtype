// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using Meltype.Composition;

namespace Meltype.Tests;

internal static class GalmojiTests
{
    [Test]
    public static void ConvertsGaljpExamples()
    {
        var converter = new GalmojiConverter();
        var options = new GalmojiOptions { Enabled = true };

        Assert.Equal("學木交", converter.Convert("学校", options));
        Assert.Equal("ｲ言束頁Ｕτゑ", converter.Convert("信頼してる", options));
    }

    [Test]
    public static void PreservesUrlsByDefault()
    {
        var converter = new GalmojiConverter();
        var options = new GalmojiOptions { Enabled = true };

        Assert.Equal("目儿τ https://example.com/学校", converter.Convert("見て https://example.com/学校", options));
    }

    [Test]
    public static void DisabledConversionReturnsInput()
    {
        var converter = new GalmojiConverter();
        var options = new GalmojiOptions { Enabled = false };

        Assert.Equal("学校", converter.Convert("学校", options));
    }

    [Test]
    public static void ConvertsExpectedTextAndDeletionLength()
    {
        var converter = new GalmojiConverter();
        var options = new GalmojiOptions { Enabled = true };

        var expected = converter.Convert("学校", options);

        Assert.Equal("學木交", expected);
    }
}
