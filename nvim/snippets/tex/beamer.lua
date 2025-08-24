-- luacheck:ignore 631
local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local m = extras.match
local p = extras.partial
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'bea', dscr = 'Beamer template' },
        fmta(
            [[
\PassOptionsToPackage{table,x11names}{xcolor}
\documentclass[leqno, 10pt, envcountsect]{beamer}

%------------------------------+
% Silence compilation warnings |
%------------------------------+
% Silence biblatex and caption warning when used with beamer
\usepackage{silence}
\WarningFilter{biblatex}{Patching footnotes failed}
\WarningFilter{caption}{Forced redefinition of}

%---------------------------------------+
% Source code, programming and patching |
%---------------------------------------+
\usepackage{embedfile}                 % Embed latex source code
% \embedfile{<embedfile>}
\usepackage{etoolbox}                  % Toolbox of programming tools
\usepackage{xpatch}                    % Extension of etoolbox patching commands

%--------------------------------------+
% Language, hyphenation, encoding, etc |
%--------------------------------------+
% Babel package
\usepackage[<second_lang>,<><babel_opts>]{babel}

\usepackage{lmodern}             % Use Latin Modern fonts
\usefonttheme[onlymath]{serif}   % Computer modern fonts in math
\usefonttheme{professionalfonts} % Prevent undesired replacements by beamer
\usepackage[T1]{fontenc}         % Better output when a diacritic/accent is used
\usepackage[utf8]{inputenc}      % Allows to input accented characters
\usepackage{textcomp}            % Avoid conflicts with siunitx and microtype
\usepackage{microtype}           % Improves justification and typography
<beamer_translator>
%-------------------------------------+
% Beamer style: theme, frames, titles |
%-------------------------------------+
% Use the default theme (alternative define another one like this:)
% \usetheme{Madrid}

% Frames (empty navigation bar and add roman number title when a frame is split)
\beamertemplatenavigationsymbolsempty
\setbeamertemplate{frametitle continuation}[from second][
	\insertcontinuationcountroman]

% Reduce margins (i.e increase textwidth)
\setbeamersize{text margin left=0.35cm,text margin right=0.35cm}

% Define color
\definecolor{<>}{RGB}{<rgb>}
\definecolor{<color>_light}{RGB}{<rgb_other>}

% Set frametitle, title and date color
\setbeamertemplate{headline}{\vskip 8pt}
\setbeamercolor*{title}{fg=<color>}
\setbeamercolor*{frametitle}{fg=<color>}
\setbeamerfont{frametitle}{size=\Large, series=\bfseries}
\setbeamertemplate{frametitle}{\hspace{-0.1cm}
	\expandafter\MakeUppercase\expandafter\insertframetitle
  % FIXME: this adds too much skip
  % \ifx\insertframesubtitle\@empty%
  % \else%
  %   \vskip0.25em \hspace{0.1cm}%
  %   {\usebeamerfont{framesubtitle}\usebeamercolor[fg]{framesubtitle}{\insertframesubtitle}ar}%
  % \fi%
}

% Insert Page number in footline
\defbeamertemplate*{footline}{example theme}
{\begin{beamercolorbox}[wd=\paperwidth, dp=2.5ex]{}
	\hfill\textcolor{<color>}{\scriptsize{\insertframenumber}}\hspace{0.4cm}
\end{beamercolorbox}
}

% Insert logo and rule in headline (load tikz package for this)
% To make this work with multiline frametitle see:
% https://tex.stackexchange.com/a/386733/9953
\usepackage{tikz}
\usetikzlibrary{arrows,intersections,calc,decorations.pathreplacing,
decorations.markings}
\addtobeamertemplate{frametitle}{}{%
\begin{tikzpicture}[remember picture,overlay]
\node[anchor=north east, yshift=3pt] at (current page.north east)
{\includegraphics[scale=0.01]{<logo>}};
%\draw[<color>] ([yshift=-0.65cm, xshift=0.25cm]current page.north west)
	% -- ([yshift=-0.65cm, xshift=\paperwidth - 0.25cm]current page.north west);
\end{tikzpicture}} % chktex 31

% Comment or uncomment to see notes
% \setbeameroption{show notes}
% Display notes with item option as an itemize environment (instead of an
% enumerate one)
\AtBeginNote{%
	\let\enumerate\itemize%
	\let\endenumerate\enditemize%
}
% \setbeameroption{show notes on second screen=right}

%-------------------------------+
% Math symbols and environments |
%-------------------------------+
\numberwithin{equation}{section}
\usepackage{amssymb}    % Defines most math symbols (such as \mathbb)
\usepackage{mathtools}  % Extension and bug fixes for amsmath package
\usepackage{mathrsfs}   % Math script like font
\usepackage{breqn}      % Automatic line breaking of math expressions
\renewcommand*{\intlimits}{\displaylimits}  % Fix breqn clash with intlimits

%------------------------------------+
% Definition of theorem environments |
%------------------------------------+
\setbeamertemplate{theorems}[numbered]

% Define numbered and unnumbered theorem environments
\newtheorem*{theorem*}{\translate{Theorem}}
\newtheorem{proposition}[theorem]{\translate{Proposition}}
\newtheorem*{proposition*}{\translate{Proposition}}
\newtheorem*{lemma*}{\translate{Lemma}}
\newtheorem*{corollary*}{\translate{Corollary}}

\theoremstyle{definition}
\newtheorem*{definition*}{\translate{Definition}}
\undef{\example}
\newtheorem{example}[theorem]{\translate{Example}}
\newtheorem*{example*}{\translate{Example}}
\newtheorem{exercise}[theorem]{\translate{Exercise}}
\newtheorem*{exercise*}{\translate{Exercise}}
\newtheorem*{problem*}{\translate{Problem}}
\newtheorem*{solution*}{\translate{Solution}}

\setbeamercolor*{block title example}{fg=white,bg=<color>_light}
\setbeamerfont{block title example}{shape=\itshape}
\theoremstyle{example}
\newtheorem{remark}[theorem]{\translate{Remark}}
\newtheorem*{remark*}{\translate{Remark}}
\newtheorem*{notation*}{\translate{Notation}}

% Remove dot from proof environment
\makeatletter
	\AtBeginEnvironment{proof}{\let\@addpunct\@gobble}
\makeatother

%---------------------+
% Floats and captions |
%---------------------+
% Beamer loads graphicx package by default and centers floats in figure and
% table environments
\graphicspath{{/home/pedro/OneDrive/programming/Latex/logos/}{figures/}{tables/}}

% We use load compatibility false to allow caption setup to work with beamer and
% set caption skip since we do not use floatrow which resets it
\usepackage[skip=\dimexpr\abovecaptionskip-2pt,compatibility=false]{caption}
\setbeamerfont{caption}{size=\small}
\setbeamercolor*{caption name}{fg=<color>_light}
\captionsetup*[figure]{format=plain,justification=centerlast,labelsep=quad}
\captionsetup*[table]{justification=centering,labelsep=newline}
\setbeamertemplate{caption}[numbered]
\numberwithin{figure}{section}
\numberwithin{table}{section}

% Use subcaption for subfigures (to work properly with hyperref)
\usepackage{subcaption}
\captionsetup*[subfigure]{font=footnotesize,subrefformat=simple,
	labelformat=simple}
\renewcommand*{\thesubfigure}{(\alph{subfigure})}

% FIXME: floatrow doesn't work without a placement option; is it needed?
% \usepackage[captionskip=5pt]{floatrow}  % Further modifications of float layout
% \floatsetup[table]{style=Plaintop,font=small,footnoterule=none,footskip=2.5pt}

% \usepackage{longtable}        % Allows to break tables through pages
% \floatsetup[longtable]{margins=centering,LTcapwidth=table}

%------------------------------------------------------+
% Miscellaneous packages: lists, listings, lipsum, etc |
%------------------------------------------------------+
% Lists symbols and colors
\useinnertheme{circles}

% Itemize
\newcommand*\smallcircled[1]{\tikz{
	\node[shape=circle,draw,inner sep=1.6pt] (char) {#1};}}
\setbeamertemplate{itemize item}{\large{$\bullet$}}
\setbeamertemplate{itemize subitem}{\smallcircled{}}
\setbeamertemplate{itemize subsubitem}{--}
\setbeamercolor*{itemize item}{fg=<color>}
\setbeamercolor*{itemize subitem}{fg=<color>}
\setbeamercolor*{itemize subsubitem}{fg=<color>}
\setlength{\leftmargini}{0.4cm}

% Enumerate
% Note: For a list of steps give the optional argument [Step 1.] to enumerate
% To use projected enumeration items comment the following line
\setbeamertemplate{enumerate items}[default]
\setbeamercolor*{item projected}{bg=<color>, fg=white}
\setbeamercolor*{enumerate item}{fg=<color>}
\setbeamercolor*{enumerate subitem}{fg=<color>}
\setbeamercolor*{enumerate subsubitem}{fg=<color>}
\renewcommand{\insertsubenumlabel}{\alph{enumii}}
\renewcommand{\insertsubsubenumlabel}{\roman{enumiii}}

% Increase item separation a bit
\let\olditem\item
\renewcommand{\item}{%
\olditem\vspace{1pt}}

% Temporary counter to store enumerate value
\newcounter{enumtemp}

% Code insertion (note: requires pygment python library and shell pdflatex flag)
\usepackage{minted}
% Define bg_color and frame border (using tcolorbox)
\definecolor{notebook_bg}{RGB}{247,247,247}
\definecolor{notebook_border}{RGB}{207,207,207}
\usepackage{tcolorbox}
\BeforeBeginEnvironment{minted}{\begin{tcolorbox}[colframe=notebook_border,
colback=notebook_bg, boxrule=0.4pt, left=0pt, top=0pt, bottom=0pt]}%
\AfterEndEnvironment{minted}{\end{tcolorbox}}%
% Set minted style
\setminted{style=default, fontsize=\scriptsize, autogobble}

% \usepackage{lipsum}    % Dummy text generator

\usepackage[normalem]{ulem} % strikethrough

%--------------------------+
% References and footnotes |
%--------------------------+
% Language sensitive quotation facilities
\usepackage[style=american]{csquotes}

\usepackage[style=authoryear-comp,backref=true,hyperref=false,
backend=biber]{biblatex}
\usepackage{mybibformat} % Modifications to authoryear-comp style and hyperlinks
% Beamer specific font and icon modifications
\setbeamercolor*{bibliography entry author}{fg=black}
\setbeamercolor*{bibliography entry note}{fg=black}
\setbeamertemplate{bibliography item}{}
% Name of bibfile
% \addbibresource{<base_bib>.bib}

% Reduce footnote rule length
\renewcommand*{\footnoterule}{\vspace*{0.2cm}\hrule width 2.5cm\vspace*{0.2cm}}

%--------------------------------------------+
% Hyperlinks, bookmarks and cross-references |
%--------------------------------------------+
% Beamer hyperlink buttons
\setbeamercolor{button}{bg=structure.fg!75!black,fg=white}
\setbeamerfont{button}{size=\scriptsize}

% Hyperref setup
\hypersetup{colorlinks=true, allcolors=<color>_light,
pdfcreator={Vim LaTeX}, pdfsubject={},
pdftitle={<pdftitle>},
pdfauthor={<pdfauthor>},
pdfkeywords={}
}

% Add anchor for equations, figures and tables
\makeatletter
\newcounter{phantomtarget}
\renewcommand*{\thephantomtarget}{phantom.\the\value{phantomtarget}}
\newcommand*{\phantomtarget}{%
	\stepcounter{phantomtarget}%
	\hypertarget{\thephantomtarget}{}%
	\edef\@currentHref{\thephantomtarget}%
}
\makeatother
% We use \appto to account for allowframbreaks
\appto{\equation}{\phantomtarget}
\appto{\figure}{\phantomtarget}
\appto{\table}{\phantomtarget}
\appto{\proposition}{\phantomtarget}
\appto{\corollary}{\phantomtarget}
\appto{\definition}{\phantomtarget}
\appto{\exercise}{\phantomtarget}
\appto{\remark}{\phantomtarget}
\appto{\problem}{\phantomtarget}
\appto{\solution}{\phantomtarget}
% For some theorems we use \AtBeginEnvironment due to the optional name argument
\AtBeginEnvironment{theorem}{\phantomtarget}
\AtBeginEnvironment{example}{\phantomtarget}
\AtBeginEnvironment{lemma}{\phantomtarget}
% \AtBeginEnvironment{subfigure}{\phantomtarget}

% Hyperlink parentheses and create cleveref-like command
\renewcommand*{\eqref}[1]{\hyperref[#1]{(\ref*{#1})}}
\newcommand{\crefnostar}[1]{\hyperref[#1]{\ref*{#1}}}
\newcommand{\crefstar}[1]{\ref*{#1}}      % No hyperlink (useful for proof env.)
\makeatletter
\newcommand{\cref}{\@ifstar{\crefstar}{\crefnostar}}
\makeatother

% Bookmarks for each frame
% TODO: Use short section names
\usepackage[open, openlevel=1]{bookmark}
\makeatletter
\apptocmd{\beamer@@frametitle}{\only<<1>>{%
	\bookmark[page=\the\c@page,level=3]{#1 \expandafter%
		\ifnum\insertcontinuationcount>>1%
			\relax\insertcontinuationcountroman%
		\fi}%
	}}%
\makeatother

%------------------------+
% Title and TOC settings |
%------------------------+
% Reduce date font and change title and subtitle color
\setbeamerfont{title}{shape=\bfseries, size=\Large}
\setbeamerfont{subtitle}{series=\mdseries}
\setbeamerfont{date}{size=\scriptsize}
\setbeamercolor{title}{fg=<color>}

% Use uppercase for title and subtitle
\makeatletter
\setbeamertemplate{title page}{%
	\vbox{}
	\vfill
	\begingroup
		\vspace{1cm}  % for centering
		\centering
		\begin{beamercolorbox}[sep=8pt,center]{title}
		\usebeamerfont{title}\MakeUppercase{\inserttitle}\par%
		\ifx\insertsubtitle\@empty%
		\else%
			\vskip0.25em%
			{\usebeamerfont{subtitle}\usebeamercolor[fg]{subtitle}\MakeUppercase{\insertsubtitle}\par}%
		\fi%
	\end{beamercolorbox}%
	\vskip1em\par
	\begin{beamercolorbox}[sep=8pt,center]{author}
		\usebeamerfont{author}\insertauthor
	\end{beamercolorbox}
	\begin{beamercolorbox}[sep=8pt,center]{institute}
		\usebeamerfont{institute}\insertinstitute
	\end{beamercolorbox}
	\begin{beamercolorbox}[sep=8pt,center]{date}
		\usebeamerfont{date}\insertdate
	\end{beamercolorbox}\vskip0.5em
	{\usebeamercolor[fg]{titlegraphic}\inserttitlegraphic\par}
	\endgroup
	\vfill
}
\makeatother

% Increase separation between top of the slide and title
\makeatletter
\expandafter\patchcmd\csname beamer@@tmpl@title page\endcsname%
	{\vfill}{\vspace*{0.3cm}}{}{}
\makeatother

% Actually define maketitle
\title[<heading>]{<title>}
\subtitle{<subtitle>}
\author[<institute>]{<author>}
\institute[]{<date>}
\date[]{\includegraphics[scale=0.02]{<logo_fn>}}

% Add agenda toc frame at the beginning of each section and anchor for proper
% hyperlinking
\AtBeginSection[]{
	\phantomtarget
	\begin{frame}[fragile=singleslide]
		\frametitle{Agenda}
		\tableofcontents[currentsection]
	\end{frame}
}
% Increase TOC number size
\setbeamerfont{section number projected}{size=\footnotesize}
% Change toc bullets to circles and use black color
\newcommand*\circled[1]{\tikz[baseline=(char.base)]{
	\node[shape=circle,draw=<color>,inner sep=2pt,
	line width=0.6pt, text=black] (char) {#1};}}
\setbeamertemplate{section in
toc}{\circled{\small{\inserttocsectionnumber}}~%
\bfseries{\inserttocsection}}

%---------------------------------------------------+
% (Re)Definition of new commands and math operators |
%---------------------------------------------------+
% Numbers
\DeclareMathOperator{\N}{\mathbb{N}}
\DeclareMathOperator{\Z}{\mathbb{Z}}
\DeclareMathOperator{\Q}{\mathbb{Q}}
\DeclareMathOperator{\R}{\mathbb{R}}
% Probability
\DeclareMathOperator{\E}{\mathbb{E}}
\DeclareMathOperator{\var}{\mathrm{Var}}
\DeclareMathOperator{\cov}{\mathrm{Cov}}
% Delimiters
\DeclarePairedDelimiter{\abs}{\lvert}{\rvert}
\DeclarePairedDelimiter{\norm}{\lvert\lvert}{\rvert\rvert}
% Miscellaneous
\renewcommand{\d}{\ensuremath{\operatorname{d}\!}}  % Differential
\renewcommand{\L}{\ensuremath{\operatorname{\mathcal{L}}}}  % Lagrangian


\begin{document}

\frame[plain]{\titlepage}

<>

\end{document}
]],
            {
                embedfile = p(_G.LuaSnipConfig.filepart, 'basename'),
                second_lang = m(1, '^spanish$', 'english', 'spanish'),
                c(1, { t('spanish'), t('english') }),
                babel_opts = m(
                    1,
                    '^spanish$',
                    [[,es-noindentfirst,es-nosectiondot,es-nolists,
es-noshorthands,es-lcroman,es-tabla]]
                ),
                beamer_translator = m(
                    1,
                    '^spanish$',
                    [[

% Translator package (loaded by beamer)
\uselanguage{spanish}
\languagepath{spanish}
\deftranslation[to=spanish]{Theorem}{Teorema}
\deftranslation[to=spanish]{Proposition}{Proposición}
\deftranslation[to=spanish]{Lemma}{Lema}
\deftranslation[to=spanish]{Corollary}{Corolario}
\deftranslation[to=spanish]{Definition}{Definición}
\deftranslation[to=spanish]{Example}{Ejemplo}
\deftranslation[to=spanish]{Exercise}{Ejercicio}
\deftranslation[to=spanish]{Problem}{Enunciado}
\deftranslation[to=spanish]{Solution}{Solución}
\deftranslation[to=spanish]{Remark}{Observación}
\deftranslation[to=spanish]{Notation}{Notación}
                ]]
                ),
                c(2, { t('mutt'), t('other') }), -- \definecolor{<>}{RGB}{<>}
                rgb = m(2, '^mutt$', '0,41,91', '31,117,254'),
                -- Note: choice nodes requiere a jump-index i.e we cannot use a variable:
                color = rep(2),
                rgb_other = m(2, '^mutt$', '29,66,129', '136,151,164'),
                base_bib = p(_G.LuaSnipConfig.filepart, 'basename_no_ext'),
                heading = i(3, 'heading'),
                title = i(4, 'title'),
                pdftitle = rep(4),
                subtitle = i(5, 'subtitle'),
                institute = i(6, 'institution'),
                author = i(7, 'authors'),
                pdfauthor = rep(7),
                date = m(1, '^spanish$', '\\Today', '\\today'),
                logo_fn = i(8, 'logo_mutt.png'),
                logo = rep(8),
                i(9),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'bf', dscr = 'Beamer frame' },
        fmta(
            [[
                \begin{frame}[<>]
                \frametitle{<>}
                  <><>
                \end{frame}
            ]],
            {
                c(1, { sn(nil, { i(1, 'fragile=singleslide') }), t('allowframebreaks') }),
                i(2, 'title'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ft', dscr = 'Frame title' },
        fmta(
            [[
        \frametitle{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'title'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fs', dscr = 'Frame subtitle' },
        fmta(
            [[
        \framesubtitle{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'subtitle'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'blo', dscr = 'Beamer block' },
        fmta(
            [[
                \begin{block}{<>}
                  <><>
                \end{block}
            ]],
            {
                i(1, 'title'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
}, {}
