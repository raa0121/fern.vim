let s:Config = vital#fern#import('Config')

" Define Public constant
let g:fern#STATUS_NONE = 0
let g:fern#STATUS_COLLAPSED = 1
let g:fern#STATUS_EXPANDED = 2
lockvar g:fern#STATUS_NONE
lockvar g:fern#STATUS_COLLAPSED
lockvar g:fern#STATUS_EXPANDED

" Define Public variables
call s:Config.config(expand('<sfile>:p'), {
      \ 'debug': 0,
      \ 'profile': 0,
      \ 'logfile': v:null,
      \ 'loglevel': g:fern#logger#INFO,
      \ 'opener': 'edit',
      \ 'keepalt_on_edit': 0,
      \ 'keepjumps_on_edit': 0,
      \ 'disable_default_mappings': 0,
      \ 'disable_drawer_auto_winfixwidth': 0,
      \ 'disable_drawer_auto_resize': 0,
      \ 'disable_drawer_auto_quit': 0,
      \ 'default_hidden': 0,
      \ 'default_include': '',
      \ 'default_exclude': '',
      \ 'grantor': 'default',
      \ 'grantors': {},
      \ 'renderer': 'default',
      \ 'renderers': {},
      \ 'comparator': 'default',
      \ 'comparators': {},
      \ 'drawer_width': 30,
      \ 'drawer_keep': v:false,
      \ 'mark_symbol': '*',
      \})
