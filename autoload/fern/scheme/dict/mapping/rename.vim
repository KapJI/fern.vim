let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#mapping#rename#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-rename:select)   :<C-u>call <SID>call('rename', 'select')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:split)    :<C-u>call <SID>call('rename', 'split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:vsplit)   :<C-u>call <SID>call('rename', 'vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:tabedit)  :<C-u>call <SID>call('rename', 'tabedit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:above)    :<C-u>call <SID>call('rename', 'leftabove split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:left)     :<C-u>call <SID>call('rename', 'leftabove vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:below)    :<C-u>call <SID>call('rename', 'rightbelow split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:right)    :<C-u>call <SID>call('rename', 'rightbelow vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:top)      :<C-u>call <SID>call('rename', 'topleft split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:leftest)  :<C-u>call <SID>call('rename', 'topleft vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:bottom)   :<C-u>call <SID>call('rename', 'botright split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:rightest) :<C-u>call <SID>call('rename', 'botright vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:edit-or-error)   :<C-u>call <SID>call('rename', 'edit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:edit-or-split)   :<C-u>call <SID>call('rename', 'edit/split')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:edit-or-vsplit)  :<C-u>call <SID>call('rename', 'edit/vsplit')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename:edit-or-tabedit) :<C-u>call <SID>call('rename', 'edit/tabedit')<CR>

  " Alias map
  nmap <buffer><silent> <Plug>(fern-action-rename:edit) <Plug>(fern-action-rename:edit-or-error)
  nmap <buffer><silent> <Plug>(fern-action-rename) <Plug>(fern-action-rename:split)

  if !a:disable_default_mappings
    nmap <buffer><nowait> R <Plug>(fern-action-rename)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_rename(helper, opener) abort
  let root = a:helper.sync.get_root_node()
  let Factory = { -> map(copy(a:helper.sync.get_selected_nodes()), { _, n -> n._path }) }
  let ns = {}
  return fern#internal#renamer#rename(Factory, { 'opener': a:opener })
        \.then({ r -> s:_map_rename(a:helper, r) })
        \.then({ n -> s:Lambda.let(ns, 'n', n) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are renamed', ns.n)) })
endfunction

function! s:_map_rename(helper, result) abort
  let provider = a:helper.fern.provider
  let tree = provider._tree
  let proceeded = 0
  for pair in a:result
    let [src, dst] = pair
    if fern#scheme#dict#tree#exists(tree, src)
      echohl WarningMsg
      echo printf('%s does not exist', src)
      echohl None
      continue
    endif
    call fern#scheme#dict#tree#move(tree, src, dst)
    let proceeded += 1
  endfor
  call provider._update_tree(provider._tree)
  return s:Promise.resolve(proceeded)
endfunction
