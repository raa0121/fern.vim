let s:PATTERN = '^$~.*[]\'
let s:FRI = {
      \ 'scheme': '',
      \ 'authority': '',
      \ 'path': '',
      \ 'query': {},
      \ 'fragment': '',
      \}

function! fern#fri#parse(expr) abort
  let remains = a:expr
  let [scheme, remains] = s:split1(remains, escape('://', s:PATTERN))
  if empty(remains)
    let remains = scheme
    let scheme = ''
  endif
  let [authority, remains] = s:split1(remains, escape('/', s:PATTERN))
  if empty(remains)
    let remaings = authority
    let authority = ''
  endif
  let [path, remains] = s:split1(remains, escape(';', s:PATTERN))
  if empty(remains)
    let query = ''
    let [path, fragment] = s:split1(path, escape('#', s:PATTERN))
  else
    let [query, fragment] = s:split1(remains, escape('#', s:PATTERN))
  endif
  return {
        \ 'scheme': scheme,
        \ 'authority': s:decode(authority),
        \ 'path': s:decode(path),
        \ 'query': s:parse_query(query),
        \ 'fragment': s:decode(fragment),
        \}
endfunction

function! fern#fri#format(fri) abort
  let fri = extend(copy(s:FRI), a:fri)
  let expr = printf(
        \ '%s://%s/%s',
        \ fri.scheme,
        \ s:encode_authority(fri.authority),
        \ s:encode_path(fri.path),
        \)
  if !empty(fri.query)
    let expr .= ';' . s:format_query(fri.query)
  endif
  if !empty(fri.fragment)
    let expr .= '#' . s:encode_fragment(fri.fragment)
  endif
  return expr
endfunction

function! fern#fri#encode(str, ...) abort
  let pattern = a:0 ? a:1 : '[#\[\]= ]'
  return s:encode(a:str, pattern)
endfunction

function! fern#fri#decode(str) abort
  return s:decode(a:str)
endfunction

function! s:parse_query(query) abort
  let obj = {}
  let terms = split(a:query, '&\%(\w\+;\)\@!')
  call map(terms, { _, v -> (split(v, '=', 1) + [v:true])[:1] })
  call map(terms, { _, v ->
        \ extend(obj, {
        \   s:decode(v[0]): s:decode(v[1])
        \ })
        \})
  return obj
endfunction

function! s:format_query(query) abort
  if empty(a:query)
    return ''
  endif
  let pattern = '[/;#\[\]= ]'
  let terms = []
  for [k, v] in items(a:query)
    if empty(v)
      continue
    elseif v is# v:true
      call add(terms, s:encode_query(k))
    else
      call add(terms, printf(
            \ '%s=%s',
            \ s:encode_query(k),
            \ s:encode_query(v),
            \))
    endif
  endfor
  return join(terms, '&')
endfunction

function! s:encode_authority(path) abort
  let pattern = '[/;#\[\]= ]'
  return s:encode(a:path, pattern)
endfunction

function! s:encode_path(path) abort
  let pattern = '[;#\[\]= ]'
  return s:encode(a:path, pattern)
endfunction

function! s:encode_query(pchar) abort
  let pattern = '[#\[\]= ]'
  return s:encode(a:pchar, pattern)
endfunction

function! s:encode_fragment(pchar) abort
  let pattern = '[#\[\]= ]'
  return s:encode(a:pchar, pattern)
endfunction

function! s:encode(str, pattern) abort
  let chars = map(
        \ split(a:str, '\zs'),
        \ { _, v -> v =~# a:pattern ? printf('%%%X', char2nr(v)) : v },
        \)
  return join(chars, '')
endfunction

function! s:decode(str) abort
  let str = a:str
  let hex = matchstr(str, '%\zs[0-9a-fA-F]\{2}')
  while !empty(hex)
    let repl = nr2char(str2nr(hex, 16))
    let str = substitute(str, '%' . hex, escape(repl, '&'), 'ig')
    let hex = matchstr(str, '%\zs[0-9a-fA-F]\{2}')
  endwhile
  return str
endfunction

function! s:split1(str, pattern) abort
  let [_, s, e] = matchstrpos(a:str, a:pattern)
  if s is# -1
    return [a:str, '']
  elseif s is# 0
    return ['', a:str[e :]]
  endif
  let lhs = a:str[:s - 1]
  let rhs = a:str[e :]
  return [lhs, rhs]
endfunction
