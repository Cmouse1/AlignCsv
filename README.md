# AlignCsv Vim Function

`aligncsv.vim` exports one public command:

```vim
:AlignCsv
```

## Use

Source the script:

```vim
:source /Users/chenhao/Documents/AlignCsv/aligncsv.vim
```

Auto-detect and align all supported blocks:

```vim
:AlignCsv
```

When it runs, it also applies `setlocal nowrap` and adds `b` to `guioptions`
when that option exists.

Align a specific range:

```vim
:12,41AlignCsv
```

Or run it on a visual/range selection:

```vim
:'<,'>AlignCsv
```

The underlying public function is also named `AlignCsv()` if you need it from
another Vim script.

## Auto-Detected Blocks

The function recognizes marker text, not fixed line numbers:

- `<PARAMETER_START>` starts an optional parameter block; the previous line is its title
- `<PARAMETER_END>` ends that optional parameter block
- `<MODULE_PORT_START>` starts the port block; the previous line is its title
- `<MODULE_PORT_END>` ends all content that should be processed

Text after `<MODULE_PORT_END>` is ignored.

## Alignment Rule

Each block is aligned independently.

For each column, the width is the longest trimmed text in that column plus one
space. Empty columns use one space. The title row participates in width
calculation, so content rows align with the title row.

Columns named `MSB` or `LSB` are right-aligned, so their text stays close to the
comma on the right. You can override that list before sourcing or running the
command:

```vim
let g:aligncsv_right_align_columns = ['MSB', 'LSB']
```

Non-CSV marker lines are left unchanged. Commas inside quoted CSV text, like
`"a,b"`, are ignored as separators.
