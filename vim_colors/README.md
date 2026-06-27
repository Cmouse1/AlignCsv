# CSV Column Highlighting for Vim/GVim

This package contains only the CSV column highlighting part:

- `plugin/csv_columns.vim`

It colors comma-separated columns with a repeating palette similar to the
screenshot. It does not change your colorscheme, background, line numbers, or
cursor line.

## Install

Copy the plugin into your Vim plugin directory:

```sh
mkdir -p ~/.vim/plugin
cp plugin/csv_columns.vim ~/.vim/plugin/
```

Restart Vim/GVim, then open a `.csv` file. The highlighting auto-enables for
`*.csv`.

You can also enable or disable it manually:

```vim
:CsvColumns
:CsvColumnsOff
```

## Customize Colors

Put custom highlight definitions in your `.vimrc` after your colorscheme:

```vim
highlight CsvCol1 guifg=#c67800 ctermfg=172
highlight CsvCol2 guifg=#e5a7d9 ctermfg=218
highlight CsvCol3 guifg=#7fd7cf ctermfg=116
```

The plugin defines ten groups: `CsvCol0` through `CsvCol9`.
