let s:ESCAPE_PATTERN = '^$~.*[]\'

" Solve rename puzzle
function! fern#internal#rename#solve(pairs, ...) abort
  let options = extend({
        \ 'intermediator': { _ -> tempname() },
        \}, a:0 ? a:1 : {},
        \)
  let Intermediator = options.intermediator
  let n = len(a:pairs)
  " Check 'src' uniqueness
  let src_map = s:to_map(map(copy(a:pairs), { -> v:val[0] }))
  if len(src_map) isnot# n
    throw printf('[fern] Duplicate src has detected in pairs: %s', a:pairs)
  endif
  " Check 'dst' uniqueness
  let dst_map = s:to_map(map(copy(a:pairs), { -> v:val[1] }))
  if len(dst_map) isnot# n
    throw printf('[fern] Duplicate dst has detected in pairs: %s', a:pairs)
  endif
  " Sort by 'dst' depth and apply intermediate column
  let pairs = sort(copy(a:pairs), funcref('s:compare'))
  " Build rename procedures
  let exprs = []
  let head = []
  let tail = []
  for [src, dst] in pairs
    let src = s:applies(src, exprs)
    let pat = escape(src, s:ESCAPE_PATTERN)
    if get(dst_map, src) || get(src_map, dst)
      let mid = Intermediator(dst)
      call add(exprs, [pat, mid])
      call add(head, [src, mid])
      call add(tail, [mid, dst])
      let dst_map[mid] = 1
    else
      call add(exprs, [pat, dst])
      call add(head, [src, dst])
    endif
    let src_map = s:to_map(map(keys(src_map), { -> s:applies(v:val, exprs) }))
  endfor
  return head + tail
endfunction

function! s:compare(a, b) abort
  let a = len(split(a:a[1], '/'))
  let b = len(split(a:b[1], '/'))
  return a is# b ? 0 : a > b ? 1 : -1
endfunction

function! s:applies(text, exprs) abort
  let text = a:text
  for [pat, dst] in a:exprs
    let text = substitute(text, pat, dst, '')
  endfor
  return text
endfunction

function! s:to_map(keys) abort
  let m = {}
  call map(uniq(sort(copy(a:keys))), { -> extend(m, { v:val : 1 }) })
  return m
endfunction
