" Lightweight comma-separated column highlighter.
" Copy this file to ~/.vim/plugin/csv_columns.vim.

if exists('g:loaded_csv_columns')
  finish
endif
let g:loaded_csv_columns = 1

if !exists('g:csv_column_groups')
  let g:csv_column_groups = [
        \ 'CsvCol0',
        \ 'CsvCol1',
        \ 'CsvCol2',
        \ 'CsvCol3',
        \ 'CsvCol4',
        \ 'CsvCol5',
        \ 'CsvCol6',
        \ 'CsvCol7',
        \ 'CsvCol8',
        \ 'CsvCol9',
        \ ]
endif

function! s:DefineDefaultHighlights() abort
  hi default CsvCol0 guifg=#e6e6e6 ctermfg=252
  hi default CsvCol1 guifg=#c67800 ctermfg=172
  hi default CsvCol2 guifg=#e5a7d9 ctermfg=218
  hi default CsvCol3 guifg=#7fd7cf ctermfg=116
  hi default CsvCol4 guifg=#d8a8e8 ctermfg=183
  hi default CsvCol5 guifg=#22b8cf ctermfg=38
  hi default CsvCol6 guifg=#c792ea ctermfg=141
  hi default CsvCol7 guifg=#e5a7d9 ctermfg=218
  hi default CsvCol8 guifg=#b9c0ff ctermfg=147
  hi default CsvCol9 guifg=#eeeeee ctermfg=255
endfunction

function! s:ClearCsvColumns() abort
  if exists('w:csv_column_matches')
    for l:id in w:csv_column_matches
      silent! call matchdelete(l:id)
    endfor
  endif
  let w:csv_column_matches = []
endfunction

function! s:AddCsvColumnMatches() abort
  call s:DefineDefaultHighlights()
  call s:ClearCsvColumns()

  for l:idx in range(0, len(g:csv_column_groups) - 1)
    let l:group = g:csv_column_groups[l:idx]
    if l:idx == 0
      let l:pattern = '^\s*\zs[^,]*'
    else
      let l:pattern = '^\([^,]*,\)\{' . l:idx . '}\s*\zs[^,]*'
    endif
    call add(w:csv_column_matches, matchadd(l:group, l:pattern, 10))
  endfor
endfunction

command! CsvColumns call s:AddCsvColumnMatches()
command! CsvColumnsOff call s:ClearCsvColumns()

augroup csv_columns
  autocmd!
  autocmd BufEnter,WinEnter *.csv call s:AddCsvColumnMatches()
  autocmd ColorScheme * call s:DefineDefaultHighlights() | call s:AddCsvColumnMatches()
augroup END
