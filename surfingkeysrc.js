/* eslint-disable no-undef */
// Preamble {{{

// For surfingkeys 1.0
const {
    aceVimMap,
    mapkey,
    imap,
    imapkey,
    getClickableElements,
    vmapkey,
    map,
    unmap,
    unmapAllExcept,
    cmap,
    vmap,
    addSearchAlias,
    removeSearchAlias,
    tabOpenLink,
    readText,
    Clipboard,
    Front,
    Hints,
    Visual,
    RUNTIME
} = api;

// To load this local config file on chromium like browsers (on firefox we need
// to manually copy and paste):
// i) Check `Allow access to file URLS` for surfingkeys in the general extensions
// view
// ii) In the extensions settings check `Advanced mode` box and add path to this
// file

// To ensure that surfingkeys keys works when starting Chrome or creating a
// new tab set the starting page and the new tab page to something other than
// Chrome's default `chrome//newtab` (for instance google.com)

unmapAllExcept(['f', '/', '*', ':', '.', 'i', 'I', '<Ctrl-i>', 'v', 'm']);

// }}}
// Options and Appearance {{{

settings.omnibarPosition = 'bottom';
settings.showTabIndices = true;
settings.focusFirstCandidate = false;
settings.enableAutoFocus = true;
settings.modeAfterYank = 'Normal';
settings.hintAlign = 'left';
settings.editableBodyCare = false;
settings.noPdfViewer = true;

// Define hint characters
Hints.setCharacters('asdfghjkl');


// Theme (uses Onedark colors)
settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 10pt;
    background: #24272e;
    color: #abb2bf;
}
.sk_theme tbody {
    color: #fff;
}
.sk_theme input {
    color: #d0d0d0;
}
.sk_theme .url {
    color: #61afef;
}
.sk_theme .annotation {
    color: #56b6c2;
}
.sk_theme .omnibar_highlight {
    color: #528bff;
}
.sk_theme .omnibar_timestamp {
    color: #e5c07b;
}
.sk_theme .omnibar_visitcount {
    color: #98c379;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #303030;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 20pt;
}`;

mapkey(',me', 'Mapping explorer (show usage)', function () {
    Front.showUsage();
});

// }}}
// Bookmarks/Quickmarks {{{

// View and add bookmarks
mapkey(',bm', 'Open bookmarks', function () {
    Front.openOmnibar({ type: 'Bookmarks' });
});
mapkey(',ab', 'Bookmark current page to selected folder', function () {
    let page = {
        url: window.location.href,
        title: document.title,
    };
    Front.openOmnibar({ type: 'AddBookmark', extra: page });
});

// Quickmarks (own implementation)
const qmarksMapKey = function (prefix, urls) {
    const newTab = prefix !== "'";
    const openLink = function (link, newTab) {
        return function () {
            RUNTIME('openLink', {
                tab: { tabbed: newTab },
                url: link,
            });
        };
    };
    for (var key in urls) {
        mapkey(
            prefix + key,
            'qmark: ' + urls[key],
            openLink(urls[key], newTab)
        );
    }
};

const qmarksUrls = {
    a: 'https://aws.amazon.com/console',
    b: 'https://bard.google.com',
    B: 'www.bing.com/chat',
    c: 'www.utdt.edu/campusvirtual',
    d: 'https://drive.google.com/drive/u/0/folders/0B9ulz1YH9ei7dGJValg1Tm9tMVE',
    g: 'www.github.com',
    h: 'www.google.com.ar',
    i: 'www.infobae.com',
    l: 'www.lanacion.com.ar',
    L: 'http://neverssl.com/', // to trigger captive (L)ogin wifi page
    m: 'https://mercadolibre.com.ar',
    M: 'https://mail.google.com',
    n: 'www.netflix.com',
    N: 'synology-ds:5000',
    o: 'https://onedrive.live.com',
    p: 'app.powerbi.com',
    r: 'www.reddit.com',
    s: 'http://stackoverflow.com',
    u: 'www.alumnos.econ.uba.ar',
    v: 'http://virtual.econ.uba.ar/',
    y: 'www.youtube.com',
    // Printing (arch)
    q: 'http://localhost:631/jobs',
};
qmarksMapKey('"', qmarksUrls);
qmarksMapKey('\'', qmarksUrls);

// Surfingkeys ViMarks
mapkey('`', 'Jump to vim-like mark in current tab', function (mark) {
    Normal.jumpVIMark(mark);
});
// mapkey('"', 'Jump to vim-like mark in new tab', function(mark) {
// Normal.jumpVIMark(mark, true);
// });
mapkey(',qm', 'Open URL from vim-like marks', function () {
    Front.openOmnibar({ type: 'VIMarks' });
});

