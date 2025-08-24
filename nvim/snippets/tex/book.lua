-- luacheck:ignore 631
local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
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
        { trig = 'bmf', dscr = 'Book main file' },
        fmta(
            [[
\documentclass[a4paper,10pt,leqno]{book}

\input{preamble.tex}

% \includeonly{}

\begin{document}

\frontmatter
	\halftitlepg
	\titlepg
	\copyrightpg
	\dedicationpg
	\tableofcontents<>

\mainmatter
	\include{<>}

\backmatter
	% \printbibheading[heading=bibbook]
	% \bibbysection[heading=subbib]
	% \printindex

\end{document}
            ]],
            {
                c(1, {
                    sn(nil, { t({ '', '  \\include{' }), i(1, 'preface'), t('}') }),
                    t(''),
                }),
                i(2, 'chapter1'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'bp', dscr = 'Book preamble' },
        fmta(
            [[
%---------------------------------------+
% Source code, programming and patching |
%---------------------------------------+
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
\newpagestyle{main}[\scshape]{%
	\headrule
	\sethead
	[\thepage][][\chaptertitlename\space\thechapter. \chaptertitle]
	{\ifthesection{\thesection\space\,\sectiontitle}
	{\chaptertitlename\space\thechapter. \chaptertitle}}{}{\thepage}
}
\newpagestyle{special}[\scshape]{%
	\headrule
	\sethead
	[\thepage][][\chaptertitle]
	{\ifthesection{\sectiontitle}{\chaptertitle}}{}{\thepage}
}
% The following pagestyle is needed because titlesec isn't compatible with
% refsegment=chapter
\newpagestyle{bibatend}[\scshape]{
	\headrule
	\sethead
	[\thepage][][\chaptertitle]
	{\sectiontitle}{}{\thepage}
}
\pagestyle{special}
\appto{\mainmatter}{\pagestyle{main}}
\appto{\backmatter}{\pagestyle{bibatend}}
\appto{\printindex}{\pagestyle{special}}

% Use empty page style instead of plain in parts and chapters title pages
\patchcmd{\part}{plain}{empty}{}{}
\patchcmd{\chapter}{plain}{empty}{}{}

\usepackage{emptypage}  % Empty blank pages created by \cleardoublepage

% Change chapter heading style to match titlepage
\titleformat{\chapter}[display]
{\bfseries\filcenter}
{\titlerule[1.5pt]\vspace{4ex}%
\LARGE{\chaptertitlename\space\thechapter}}{0.5cm}{\huge}
[\vspace{2ex}{\titlerule[1.5pt]}\vspace{0.3cm}]
% Do the same for unnumbered chapters (TOC, preface, etc)
\titleformat{name=\chapter,numberless}[display]
{\bfseries\filcenter}
{\titlerule[1.5pt]\vspace{0ex}}{0.5cm}{\huge}
[\vspace{2ex}{\titlerule[1.5pt]}\vspace{0.3cm}]

\usepackage[stable,multiple]{footmisc}  % Customizations of footnotes
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
% \usepackage[newfloat]{minted}
% \setminted{style=default, autogobble}
% \SetupFloatingEnvironment{listing}{name=<code>}
% \numberwithin{listing}{section}

\usepackage[<package_lang>colorinlistoftodos,textsize=small,figheight=5cm,
figwidth=10cm,color=red!85]{todonotes}

% \usepackage{lipsum}    % Dummy text generator

%----------------------------------+
% Appendix, bibliography and index |
%----------------------------------+
% Solve bad interaction between titlesec and \appendix
\preto{\appendix}{\cleardoublepage}

\usepackage[style=american]{csquotes}  % Language sensitive quotation facilities
\usepackage[style=authoryear-comp,backref=true,refsection=chapter,
backend=biber]{biblatex}
\usepackage{mybibformat} % Modifications to authoryear-comp style and hyperlinks
% \addbibresource{<base_bib>.bib}

\usepackage{imakeidx}  % Creation and formatting of indexes
\indexsetup{level=\chapter,firstpagestyle=empty,othercode=\small}
\makeindex[title=<index>]

%------------------------------------------------------+
% Hyperlinks, bookmarks, theorems and cross-references |
%------------------------------------------------------+
\usepackage[hyperfootnotes=false]{hyperref}
\hypersetup{colorlinks=true, allcolors=Navy, pdfstartview={XYZ null null 1},
pdfcreator={Vim LaTeX}, pdfsubject={},
pdftitle={<pdftitle>},
pdfauthor={<pdfauthor>},
pdfkeywords={}
}
\usepackage[numbered,open,openlevel=1]{bookmark}

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

%----------------------------------------------+
% Half-title, titlepage and copyright settings |
%----------------------------------------------+
\newcommand*{\halftitlepg}{%
	\begingroup
		\begin{center}
			\bfseries{\huge{<half_title>}}
		\end{center}
	\endgroup
	\thispagestyle{empty}\cleardoublepage
}

\newcommand*{\titlepg}{%
  \begingroup
    \begin{center}
      \includegraphics[scale=0.03]{<logo_fn>}
    \end{center}
	\vspace{0.01\textheight}
	\begin{center}
	  \bfseries{\LARGE{<institution>}}\\
	  \vspace{0.02\textheight}
	  \bfseries{\Large{<department>}}\\
	  \vspace{0.2\textheight}
	  \rule{\textwidth}{1.5pt}\par
	  \vspace{\baselineskip}
	  \bfseries{\Huge{<title>}}\par
	  \bigskip\Large{--- <subtitle> ---}
	  \vspace{\baselineskip}
	  \rule{\textwidth}{1.5pt}\par
      \vfill
      \normalfont{\scshape{\huge{<author>}}}
      \vfill
	  \textbf{\Large{<date>}}
	 \end{center}
	\endgroup
	\thispagestyle{empty}\clearpage
}

\newcommand*{\copyrightpg}{%
  \begingroup
    \footnotesize
    \parindent 0pt
    \null
    \vfill
    \textcopyright{} <year> <author_license>. <rights>.\par
    \vspace{\baselineskip}
    <license>.\par
    \vspace{\baselineskip}
    <typing> \LaTeX.\par
  \endgroup
  \thispagestyle{empty}\clearpage
}

\newcommand*{\dedicationpg}{%
  \begingroup
    \vspace*{0.3\textheight}
    \begin{center}
      \itshape{\large{<dedication>}}
    \end{center}
  \endgroup
  \thispagestyle{empty}\cleardoublepage
}

%-------------------+
% Table of contents |
%-------------------+<toc_spa_title>
% Add bookmark for table of contents and increase spacing of items
\preto{\tableofcontents}{\cleardoublepage\pdfbookmark[0]{\contentsname}{toc}%
	\setstretch{1.1}}
\appto{\tableofcontents}{\singlespacing}

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
            ]],
            {
                second_lang = m(1, '^spanish$', 'english', 'spanish'),
                c(1, { t('spanish'), t('english') }),
                babel_opts = m(
                    1,
                    '^spanish$',
                    [[,es-noindentfirst,es-nosectiondot,es-nolists,
es-noshorthands,es-lcroman,es-tabla]]
                ),
                step = m(1, '^spanish$', 'Paso', 'Step'),
                package_lang = m(1, '^spanish$', 'spanish,', ''),
                code = m(1, '^spanish$', 'Código', 'Code'),
                base_bib = p(_G.LuaSnipConfig.filepart, 'basename_no_ext'),
                index = m(1, '^spanish$', 'Índice Alfabético', 'Alphabetical Index'),
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
                half_title = i(2, 'half title'),
                logo_fn = i(3, 'logo_mutt.png'),
                institution = i(4, 'institution'),
                department = i(5, 'department'),
                title = i(6, 'title'),
                pdftitle = rep(6),
                subtitle = i(7, 'subtitle'),
                author = i(8, 'author'),
                author_license = rep(8),
                pdfauthor = rep(8),
                date = i(9, 'date'),
                year = p(os.date, '%Y'),
                rights = m(
                    1,
                    '^spanish$',
                    [[Todos los derechos reservados]],
                    [[All rights reserved]]
                ),
                license = m(
                    1,
                    '^spanish$',
                    [[
Este documento es libre; puede ser redistribuido y/o modificado bajo los
    términos de la Licencia Pública General de GNU (GNU General Public License o
    GPL) según han sido publicados por la Free Software Foundation; según la
    versión 2 de la Licencia o (a su elección) cualquier versión posterior]],
                    [[
This document is free; you can redistribute it and/or modify it under the
    terms of the GNU General Public License as published by the Free Software
    Foundation; either version 2 of the License, or (at your choice) any later
    version]]
                ),
                typing = m(
                    1,
                    '^spanish$',
                    [[Este documento fue tipeado en letra Latin Modern usando]],
                    [[This document was typeset in Latin Modern font using]]
                ),
                toc_spa_title = m(
                    1,
                    '^spanish$',
                    [[

\addto{\captionsspanish}{\renewcommand*{\contentsname}{Índice General}}
                ]],
                    ''
                ),
                dedication = i(10, 'For me.'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pf', dscr = 'Preface' },
        fmta(
            [[
                \chapter{<>}
                \label{cha:<>}

                <>

                \begin{flushright}
                  \bigskip
                  <>\\
                  <>
                \end{flushright}
            ]],
            {
                i(1, 'chapter name'),
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(2),
                i(3, 'city'),
                i(4, 'date'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ba', dscr = 'Book appendix' },
        fmta(
            [[
                \appendix
                \chapter{<>}
                \label{cha:<>}

                <><>
            ]],
            {
                i(1, 'chapter name'),
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ind', wordTrig = false, dscr = 'Index' },
        fmta(
            [[
        \index{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
}, {}
