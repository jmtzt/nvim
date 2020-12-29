"let g:startify_session_dir = '~/.config/nvim/session'
let g:startify_lists = [
          \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
          \ { 'type': 'files',     'header': ['   Files']            },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
          \ ]
"          \ { 'type': 'sessions',  'header': ['   Sessions']       },

let g:startify_bookmarks = [
            \ { 'c': '~/.config/' },
            \ { 'n': '~/.config/nvim' },
            \ { 'z': '~/.zshrc' },
            \ '~/data/',
            \ '~/data/LATICINIO/backendlat',
            \ '~/data/LATICINIO/frontendlat',
            \ ]


let g:startify_custom_header = [
 \ ' _        _______  _______          _________ _______ ',
 \ '( (    /|(  ____ \(  ___  )|\     /|\__   __/(       )',
 \ '|  \  ( || (    \/| (   ) || )   ( |   ) (   | () () |',
 \ '|   \ | || (__    | |   | || |   | |   | |   | || || |',
 \ '| (\ \) ||  __)   | |   | |( (   ) )   | |   | |(_)| |',
 \ '| | \   || (      | |   | | \ \_/ /    | |   | |   | |',
 \ '| )  \  || (____/\| (___) |  \   /  ___) (___| )   ( |',
 \ '|/    )_)(_______/(_______)   \_/   \_______/|/     \|',
\]