// }}}
// Navigation and tab handling  {{{

// Page navigation (and opening links)
mapkey('r', 'Refresh', function () {
    RUNTIME.repeats = 1;
    RUNTIME('reloadTab', { nocache: false });
});
mapkey('H', 'Backward', function () {
    history.go(-1);
});
mapkey('L', 'Forward', function () {
    history.go(1);
});
mapkey('F', 'Open a link in non-active new tab', function () {
    Hints.create('', Hints.dispatchMouseClick, { tabbed: true, active: false });
});

// Page movement (and searching)
mapkey('j', 'Roll down', function () {
    window.scrollTo(0, window.pageYOffset+25)
});
mapkey('k', 'Roll up', function () {
    window.scrollTo(0, window.pageYOffset-25)
});
mapkey('h', 'Roll left', function () {
    window.scrollTo(window.pageXOffset-25, 0)
});
mapkey('l', 'Roll right', function () {
    window.scrollTo(window.pageXOffset+25, 0)
});
mapkey('<Ctrl-u>', 'Scroll up half a page', function () {
    window.scrollTo(0, window.pageYOffset-window.innerHeight*0.6)
});
mapkey('<Ctrl-d>', 'Scroll down half a page', function () {
    window.scrollTo(0, window.pageYOffset+window.innerHeight*0.6)
});
mapkey('gg', 'Jump to the top of the page', function () {
    window.scrollTo(0, window.pageYOffset-1000000000)
});
mapkey('G', 'Jump to the bottom of the page', function () {
    window.scrollTo(0, window.pageYOffset+1000000000)
});
mapkey('n', 'Next search result', function () {
    Visual.next(false);
});
mapkey('N', 'Previous search result', function () {
    Visual.next(true);
});

// Tabs
mapkey(',nt', 'Open new tab', function () {
    tabOpenLink('www.google.com.ar');
});
mapkey('<Ctrl-c>', 'Close tab', function () {
    RUNTIME.repeats = 1;
    RUNTIME('closeTab');
});
map(',wd', '<Ctrl-c>');
map(',bd', '<Ctrl-c>');
// Ctrl-n cannot be mapped on Linux so we use alt-n (and alt-p) instead
mapkey('<Alt-n>', 'Go one tab right', function () {
    RUNTIME.repeats = 1;
    RUNTIME('nextTab');
});
mapkey('<Alt-p>', 'Go one tab left', function () {
    RUNTIME.repeats = 1;
    RUNTIME('previousTab');
});
mapkey('<Alt-h>', 'Move current tab to left', function () {
    RUNTIME.repeats = 1;
    RUNTIME('moveTab', { step: -1 });
});
mapkey('<Alt-l>', 'Move current tab to right', function () {
    RUNTIME.repeats = 1;
    RUNTIME('moveTab', { step: 1 });
});
mapkey('<Alt-w>', 'New window with current tab', function () {
    Front.openOmnibar(({type: "Windows"}));
});
mapkey(',be', 'Choose a tab with omnibar', function () {
    Front.openOmnibar({ type: 'Tabs' });
});
mapkey(',bc', 'Choose a tab', function () {
    Front.chooseTab();
});
// TODO: Do this with `,n`
mapkey('T', 'Choose a tab (use nT to move to the nth tab)', function () {
    Front.chooseTab();
});
mapkey('M', 'Mute/unmute current tab', function () {
    RUNTIME('muteTab');
});

