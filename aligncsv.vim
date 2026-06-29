" Align CSV commas with the header row.
" Public entry point:
"   :AlignCsv
"   :12,41AlignCsv
"   :call AlignCsv()

let g:loaded_aligncsv = 1

if !exists('g:aligncsv_marker_pairs')
  let g:aligncsv_marker_pairs = [
        \ ['<PARAMETER_START>', '<PARAMETER_END>'],
        \ ['<MODULE_PORT_START>', '<MODULE_PORT_END>'],
        \ ]
endif

if !exists('g:aligncsv_stop_markers')
  let g:aligncsv_stop_markers = ['<MODULE_PORT_END>']
endif

if !exists('g:aligncsv_right_align_columns')
  let g:aligncsv_right_align_columns = ['MSB', 'LSB']
endif

function! s:TrimBoth(text) abort
  return substitute(substitute(a:text, '^\s\+', '', ''), '\s\+$', '', '')
endfunction

function! s:PadRight(text, width) abort
  let l:pad = a:width - strdisplaywidth(a:text)
  return a:text . repeat(' ', max([l:pad, 0]))
endfunction

function! s:PadLeft(text, width) abort
  let l:pad = a:width - strdisplaywidth(a:text)
  return repeat(' ', max([l:pad, 0])) . a:text
endfunction

function! s:SplitCsvLine(line) abort
  let l:fields = []
  let l:field = ''
  let l:i = 0
  let l:in_quote = 0

  while l:i < strlen(a:line)
    let l:ch = strpart(a:line, l:i, 1)

    if l:ch ==# '"'
      if l:in_quote && l:i + 1 < strlen(a:line) && strpart(a:line, l:i + 1, 1) ==# '"'
        let l:field .= '""'
        let l:i += 2
        continue
      endif
      let l:in_quote = !l:in_quote
      let l:field .= l:ch
    elseif l:ch ==# ',' && !l:in_quote
      call add(l:fields, l:field)
      let l:field = ''
    else
      let l:field .= l:ch
    endif

    let l:i += 1
  endwhile

  call add(l:fields, l:field)
  return l:fields
endfunction

function! s:IsCsvLine(line) abort
  return len(s:SplitCsvLine(a:line)) > 1
endfunction

function! s:FieldWidths(rows) abort
  let l:max_cols = 0
  for l:row in a:rows
    let l:max_cols = max([l:max_cols, len(l:row)])
  endfor

  let l:widths = repeat([1], l:max_cols)
  let l:has_content = repeat([0], l:max_cols)

  for l:row in a:rows
    for l:col in range(0, l:max_cols - 1)
      let l:cell = l:col < len(l:row) ? s:TrimBoth(l:row[l:col]) : ''
      if l:cell !=# ''
        let l:has_content[l:col] = 1
        let l:widths[l:col] = max([l:widths[l:col], strdisplaywidth(l:cell) + 1])
      endif
    endfor
  endfor

  for l:col in range(0, l:max_cols - 1)
    if !l:has_content[l:col]
      let l:widths[l:col] = 1
    endif
  endfor

  return l:widths
endfunction

function! s:RightAlignColumns(header_fields) abort
  let l:right_cols = {}

  for l:col in range(0, len(a:header_fields) - 1)
    let l:name = s:TrimBoth(a:header_fields[l:col])
    if index(g:aligncsv_right_align_columns, l:name) >= 0
      let l:right_cols[l:col] = 1
    endif
  endfor

  return l:right_cols
endfunction

function! s:JoinAligned(fields, widths, right_cols, is_header) abort
  let l:out = ''
  let l:last = len(a:fields) - 1

  for l:col in range(0, l:last)
    let l:cell = s:TrimBoth(a:fields[l:col])
    if l:col == l:last
      let l:out .= l:cell
    elseif !a:is_header && has_key(a:right_cols, l:col)
      let l:out .= s:PadLeft(l:cell, a:widths[l:col]) . ','
    else
      let l:out .= s:PadRight(l:cell, a:widths[l:col]) . ','
    endif
  endfor

  return l:out
endfunction

function! s:InsideRanges(lnum, ranges) abort
  for l:range in a:ranges
    if a:lnum >= l:range[0] && a:lnum <= l:range[1]
      return 1
    endif
  endfor
  return 0
