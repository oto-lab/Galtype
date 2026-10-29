// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 otoneko.

using Meltype.Input;

namespace Meltype.Composition;

internal sealed class GalmojiCompositionHost(ICompositionHost host, Func<GalmojiOptions> options) : ICompositionHost
{

    private readonly List<(string Original, string Rendered)> _committed = [];

    public void CommitText(string text)
    {
        var rendered = GalmojiConverter.Convert(text, options());
        host.CommitText(rendered);
        _committed.Add((text, rendered));
        if (_committed.Count > 256) _committed.RemoveAt(0);
    }

    private int RenderedDeletionLength(int count)
    {
        var length = 0;
        while (count > 0 && _committed.Count > 0)
        {
            var chunk = _committed[^1];
            _committed.RemoveAt(_committed.Count - 1);
            if (count >= chunk.Original.Length)
            {
                count -= chunk.Original.Length;
                length += chunk.Rendered.Length;
            }
            else
            {
                var prefix = chunk.Original[..^count];
                var renderedPrefix = GalmojiConverter.Convert(prefix, options());
                length += Math.Max(0, chunk.Rendered.Length - renderedPrefix.Length);
                _committed.Add((prefix, renderedPrefix));
                count = 0;
            }
        }
        return length + count;
    }

    public void DeleteBackward(int count) => host.DeleteBackward(RenderedDeletionLength(count));

    public void ReplaceBackward(int count, string text)
    {
        var length = RenderedDeletionLength(count);
        var rendered = GalmojiConverter.Convert(text, options());
        host.ReplaceBackward(length, rendered);
        _committed.Add((text, rendered));
    }

    public void Show(CompositionView view) => host.Show(GalmojiConverter.ConvertView(view, options()));

    public void Replay(KeyEvent e)
    {
        _committed.Clear();
        host.Replay(e);
    }

    public void Replay(MouseButtonEvent e)
    {
        _committed.Clear();
        host.Replay(e);
    }

    public void RecordDirectReplay(char c)
    {
        _committed.Add((c.ToString(), c.ToString()));
        host.RecordDirectReplay(c);
    }

    public ReconversionSelection? GetReconversionSelection() => host.GetReconversionSelection();
    public bool TryReplaceSelection(ReconversionSelection selection, string text) => host.TryReplaceSelection(selection, GalmojiConverter.Convert(text, options()));
    public bool CanDeleteBackward => host.CanDeleteBackward;
    public char? CharFromKey(KeyEvent e, bool shift) => host.CharFromKey(e, shift);
    public bool IsShiftDown() => host.IsShiftDown();
    public bool SurroundingTextIsCurrent => host.SurroundingTextIsCurrent;
    public string? ClipboardText => host.ClipboardText;
    public void RequestSurroundingText(Action<string?, string?> callback) => host.RequestSurroundingText(callback);
    public void Hide() => host.Hide();
}