// Yanking and pasting
mapkey('y', "Copy current page's URL", function () {
    Clipboard.write(window.location.href);
});
mapkey('p', 'Open the clipboard in the current tab', function () {
    let data;
    Clipboard.read(function (response) {
        if (
            response.data.startsWith('http://') ||
            response.data.startsWith('https://') ||
            response.data.startsWith('www.')
        ) {
            data = response.data;
        } else {
            data = 'https://www.google.com/search?q=' + response.data;
        }
        RUNTIME.repeats = 1;
        RUNTIME('openLink', {
            tab: { tabbed: false },
            url: data,
        });
    });
});
mapkey('P', 'Open the clipboard in a new tab', function () {
    let data;
    Clipboard.read(function (response) {
        if (
            response.data.startsWith('http://') ||
            response.data.startsWith('https://') ||
            response.data.startsWith('www.')
        ) {
            data = response.data;
        } else {
            data = 'https://www.google.com/search?q=' + response.data;
        }
        RUNTIME.repeats = 1;
        RUNTIME('openLink', {
            tab: { tabbed: true },
            url: data,
        });
    });
});

// Zoom
mapkey('<Meta-0>', 'Zoom reset', function () {
    RUNTIME('setZoom', {
        zoomFactor: 0,
    });
});
mapkey('<Meta-=>', 'Zoom in', function () {
    RUNTIME('setZoom', {
        zoomFactor: 0.1,
    });
});
mapkey('<Meta-->', 'Zoom out', function () {
    RUNTIME('setZoom', {
        zoomFactor: -0.1,
    });
});
mapkey('<Meta-u>', 'Zoom up when changing monitors', function () {
    RUNTIME('setZoom', {
        zoomFactor: 1,
    });
});
mapkey('<Meta-d>', 'Zoom down when changing monitors', function () {
    RUNTIME('setZoom', {
        zoomFactor: -1,
    });
});

// }}}
// Omnibar {{{

// Map ; to :
mapkey(';', 'Open commands', function () {
    Front.openOmnibar({ type: 'Commands' });
});

// Move in omnibar (first candidate is in the bottom)
cmap('<Ctrl-p>', '<Tab>');
cmap('<Ctrl-n>', '<Shift-Tab>');
cmap('<Ctrl-k>', '<Tab>');
cmap('<Ctrl-j>', '<Shift-Tab>');

// URLs
mapkey('o', 'Open a URL in current tab', function () {
    Front.openOmnibar({ type: 'URLs', extra: 'getAllSites', tabbed: false });
});
mapkey('t', 'Open a URL in a new tab', function () {
    Front.openOmnibar({ type: 'URLs', extra: 'getAllSites' });
});
mapkey('u', 'Open recently closed URL', function () {
    Front.openOmnibar({ type: 'URLs', extra: 'getRecentlyClosed' });
});

// Search engines (see https://github.com/b0o/surfingkeys-conf to add extra
// completions)
mapkey('s', 'Search in google in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'g', tabbed: false });
});
mapkey('S', 'Search in google in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'g' });
});
addSearchAlias(
    's',
    'StackOverflow',
    'https://stackoverflow.com/search?q=',
    's',
    'https://api.stackexchange.com/2.2/search/advanced?pagesize=10&' +
        'order=desc&sort=relevance&site=stackoverflow&q=',
    function (response) {
        var res = JSON.parse(response.text)['items'];
        return res.map(function (r) {
            return {
                title: '[' + r.score + '] ' + r.title,
                url: r.link,
            };
        });
    }
);
mapkey(',ss', 'Search in StackOverflow in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 's', tabbed: false });
});
mapkey(',Ss', 'Search in StackOverflow in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 's' });
});
addSearchAlias(
    'h',
    'GitHub',
    'https://github.com/search?q=',
    's',
    'https://api.github.com/search/repositories?order=desc&q=',
    function (response) {
        var res = JSON.parse(response.text)['items'];
        return res.map(function (r) {
            var prefix = '';
            if (r.stargazers_count) {
                prefix += '[★' + r.stargazers_count + '] ';
            }
            return {
                title: prefix + r.description,
                url: r.html_url,
            };
        });
    }
);
mapkey(',sg', 'Search in Github in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'h', tabbed: false });
});
mapkey(',Sg', 'Search in Github in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'h' });
});
addSearchAlias(
    'w',
    'Wikipedia',
    'https://en.wikipedia.org/w/index.php?search=',
    's',
    'https://en.wikipedia.org/w/api.php?action=query&format=json' +
        '&list=prefixsearch&utf8&pssearch=',
    function (response) {
        const res = JSON.parse(response.text).query.prefixsearch.map(
            (r) => r.title
        );
        return res;
    }
);
mapkey(',sw', 'Search in Wikpedia in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'w', tabbed: false });
});
mapkey(',Sw', 'Search in Wikpedia in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'w' });
});
addSearchAlias(
    'y',
    'YouTube',
    'https://www.youtube.com/results?search_query='
);
mapkey(',sy', 'Search in Youtube in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'y', tabbed: false });
});
mapkey(',Sy', 'Search in Youtube in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'y' });
});
addSearchAlias(
    'm',
    'MercadoLibre',
    'http://www.mercadolibre.com.ar/jm/search?as_word='
);
mapkey(',sm', 'Search in MercadoLibre in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'm', tabbed: false });
});
mapkey(',Sm', 'Search in MercadoLibre in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'm' });
});
addSearchAlias(
    'd',
    'Google Drive',
    'https://drive.google.com/drive/u/0/search?q='
);
mapkey(',sd', 'Search in Google Drive in current tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'd', tabbed: false });
});
mapkey(',Sd', 'Search in Google Drive in new tab', function () {
    Front.openOmnibar({ type: 'SearchEngine', extra: 'd' });
});

