let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#renamer#rename(factory, ...) abort
  let options = extend({
        \ 'bufname': printf('fern-renamer:%s', sha256(localtime()))[:7],
        \ 'opener': 'vsplit',
        \ 'cursor': [1, 1],
        \ 'is_drawer': v:false,
        \}, a:0 ? a:1 : {},
        \)
  return s:Promise.new(funcref('s:executor', [a:factory, options]))
endfunction

function! s:executor(factory, options, resolve, reject) abort
  call fern#internal#buffer#open(a:options.bufname, {
        \ 'opener': a:options.opener,
        \ 'locator': a:options.is_drawer,
        \ 'keepalt': !a:options.is_drawer && g:fern#keepalt_on_edit,
        \ 'keepjumps': !a:options.is_drawer && g:fern#keepjumps_on_edit,
        \ 'mods': 'noautocmd',
        \})

  setlocal buftype=acwrite bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nowrap
  setlocal filetype=fern-renamer

  let b:fern_renamer_resolve = a:resolve
  let b:fern_renamer_factory = a:factory
  let b:fern_renamer_candidates = a:factory()

  augroup fern_renamer_internal
    autocmd! * <buffer>
    autocmd BufReadCmd  <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
    autocmd ColorScheme <buffer> call s:highlight()
  augroup END

  call s:highlight()
  call s:syntax()

  " Do NOT allow to add/remove lines
  nnoremap <buffer><silent> <Plug>(fern-renamer-p) :<C-u>call <SID>map_paste(0)<CR>
  nnoremap <buffer><silent> <Plug>(fern-renamer-P) :<C-u>call <SID>map_paste(-1)<CR>
  nnoremap <buffer><silent> <Plug>(fern-renamer-warn) :<C-u>call <SID>map_warn()<CR>
  inoremap <buffer><silent><expr> <Plug>(fern-renamer-warn) <SID>map_warn()
  nnoremap <buffer><silent> dd 0D
  nmap <buffer> p <Plug>(fern-renamer-p)
  nmap <buffer> P <Plug>(fern-renamer-P)
  nmap <buffer> o <Plug>(fern-renamer-warn)
  nmap <buffer> O <Plug>(fern-renamer-warn)
  imap <buffer> <C-m> <Plug>(fern-renamer-warn)
  imap <buffer> <Return> <Plug>(fern-renamer-warn)
  edit
  call cursor(a:options.cursor)
endfunction

function! s:map_warn() abort
  echohl WarningMsg
  echo 'Newline is prohibited in the renamer buffer'
  echohl None
  return ''
endfunction

function! s:map_paste(offset) abort
  let line = getline('.')
  let v = substitute(getreg(), '\r\?\n', '', 'g')
  let c = col('.') + a:offset - 1
  let l = line[:c]
  let r = line[c + 1:]
  call setline(line('.'), l . v . r)
endfunction

function! s:BufReadCmd() abort
  let b:fern_renamer_candidates = b:fern_renamer_factory()
  call s:syntax()
  call setline(1, b:fern_renamer_candidates)
endfunction

function! s:BufWriteCmd() abort
  if !&modifiable
    return
  endif
  let candidates = b:fern_renamer_candidates
  let results = []
  for index in range(len(candidates))
    let src = candidates[index]
    let dst = getline(index + 1)
    if empty(dst) || dst ==# src
      continue
    endif
    call add(results, [src, dst])
  endfor
  let Resolve = b:fern_renamer_resolve
  set nomodified
  close
  call Resolve(results)
endfunction

function! s:syntax() abort
  let pattern = '^$~.*[]\'

  syntax clear
  syntax match FernRenamed '^.\+$'

  for index in range(len(b:fern_renamer_candidates))
    let candidate = b:fern_renamer_candidates[index]
    execute printf(
          \ 'syntax match FernOrigin ''^\%%%dl%s$''',
          \ index + 1,
          \ escape(candidate, pattern),
          \)
  endfor
endfunction

function! s:highlight() abort
  highlight default link FernOrigin Normal
  highlight default link FernRenamed Special
endfunction
