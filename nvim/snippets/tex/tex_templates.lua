-- luacheck:ignore 631

local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local m = extras.match
local p = extras.partial
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'mwe', dscr = 'MWE template' },
        fmta(
            [[
\documentclass{<>}
\begin{document}
    <>
\end{document}
]],
            {
                i(1, 'article'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'art', dscr = 'Article template' },
        fmta(
            [[
\documentclass[a4paper,twoside,10pt,leqno]{article}

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
\usepackage[T1]{fontenc}         % Better output when a diacritic/accent is used
\usepackage[utf8]{inputenc}      % Allows to input accented characters
\usepackage{textcomp}            % Avoid conflicts with siunitx and microtype
\usepackage{microtype}           % Improves justification and typography
\usepackage[svgnames]{xcolor}    % Svgnames option loads navy (blue) colour

%---------------------------------------------+
% Page style: titles, margins, footnotes, etc |
%---------------------------------------------+
% A4 page layout:
\usepackage[width=14cm,left=3.5cm,marginparwidth=3cm,marginparsep=0.35cm,
height=21cm,top=3.7cm,headsep=1cm, headheight=1.6cm,footskip=1.2cm]{geometry}

\usepackage[pagestyles,outermarks]{titlesec}  % Customize titles and headers
\newpagestyle{<pagestyle>}{%
  \sethead
  [<head_left>][<head_center>][]
  {}{\MakeUppercase{<foot_center>}}{<foot_right>}
  <footer>}
\pagestyle{<>}

\usepackage{emptypage}          % Empty blank pages created by \cleardoublepage

\usepackage[stable,multiple]{footmisc}  % Customizations of footnotes
\DefineFNsymbols*{mysymbols}[math]{\dagger\ddagger\S\diamondsuit*}
\setfnsymbol{mysymbols}  % These are used with the \thanks command
\renewcommand*{\footnoterule}{\vspace*{0.3cm}\hrule width 2.5cm\vspace*{0.3cm}}
\makeatletter
	\renewcommand\@makefntext[1]{
		\setlength{\parindent}{15pt}\mbox{\@thefnmark.\space}{#1}}
\makeatother

%-------------------------------+
% Math symbols and environments |
%-------------------------------+
\usepackage{amsmath}               % Load new math environments
\numberwithin{equation}{section}
\usepackage{amssymb}               % Defines most math symbols (such as \mathbb)
\usepackage{mathtools}             % Extension and bug fixes for amsmath package
\usepackage{mathrsfs}              % Math script like font
\usepackage{breqn}                 % Automatic line breaking of math expressions
\renewcommand*{\intlimits}{\displaylimits}  % Fix breqn clash with intlimits

%---------------------+
% Floats and captions |
%---------------------+
\graphicspath{{/home/pedro/OneDrive/programming/Latex/logos/}{figures/}{tables/}}

\usepackage[font=small,labelfont=bf]{caption}
\captionsetup*[figure]{format=plain,justification=centerlast,labelsep=quad}
\captionsetup*[table]{justification=centering,labelsep=newline}
\numberwithin{figure}{section}
\numberwithin{table}{section}

% Use subcaption for subfigures (to work properly with hyperref)
\usepackage{subcaption}
\captionsetup*[subfigure]{subrefformat=simple,labelformat=simple}
\renewcommand*{\thesubfigure}{(\alph{subfigure})}

% Further modifications of float layout
\usepackage[captionskip=5pt]{floatrow}  % We set caption skip here
\floatsetup[table]{style=Plaintop,font=small,footnoterule=none,footskip=2.5pt}

% \usepackage{longtable}        % Allows to break tables through pages
% \floatsetup[longtable]{margins=centering,LTcapwidth=table}

%---------------------------------------------------------+
% Miscellaneous packages: lists, setspace, todonotes, etc |
%---------------------------------------------------------+
\usepackage[shortlabels,inline]{enumitem}   % Customize lists
\setlist[itemize,1]{label=$\bullet$}
\setlist[itemize,2]{label=\footnotesize{$\blacktriangleright$}}
\setlist[itemize,3]{label=\tiny{$\blacksquare$}}
\setlist[itemize,4]{label=\bfseries{\large{--}}}
% \setlist[enumerate,2]{label=\emph{\alph*})}
\newlist{steps}{enumerate}{1}               % List of steps to be used in proofs
\setlist[steps,1]{leftmargin=*,label=\textit{<step> \arabic*.},ref=\arabic*}

\usepackage{setspace}  % Commands for double and one and a half spacing
% \setstretch{1.2}       % 1.2 spacing

% \usepackage{listings}  % Useful for inserting code (no unicode support)
% \lstset{basicstyle=\small\ttfamily}

% Code insertion (note: requires pygment python library and shell pdflatex flag)
% \usepackage{minted}
% \setminted{style=default, autogobble}
% \SetupFloatingEnvironment{listing}{name=`!p snip.rv= 'Código' if t[1] == 'spanish' else 'Code'`}
% \numberwithin{listing}{section}

\usepackage[<package_lang>colorinlistoftodos,textsize=small,figheight=5cm,
figwidth=10cm,color=red!85]{todonotes}

% \usepackage{lipsum}    % Dummy text generator

%-------------------------+
% References and appendix |
%-------------------------+
\usepackage[style=american]{csquotes}  % Language sensitive quotation facilities
\usepackage[style=authoryear-comp,backref=true,backend=biber]{biblatex}
\usepackage{mybibformat} % Modifications to authoryear-comp style and hyperlinks
% \addbibresource{<base_bib>.bib}

% Set appendix heading as unnumbered section (use subsections afterwards)
\newcommand*{\appheading}[1][<appendix>]{%
  \setcounter{secnumdepth}{0}\section{#1}\setcounter{secnumdepth}{3}%
  \renewcommand*{\thesubsection}{\Alph{subsection}}
  \numberwithin{equation}{subsection}
  \numberwithin{theorem}{subsection}
  \numberwithin{figure}{subsection}
  \numberwithin{table}{subsection}
}

%------------------------------------------------------+
% Hyperlinks, bookmarks, theorems and cross-references |
%------------------------------------------------------+
\usepackage[hyperfootnotes=false]{hyperref}
\hypersetup{colorlinks=true, allcolors=Navy, pdfstartview={XYZ null null 1},
pdfcreator={Vim LaTeX}, pdfsubject={},
pdftitle={<title>},
pdfauthor={<author>},
pdfkeywords={}
}
\usepackage[numbered,open,openlevel=2]{bookmark}

\usepackage{amsthm}        % We load theorem environments here to avoid warnings

\usepackage[<package_lang>noabbrev,capitalise]{cleveref}

%------------------------------------+
% Definition of theorem environments |
%------------------------------------+
% Declare theorem styles that remove final dot and use bold font for notes
\newtheoremstyle{plaindotless}{\topsep}{\topsep}{\itshape}{0pt}{\bfseries}{}%
{5pt plus 1pt minus 1pt}{\thmname{#1}\thmnumber{ #2}\bfseries{\thmnote{ (#3)}}}
\newtheoremstyle{definitiondotless}{\topsep}{\topsep}{\normalfont}{0pt}%
{\bfseries}{}{5pt plus 1pt minus 1pt}%
{\thmname{#1}\thmnumber{ #2}\bfseries{\thmnote{ (#3)}}}
\newtheoremstyle{remarkdotless}{0.5\topsep}{0.5\topsep}{\normalfont}{0pt}%
{\itshape}{}{5pt plus 1pt minus 1pt}%
{\thmname{#1}\normalfont\thmnumber{ #2}\itshape{\thmnote{ (#3)}}}

% Define style dependent environments and number them consecutively per section
\theoremstyle{plaindotless}
\newtheorem{theorem}{<theorem>}[section]
\newtheorem*{theorem*}{<theorem>.}
\newtheorem{proposition}[theorem]{<proposition>}
\newtheorem*{proposition*}{<proposition>.}
\newtheorem{lemma}[theorem]{<lemma>}
\newtheorem*{lemma*}{<lemma>.}
\newtheorem{corollary}[theorem]{<corollary>}
\newtheorem*{corollary*}{<corollary>.}

\theoremstyle{definitiondotless}
\newtheorem{definition}[theorem]{<definition>}
\newtheorem*{definition*}{<definition>.}
\newtheorem{examplex}[theorem]{<example>}
\newtheorem*{examplestarred}{<example>.}
\newtheorem*{continuedex}{<example_cont>.}
\newtheorem{exercise}[theorem]{<exercise>}
\newtheorem*{exercise*}{<exercise>.}
\newtheorem*{solution*}{<solution>.}

\theoremstyle{remarkdotless}
\newtheorem{remark}[theorem]{<remark>}
\newtheorem*{remark*}{<remark>.}
\newtheorem*{notation*}{<notation>.}

% Define numbered, unnumbered and continued examples with triangle end mark
\newcommand{\myqedsymbol}{\ensuremath{\triangle}}

\newenvironment{example}
  {\pushQED{\qed} \renewcommand{\qedsymbol}{\myqedsymbol}\examplex}
  {\popQED\endexamplex}

\newenvironment{example*}
  {\pushQED{\qed}\renewcommand{\qedsymbol}{\myqedsymbol}\examplestarred}
  {\popQED\endexamplestarred}

\newenvironment{examcont}[1]
  {\pushQED{\qed}\renewcommand{\qedsymbol}{\myqedsymbol}%
    \newcommand{\continuedexref}{\ref*{#1}}\continuedex}
  {\popQED\endcontinuedex}

%-----------------------------------------------+
% Cross-references settings (cleveref settings) |
%-----------------------------------------------+<cref_spanish>
\crefname{exercise}{<cref_exercise>}
\crefname{stepsi}{<cref_steps>}

\crefname{equation}{}{}
\crefformat{equation}{#2(#1)#3}
\crefrangeformat{equation}{#3(#1)#4 <lang_to> #5(#2)#6}
\crefmultiformat{equation}{#2(#1)#3}{ <lang_and> #2(#1)#3}{, #2(#1)#3}{ <lang_and> #2(#1)#3}
\crefrangemultiformat{equation}{#3(#1)#4 <lang_to> #5(#2)#6}{ <lang_and> #3(#1)#4 <lang_to> #5(#2)#6}%
{, #3(#1)#4 <lang_to> #5(#2)#6}{ <lang_and> #3(#1)#4 <lang_to> #5(#2)#6}
<>
%-----------------------------+
% Title and abstract settings |
%-----------------------------+
% Patch maketitle to change font and shape size
\makeatletter
\patchcmd{\@maketitle}{\LARGE}{\huge\bfseries}{}{}     % Title
\patchcmd{\@maketitle}{\vskip1.5em}{\vskip1.65em}{}{}  % Separation
\patchcmd{\@maketitle}{\large\lineskip}{\Large\scshape\lineskip}{}{}  % Authors
\makeatother

\title{<title>}
\author{<author>}
\date{<date>}
<abstract_spa>
% Don't indent abstract first line
\patchcmd{\abstract}{\quotation}{\quotation\noindent\ignorespaces}{}{}

% Keywords and JEL Classification commands:
\newcommand*{\keywords}[1]{\par\noindent\textbf{<keywords>}: \textit{#1}}
\newcommand*{\jel}[1]{\par\noindent\textbf{<jel>}: \textit{#1}}

%-------------------+
% Table of contents |
%-------------------+
%\addto\captionsspanish{\renewcommand*{\contentsname}{}}

% Add bookmark for table of contents and increase spacing of items
\preto{\tableofcontents}{\pdfbookmark[0]{\contentsname}{toc}%
  \setstretch{1.1}}
\appto{\tableofcontents}{\singlespacing}
% \appto{\tableofcontents}{\setstretch{1.1}}

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

\maketitle
<abstract_trigger>
\tableofcontents

<>

% \printbibliography[heading=bibarticle]

\end{document}
            ]],
            {
                embedfile = p(vim.fn.expand, '%:t'),
                second_lang = m(1, '^spanish$', 'english', 'spanish'),
                c(1, { t('spanish'), t('english') }),
                babel_opts = m(
                    1,
                    '^spanish$',
                    [[,es-noindentfirst,es-nosectiondot,es-nolists,
es-noshorthands,es-lcroman,es-tabla]]
                ),
                c(2, { t('mutt'), t('other') }),
                pagestyle = rep(2),
                head_left = m(2, '^mutt$', '', '\\thepage'),
                head_center = m(
                    2,
                    '^mutt$',
                    '\\includegraphics[height=1.45cm]{logo_mutt.png}',
                    '\\MakeUppercase{}'
                ),
                foot_center = i(3, 'Short Article Title'),
                foot_right = m(2, '^mutt$', '', '\\thepage'),
                footer = m(
                    2,
                    '^mutt$',
                    [[
  \setfoot
  {}{\thepage}{}
  ]],
                    ''
                ),
                step = m(1, '^spanish$', 'Paso', 'Step'),
                package_lang = m(1, '^spanish$', 'spanish,', ''),
                base_bib = p(vim.fn.expand, '%:t:r'),
                appendix = m(1, '^spanish$', 'Apéndice', 'Appendix'),
                theorem = m(1, '^spanish$', 'Teorema', 'Theorem'),
                proposition = m(1, '^spanish$', 'Proposición', 'Proposition'),
                lemma = m(1, '^spanish$', 'Lema', 'Lemma'),
                corollary = m(1, '^spanish$', 'Corolario', 'Corollary'),
                definition = m(1, '^spanish$', 'Definición', 'Definition'),
                example = m(1, '^spanish$', 'Ejemplo', 'Example'),
                example_cont = m(
                    1,
                    '^spanish$',
                    'Continuación del Ejemplo \\continuedexref',
                    'Example \\continuedexref\\space Continued.'
                ),
                exercise = m(1, '^spanish$', 'Ejercicio', 'Exercise'),
                solution = m(1, '^spanish$', 'Solución', 'Solution'),
                remark = m(1, '^spanish$', 'Observación', 'Remark'),
                notation = m(1, '^spanish$', 'Notación', 'Notation'),
                cref_spanish = m(
                    1,
                    '^spanish$',
                    [[

\crefname{section}{Sección}{Secciones}
\crefname{table}{Tabla}{Tablas}
\crefname{enumi}{Inciso}{Incisos}]],
                    ''
                ),
                cref_exercise = m(
                    1,
                    '^spanish$',
                    'Ejercicio}{Ejercicios',
                    'Exercise}{Exercises'
                ),
                cref_steps = m(1, '^spanish$', 'Paso}{Pasos', 'Step}{Steps'),
                lang_to = m(1, '^spanish$', 'a', 'to'),
                lang_and = m(1, '^spanish$', 'y', 'and'),
                c(4, {
                    sn(nil, {
                        t({
                            '',
                            [[%------------------------+]],
                            [[% Solutions to exercises |]],
                            [[%------------------------+]],
                            [[\setlist[enumerate,1]{wide = 0pt}  % Use wild lists]],
                            [[% \renewcommand*{\labelenumi}{\textbf{]],
                        }),
                        rep(1),
                        t({
                            [[ \arabic{enumi}.}}]],
                            '',
                            [[% Number equations, figures and tables following the first enumerate counter]],
                            [[% (ensuring that hyperlinks work properly)]],
                            [[\numberwithin{equation}{enumi}]],
                            [[\renewcommand{\theHequation}{\arabic{enumi}.\arabic{equation}}]],
                            [[\numberwithin{figure}{enumi}]],
                            [[\renewcommand\theHfigure{\arabic{enumi}.\arabic{figure}}]],
                            [[\numberwithin{table}{enumi}]],
                            [[\renewcommand\theHtable{\arabic{enumi}.\arabic{table}}]],
                            '',
                            [[% Don't number section environments (but create bookmarks for them) and create]],
                            [[% bookmark for each exercise]],
                            [[\setcounter{secnumdepth}{0}]],
                            [[\preto{\labelenumi}{%]],
                            [[  \pdfbookmark[2]{]],
                        }),
                        i(1, 'Ejercicio'),
                        t({
                            [[ \arabic{enumi}}{ejer\arabic{enumi}}}]],
                            [[  \preto{\labelenumii}{%]],
                            [[  \pdfbookmark[3]{(\theenumii)}{\theenumi\theenumii}}]],
                            '',
                            [[% Each item is an exercise (potentially with points)]],
                            [[\crefname{enumi}{]],
                        }),
                        rep(1),
                        t('}{'),
                        rep(1),
                        t('s}'),
                        t({ '', [[\newcommand*{\points}[1]{[#1 \textsc{]] }),
                        i(2, 'puntos'),
                        t({
                            '}]}',
                            '',
                            [[% To avoid printing solutions uncomment the following two lines]],
                            [[% \usepackage{environ}]],
                            [[% \RenewEnviron{solution*}{}]],
                        }),
                    }),
                    t(''),
                }),
                title = i(5, 'title'),
                author = i(6, 'author'),
                date = m(1, '^spanish$', '\\Today', '\\today'),
                abstract_spa = m(
                    1,
                    '^spanish$',
                    [[

\addto\captionsspanish{\renewcommand*{\abstractname}{Abstract}}]],
                    ''
                ),
                keywords = m(1, '^spanish$', 'Palabras Clave', 'Keywords'),
                jel = m(1, '^spanish$', 'Clasificación JEL', 'JEL Classification'),
                abstract_trigger = i(7, 'type abs and press <C-s> for abstract'),
                i(8),
            }
        ),
        { condition = line_begin }
    ),
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
{\includegraphics[scale=0.01]{<logo_fn>}};
%\draw[<color>] ([yshift=-0.65cm, xshift=0.25cm]current page.north west)
	% -- ([yshift=-0.65cm, xshift=\paperwidth - 0.25cm]current page.north west);
\end{tikzpicture}}

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
pdftitle={<title>},
pdfauthor={<author>},
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
                embedfile = p(vim.fn.expand, '%:t'),
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
                -- Note: choice nodes requiere a jump-index i.e we cannot use a variable
                -- we define it here instead
                color = rep(2),
                rgb_other = m(2, '^mutt$', '29,66,129', '136,151,164'),
                base_bib = p(vim.fn.expand, '%:t:r'),
                heading = i(3, 'heading'),
                title = i(4, 'title'),
                subtitle = i(5, 'subtitle'),
                institute = i(6, 'institution'),
                author = i(7, 'authors'),
                date = m(1, '^spanish$', '\\Today', '\\today'),
                logo_fn = i(8, 'logo_mutt.png'),
                i(9),
            }
        ),
        { condition = line_begin }
    ),

    s(
        { trig = 'sat', dscr = 'Standalone table' },
        fmta(
            [[
\documentclass{standalone}

%-----------------------+
% Clean auxiliary files |
%-----------------------+
% arara: clean: {files: [<base_fn>.aux, <base_fn>.log, <base_fn>.synctex.gz]}

%------------------------------------+
% Language, hyphenation and encoding |
%------------------------------------+
\usepackage{lmodern}                      % Use Latin Modern fonts
<>\renewcommand{\rmdefault}{\sfdefault}   % Use beamer sans-serif font family
\usepackage[T1]{fontenc}        % Better output when a diacritic/accent is used
\usepackage[utf8]{inputenc}               % Allows to input accented characters

%----------------+
% Table packages |
%----------------+
\usepackage{array}          % Flexible column formatting
% \usepackage{spreadtab}  % Spreadsheet features
\usepackage{multirow}       % Allows table cells that span more than one row
\usepackage{booktabs}       % Enhance quality of tables
\setlength{\heavyrulewidth}{1pt}

\usepackage{siunitx}        % Typeset units correctly and define new column (S)
\sisetup{detect-all,table-auto-round,input-symbols = {()}}
% \robustify{\bfseries}     % Correct alignment of bold numbers in tables

% Table colors
\usepackage[table,x11names]{xcolor}

\begin{document}
\begin{tabular}{<>}
    \toprule
    <>
    \midrule
    <>
    \bottomrule
\end{tabular}
\end{document}
]],
            {
                base_fn = p(vim.fn.expand, '%:t:r'),
                c(1, { sn(nil, { i(1, '%') }), t('') }),
                i(2, 'S'),
                d(3, function(args)
                    local nodes = {}
                    local nr_cols = string.len(args[1][1]) - 1
                    local idx = 0
                    for j = 1, nr_cols do
                        idx = idx + 1
                        table.insert(nodes, i(j))
                        table.insert(nodes, t(' & '))
                    end
                    idx = idx + 1
                    table.insert(nodes, i(idx))
                    table.insert(nodes, t(' \\\\'))
                    return sn(nil, nodes)
                end, { 2 }),
                i(4, 'rxc'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'saf', dscr = 'Standalone figure' },
        fmta(
            [[
\documentclass{standalone}

%-----------------------+
% Clean auxiliary files |
%-----------------------+
% arara: clean: {files: [<base_fn>.aux, <base_fn>.log, <base_fn>.synctex.gz]}

%----------------------------------------------+
% Font, hyphenation, encoding and math symbols |
%----------------------------------------------+
\usepackage{lmodern}
% \renewcommand{\rmdefault}{\sfdefault}   % Use beamer sans-serif font family
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{amssymb}
\usepackage[eulergreek]{sansmath}

%--------+
% Graphs |
%--------+
\usepackage{pgfplots}
\pgfplotsset{compat=newest,
standard/.style={
    axis lines=middle, axis line style={-,big arrow},
    every axis x label/.style={at={(current axis.right of origin)}, anchor=
    north east, xshift=1.2mm, yshift=-0.2mm},
    every axis y label/.style={at={(current axis.above origin)}, anchor=east,
    yshift=-0.7mm},
    every tick/.style={color=black, line width=0.35pt}
}
}

\usetikzlibrary{arrows,intersections,calc,decorations.pathreplacing,
decorations.markings}
\tikzset{
big arrow/.style={
    decoration={markings,mark=at position 1 with {\arrow[scale=2.4]{latex'}}},
    postaction={decorate,draw}},
bold/.style={line width=1pt},
fopaque/.style={fill=gray, fill opacity=0.25},
every picture/.style={line width=0.5pt},
every node/.style={font=\small},
every pin/.style={font=\footnotesize},
every pin edge/.style={<<-,>>=stealth'}
}

\begin{document}
\begin{tikzpicture}
    <>
\end{tikzpicture}
\end{document}
]],
            {
                base_fn = p(vim.fn.expand, '%:t:r'),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cm', dscr = 'Choice multi' },
        fmta(
            [[
                <>
            ]],
            {
                c(1, { sn(nil, { t('foo\bar'), t('bar') }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
}, {}