endfunction

function! s:StopLine(line1, line2) abort
  for l:lnum in range(a:line1, a:line2)
    let l:line = s:TrimBoth(getline(l:lnum))
    for l:marker in g:aligncsv_stop_markers
      if l:line ==# l:marker
        return l:lnum
      endif
    endfor
  endfor
  return a:line2
endfunction

function! s:MarkerRanges(line1, line2) abort
  let l:ranges = []

  for l:lnum in range(a:line1, a:line2)
    let l:line = s:TrimBoth(getline(l:lnum))

    for l:pair in g:aligncsv_marker_pairs
      if type(l:pair) != 3 || len(l:pair) < 2 || l:line !=# l:pair[0]
        continue
      endif

      let l:start = max([a:line1, l:lnum - 1])
      let l:end = a:line2

      for l:end_lnum in range(l:lnum, a:line2)
        if s:TrimBoth(getline(l:end_lnum)) ==# l:pair[1]
          let l:end = l:end_lnum
          break
        endif
      endfor

      call add(l:ranges, [l:start, l:end])
    endfor
  endfor

  return l:ranges
endfunction

function! s:LooseCsvRanges(line1, line2, marker_ranges) abort
  let l:ranges = []
  let l:start = 0

  for l:lnum in range(a:line1, a:line2)
    if s:InsideRanges(l:lnum, a:marker_ranges)
      if l:start > 0
        call add(l:ranges, [l:start, l:lnum - 1])
        let l:start = 0
      endif
      continue
    endif

    if s:IsCsvLine(getline(l:lnum))
      if l:start == 0
        let l:start = l:lnum
      endif
    elseif l:start > 0
      call add(l:ranges, [l:start, l:lnum - 1])
      let l:start = 0
    endif
  endfor

  if l:start > 0
    call add(l:ranges, [l:start, a:line2])
  endif

  return l:ranges
endfunction

function! s:CompareRanges(a, b) abort
  return a:a[0] == a:b[0] ? a:a[1] - a:b[1] : a:a[0] - a:b[0]
endfunction

function! s:AutoRanges(line1, line2) abort
  let l:end = s:StopLine(a:line1, a:line2)
  let l:marker_ranges = s:MarkerRanges(a:line1, l:end)
  let l:loose_ranges = s:LooseCsvRanges(a:line1, l:end, l:marker_ranges)
  return sort(l:marker_ranges + l:loose_ranges, function('s:CompareRanges'))
endfunction

function! s:AlignOneRange(line1, line2) abort
  let l:rows = []
  let l:items = []

  for l:lnum in range(a:line1, a:line2)
    let l:line = getline(l:lnum)
    if !s:IsCsvLine(l:line)
      continue
    endif

    let l:fields = s:SplitCsvLine(l:line)
    call add(l:rows, l:fields)
    call add(l:items, {'lnum': l:lnum, 'fields': l:fields})
  endfor

  if empty(l:rows)
    return
  endif

  let l:widths = s:FieldWidths(l:rows)
  let l:right_cols = s:RightAlignColumns(l:rows[0])
  for l:idx in range(0, len(l:items) - 1)
    let l:item = l:items[l:idx]
    call setline(l:item.lnum, s:JoinAligned(l:item.fields, l:widths, l:right_cols, l:idx == 0))
  endfor
endfunction

function! s:ApplyViewOptions() abort
  setlocal nowrap

  if exists('&guioptions')
    set guioptions+=b
  endif
endfunction

function! AlignCsv(...) range abort
  call s:ApplyViewOptions()

  if a:0 >= 2
    call s:AlignOneRange(a:1, a:2)
    return
  endif

  if a:firstline != a:lastline
    call s:AlignOneRange(a:firstline, a:lastline)
    return
  endif

  for l:range in s:AutoRanges(1, line('$'))
    call s:AlignOneRange(l:range[0], l:range[1])
  endfor
endfunction

function! AlignCsvCommand(range_count, line1, line2) abort
  if a:range_count == 0
    call AlignCsv()
  else
    call AlignCsv(a:line1, a:line2)
  endif
endfunction

command! -range AlignCsv call AlignCsvCommand(<range>, <line1>, <line2>)
