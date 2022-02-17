let s:sign_names = {
            \ ' A': 'DirGutterAdded',
            \ ' M': 'DirGutterModified',
            \ ' D': 'DirGutterDeleted',
            \ ' R': 'DirGutterRenamed',
            \ ' C': 'DirGutterCopied',
            \ 'A ': 'DirGutterAddedStaged',
            \ 'AM': 'DirGutterAddedStagedModified',
            \ 'AD': 'DirGutterAddedStagedDeleted',
            \ 'M ': 'DirGutterModifiedStaged',
            \ 'MM': 'DirGutterModifiedStagedModified',
            \ 'MD': 'DirGutterModifiedStagedDeleted',
            \ 'D ': 'DirGutterDeletedStaged',
            \ 'DR': 'DirGutterDeletedStagedRenamed',
            \ 'DC': 'DirGutterDeletedStagedCopied',
            \ 'R ': 'DirGutterRenamedStaged',
            \ 'RM': 'DirGutterRenamedStagedModified',
            \ 'RD': 'DirGutterRenamedStagedDeleted',
            \ 'C ': 'DirGutterCopiedStaged',
            \ 'CM': 'DirGutterCopiedStagedModified',
            \ 'CD': 'DirGutterCopiedStagedDeleted',
            \ 'AA': 'DirGutterUnmergedBothAdded',
            \ 'UU': 'DirGutterUnmergedBothModified',
            \ 'DD': 'DirGutterUnmergedBothDeleted',
            \ 'AU': 'DirGutterUnmergedAddedByUs',
            \ 'UA': 'DirGutterUnmergedAddedByThem',
            \ 'DU': 'DirGutterUnmergedDeletedByUs',
            \ 'UD': 'DirGutterUnmergedDeletedByThem',
            \ '??': 'DirGutterUntracked',
            \ '!!': 'DirGutterIgnored',
            \ }

function! dirgutter#define_signs()
    for [symbol, name] in items(s:sign_names)
        let sign = {'text': symbol}
        if symbol =~# 'A.*\| A'
            let sign.texthl = 'GitGutterAdd'
            let sign.numhl = 'GitGutterAdd'
        elseif symbol =~# 'D.*\| D'
            let sign.texthl = 'GitGutterDelete'
            let sign.numhl = 'GitGutterDelete'
        elseif symbol =~# 'M.*\| M'
            let sign.texthl = 'GitGutterChange'
            let sign.numhl = 'GitGutterChange'
        elseif symbol =~# '??'
            let sign.texthl = 'GitGutterChangeDelete'
        endif
        call sign_define(name, sign)
    endfor
endfunction

function! dirgutter#place_signs()
    if !isdirectory(expand('%'))
        " current buffer is no directory -> return!
        return
    endif
    let l:cur_dir = expand('%')
    " get git status
    let l:status = systemlist(printf('git status --porcelain --short --renames --ignored=matching %s', l:cur_dir))
    let l:files = {}
    " construct dictionary mapping buffer lines to git status
    for l:line in l:status
        let l:state = line[0:1]
        let l:file = get(split(l:line), 1)
        let l:files[file] = l:state
        if get(split(l:line), 3) !=# '0'
            " rename or copy separating two paths by ' -> '
            " thus, we also include the second path with the same state
            let l:files[get(split(l:line), 3)] = l:state
        endif
    endfor
    let l:linenr = 0
    let l:signid = 0
    " place git status signs on buffer lines
    while l:linenr < line('$')
        let l:linenr += 1
        let l:line = fnamemodify(getline(l:linenr), ':.')
        let l:found = 0
        for l:file in keys(l:files)
            if matchstr(l:file, l:line) !=# ''
                call sign_place(l:signid, 'dirgutter', s:sign_names[l:files[l:file]], '%', {'lnum': l:linenr})
                let l:signid += 1
                let l:found = 1
            endif
        endfor
        if l:found == 0 && empty(systemlist('ls -A ' . l:line))
            " empty directories are also ignored by git
            call sign_place(l:signid, 'dirgutter', 'DirGutterIgnored', '%', {'lnum': l:linenr})
            let l:signid += 1
        endif
    endwhile
endfunction
