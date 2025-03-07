let s:Config = vital#fern#import('Config')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:ESCAPE_PATTERN = '^$~.*[]\'
let s:STATUS_NONE = g:fern#STATUS_NONE
let s:STATUS_COLLAPSED = g:fern#STATUS_COLLAPSED

function! fern#renderer#default#new() abort
  return {
        \ 'render': funcref('s:render'),
        \ 'index': funcref('s:index'),
        \ 'lnum': funcref('s:lnum'),
        \ 'syntax': funcref('s:syntax'),
        \ 'highlight': funcref('s:highlight'),
        \}
endfunction

function! s:render(nodes) abort
  let options = {
        \ 'leading': g:fern#renderer#default#leading,
        \ 'root_symbol': g:fern#renderer#default#root_symbol,
        \ 'leaf_symbol': g:fern#renderer#default#leaf_symbol,
        \ 'expanded_symbol': g:fern#renderer#default#expanded_symbol,
        \ 'collapsed_symbol': g:fern#renderer#default#collapsed_symbol,
        \}
  let base = len(a:nodes[0].__key)
  let Profile = fern#profile#start('fern#renderer#default#s:render')
  return s:AsyncLambda.map(copy(a:nodes), { v, -> s:render_node(v, base, options) })
        \.finally({ -> Profile() })
endfunction

function! s:index(lnum) abort
  return a:lnum - 1
endfunction

function! s:lnum(index) abort
  return a:index + 1
endfunction

function! s:syntax() abort
  execute printf(
        \ 'syntax match FernRootSymbol /\%%1l%s/ nextgroup=FernRootText',
        \ escape(g:fern#renderer#default#root_symbol, s:ESCAPE_PATTERN),
        \)
  execute printf(
        \ 'syntax match FernLeafSymbol /^\s*%s/ nextgroup=FernLeafText',
        \ escape(g:fern#renderer#default#leaf_symbol, s:ESCAPE_PATTERN),
        \)
  execute printf(
        \ 'syntax match FernBranchSymbol /^\s*\%%(%s\|%s\)/ nextgroup=FernBranchText',
        \ escape(g:fern#renderer#default#collapsed_symbol, s:ESCAPE_PATTERN),
        \ escape(g:fern#renderer#default#expanded_symbol, s:ESCAPE_PATTERN),
        \)
  syntax match FernRootText   /.*\ze .*$/ contained nextgroup=FernBadge
  syntax match FernLeafText   /.*\ze .*$/ contained nextgroup=FernBadge
  syntax match FernBranchText /.*\ze .*$/ contained nextgroup=FernBadge
  syntax match FernBadge      /.*/        contained
endfunction

function! s:highlight() abort
  highlight default link FernRootSymbol   Directory
  highlight default link FernRootText     Directory
  highlight default link FernLeafSymbol   Directory
  highlight default link FernLeafText     None
  highlight default link FernBranchSymbol Directory
  highlight default link FernBranchText   Directory
endfunction

function! s:render_node(node, base, options) abort
  let level = len(a:node.__key) - a:base
  if level is# 0
    return a:options.root_symbol . a:node.label . ' ' . a:node.badge
  endif
  let leading = repeat(a:options.leading, level - 1)
  let symbol = a:node.status is# s:STATUS_NONE
        \ ? a:options.leaf_symbol
        \ : a:node.status is# s:STATUS_COLLAPSED
        \   ? a:options.collapsed_symbol
        \   : a:options.expanded_symbol
  return leading . symbol . a:node.label . ' ' . a:node.badge
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'leading': ' ',
      \ 'root_symbol': '',
      \ 'leaf_symbol': '|  ',
      \ 'collapsed_symbol': '|+ ',
      \ 'expanded_symbol': '|- ',
      \})

" Obsolete warnings
if exists('g:fern#renderer#default#marked_symbol')
  call fern#util#obsolete(
        \ 'g:fern#renderer#default#marked_symbol',
        \ 'g:fern#mark_symbol',
        \)
endif
if exists('g:fern#renderer#default#unmarked_symbol')
  call fern#util#obsolete('g:fern#renderer#default#unmarked_symbol')
endif