// History
mapkey(',hs', 'Open URL from history', function () {
    Front.openOmnibar({ type: 'History', tabbed: false });
});
mapkey(',th', 'Open URL from history in a new tab', function () {
    Front.openOmnibar({ type: 'History' });
});
// FIXME: Not working?
mapkey(',dh', 'Delete history older than 30 days', function () {
    RUNTIME('deleteHistoryOlderThan', {
        days: 30,
    });
});

// }}}
// Insert mode and AceVim {{{

// Note: we can show available input boxes with i or I and enter vim editor mode
// with <Ctrl-I>

mapkey('gi', 'Go to the first edit box', function () {
    Hints.createInputLayer();
});
// FIXME: Not working (and can't cycle through input boxes with tab)
mapkey('gI', 'Go to the second edit box', function () {
    Hints.create('input[type=text]:nth(1)', Hints.dispatchMouseClick);
});

// Mappings
// FIXME: These are not working
imap('jj', '<Esc>');
imap('<Ctrl-a>', '<Ctrl-f>');
imap('<Ctrl-h>', '<ArrowLeft>');
imap('<Ctrl-l>', '<ArrowRight>');

// AceVim
aceVimMap('jj', '<Esc>', 'insert');
aceVimMap('H', '0', 'normal');
aceVimMap('L', '$', 'normal');

// }}}
// Visual mode {{{

vmap('L', '$');
vmap('H', '0');

// }}}
// Blacklisting and domain specific maps {{{

// Pass through mode (toggle i.e disable Surfingkeys)
// map(',pt', '<Alt-s>');  // Must be one key stroke

// Note: if we blacklist we loose all mappings
// settings.blacklistPattern = /.*docs\.google\.com.*/i;
mapkey(',pt', 'Enter PassThrough mode', function () {
    Normal.passThrough();
});

imapkey(
    '<Alt-p>',
    'Previous Tab',
    function () {
        RUNTIME.repeats = 1;
        RUNTIME('previousTab');
    },
    {
        domain: /.*docs\.google\.com.*/i,
    }
);
imapkey(
    '<Alt-n>',
    'Next Tab',
    function () {
        RUNTIME.repeats = 1;
        RUNTIME('nextTab');
    },
    {
        domain: /.*docs\.google\.com.*/i,
    }
);

// }}}
// Convenient mappings {{{

// Session handling
mapkey(',kv', 'Save session and quit', function () {
    RUNTIME('createSession', {
        name: 'LAST',
        quitAfterSaved: true,
    });
});
mapkey(',ps', 'Restore previous session', function () {
    RUNTIME('openSession', {
        name: 'LAST',
    });
});

// View page source
mapkey(',vs', 'View page source', function () {
    RUNTIME('viewSource', { tab: { tabbed: true } });
});

// Chrome specific
mapkey(',dl', 'Open Chrome Downloads', function () {
    tabOpenLink('chrome://downloads/');
});
mapkey(',cd', 'Close Downloads Shelf', function () {
    RUNTIME('closeDownloadsShelf', { clearHistory: true });
});
mapkey(',ad', 'Open Chrome Extensions', function () {
    tabOpenLink('chrome://extensions/');
});
mapkey(',hc', 'Open Chrome History', function () {
    tabOpenLink('chrome://history/');
});

// }}}
