let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#promise#chain(promise_factories) abort
  return s:chain(copy(a:promise_factories), [])
endfunction

function! s:chain(promise_factories, results) abort
  if empty(a:promise_factories)
    return s:Promise.resolve(a:results)
  endif
  let Factory = remove(a:promise_factories, 0)
  return Factory()
        \.then({ v -> add(a:results, v) })
        \.then({ -> s:chain(a:promise_factories, a:results) })
endfunction
