" Original Maintainer:	Alan Isaac <aisaac@american.edu>

" Quit when a syntax file was already loaded
if exists('b:current_syntax')
	finish
endif

syn keyword gaussStatement	call fn proc local return stop
syn keyword gaussConditional      if then else endif elseif break continue goto
syn keyword gaussRepeat           while until for do endo endfor endp

syn keyword gaussTodo			contained  TODO NOTE FIXME XXX

syn keyword gaussLogicalOperator         and or not .and .or .not AND OR NOT .AND .OR .NOT
syn match gaussOperator	"[-+/*]"
syn match gaussOperator    "[|!<>^~:=.%?$]"
syn match gaussTransposeOperator	"[])a-zA-Z0-9.]'"lc=1
syn match gaussSemicolon		";"

syn match gaussNumber		"\<\d\+[ij]\=\>"
syn match gaussFloat		"\<\d\+\(\.\d*\)\=\([edED][-+]\=\d\+\)\=[ij]\=\>"
syn match gaussFloat		"\.\d\+\([edED][-+]\=\d\+\)\=[ij]\=\>"
syn region gaussString			start=+"+ end=+"+	oneline

syn region gaussSlashComment start="\s//"   end=/$/    contains=gaussComment oneline
syn region gaussSlashComment start="^//"    end=/$/    contains=gaussComment oneline
syn region gaussBlockComment      start="/\*"    end="\*/"  contains=gaussComment
syn match gaussAltComment			"@.*$"
" FIXME: Account for block comments with @
" syn region gaussAltBlockComment      start="/@"    end="@$/"

syn region gaussRegion matchgroup=Delimiter start=/(/ matchgroup=Delimiter end=/)/ transparent contains=ALLBUT,gaussError,gaussBraceError,gaussCurlyError
syn region gaussRegion matchgroup=Delimiter start=/{/ matchgroup=Delimiter end=/}/ transparent contains=ALLBUT,gaussError,gaussBraceError,gaussParenError
syn region gaussRegion matchgroup=Delimiter start=/\[/ matchgroup=Delimiter end=/]/ transparent contains=ALLBUT,gaussError,gaussCurlyError,gaussParenError
syn match gaussError      "[)\]}]"
syn match gaussBraceError "[)}]" contained
syn match gaussCurlyError "[)\]]" contained
syn match gaussParenError "[\]}]" contained

syn match gaussPreProc	"#\S\+"

syn keyword gaussStatement _daypryr _dstatd _dstatx _isleap
syn keyword gaussStatement dlibrary library new cls graphset format rndseed let
syn keyword gaussStatement begwind nextwind endwind trap local

syn keyword gaussFunc abs arccos arcsin arctan arctan2 asclabel atan atan2 axmargin
syn keyword gaussFunc balance band bandchol bandcholsol bandltsol bandrv bandsolpd bar base10 besselj bessely box
syn keyword gaussFunc call cdfbeta cdfbvn cdfbvn2 cdfbvn2e cdfchic cdfchii cdfchinc cdffc cdffnc cdfgam cdfmvn cdfn cdfn2 cdfnc cdfni cdftc cdftci cdftnc cdftvn cdir ceil cfft cffti ChangeDir chdir chol choldn cholsol cholup chrs cint clear clearg close closeall cmadd cmcplx cmcplx2 cmdiv cmemult cmimag cminv cmmult cmreal cmsoln cmsub cmtrans code color cols colsf comlog compile complex con cond conj cons contour conv coreleft corrm corrvc corrx cos cosh counts countwts create crossprd crout croutp csrcol csrlin csrtype cumprodc cumsumc
syn keyword gaussFunc datalist date datestr datestring datestrymd dayinyr debug declare delete delif denseSubmat design det detl dfft dffti dfree diag diagrv disable dllcall dos doswin DOSWinCloseall DOSWinOpen draw dstat dummy dummybr dummydn
syn keyword gaussFunc ed edit editm eig eigcg eigcg2 eigch eigch2 eigh eighv eigrg eigrg2 eigrs eigrs2 eigv enable end envget eof eqSolve erf erfc error errorlog etdays ethsec etstr exctsmpl exec exp export exportf external eye
syn keyword gaussFunc fcheckerr fclearerr feq fflush fft ffti fftm fftmi fftn fge fgets fgetsa fgetsat fgetst fgt fileinfo files filesa fix fle floor flt fmod fne fonts fopen for formatcv formatnv fputs fputst fseek fstrerror ftell ftocv ftos syn keyword gaussFunc gamma gammaii gausset getf getname getnr getpath getwind gosub gradp graph graphprt
syn keyword gaussFunc hardcopy hasimag header hess hessp hist histf histp hsec
syn keyword gaussFunc imag import importf indcv indexcat indices indices2 indnv int intgrat2 intgrat3 intquad1 intquad2 intquad3 intrleav intrsect intsimp inv invpd invswp iscplx iscplxf ismiss isSparse syn keyword gaussFunc key keyw keyword
syn keyword gaussFunc lag1 lagn lib line ln lncdfbvn lncdfbvn2 lncdfmvn lncdfn lncdfn2 lncdfnc lnfact lnpdfmvn lnpdfn load loadd loadf loadk loadm loadp loads loadwind locate loess log loglog logx logy lower lowmat lowmat1 lpos lprint lpwidth lshow ltrisol lu lusol
syn keyword gaussFunc makevars makewind margin maxc maxindc maxvec mbesselei mbesselei0 mbesselei1 mbesseli mbesseli0 mbesseli1 meanc median mergeby mergevar minc minindc miss missex missrv moment momentd msym
syn keyword gaussFunc nametype ndpchk ndpclex ndpcntrl nextn nextnevn null null1
syn keyword gaussFunc ols olsqr olsqr2 ones open optn optnevn orth output outwidth
syn keyword gaussFunc packr parse pause pdfn pi pinv plot plotsym polar polychar polyeval polyint polymake polymat polymult polyroot pop pqgwin prcsn print printdos printfm printfmt prodc putf
syn keyword gaussFunc QProg qqr qqre qqrep qr qre qrep qrsol qrtsol qtyr qtyre qtyrep quantile quantiled qyr qyre qyrep
syn keyword gaussFunc rank rankindx readr real recode recserar recsercp recserrc replay rerun reshape retp rev rfft rffti rfftip rfftn rfftnp rfftp rndbeta rndcon rndgam rndmod rndmult rndn rndnb rndns rndp rndu rndus rndvm rotater round rows rowsf rref run
syn keyword gaussFunc save saveall saved savewind scale scale3d scalerr scalmiss schtoc schur screen scroll seekr selif seqa seqm setcnvrt setdif setvars setvmode setwind shell shiftr show sin sinh sleep solpd sortc sortcc sortd sorthc sorthcc sortind sortindc sortmc sparseCols sparseEye sparseFD sparseFP sparseHConcat sparseNZE sparseOnes sparseRows sparseSolve sparseSubmat sparseTD sparseTrTD sparseVConcat spline1D spline2D sqpSolve sqrt stdc stof strindx strlen strput strrindx strsect submat subscat substute sumc surface svd svd1 svd2 svdcusv svds svdusv sysstate system
syn keyword gaussFunc tab tan tanh tempname time timestr title toeplitz token trace trapchk trim trimr trunc type typecv typef
syn keyword gaussFunc union uniqindx unique upmat upmat1 upper use utrisol
syn keyword gaussFunc vals varget vargetl varput varputl vartype vcm vcx vec vech vecr vget view viewxyz vlist vnamecv volume vput vread vtypecv
syn keyword gaussFunc wait waitc window writer
syn keyword gaussFunc xlabel xpnd xtics xy xyz
syn keyword gaussFunc ylabel ytics
syn keyword gaussFunc zeros zlabel ztics
syn keyword gaussFunc co coset coprt gradre gradfd gradcd cml cmlset cmlprt cmlclprt cmltlimits cmlhist cmldensity cmlboot cmlblimits cmlclimits cmlprofile cmlbayes cmlpflclimits


if !exists('did_gauss_syntax_inits')
    hi def link gaussConditional       Conditional
    hi def link gaussRepeat            Repeat
    hi def link gaussTodo            Todo
	hi def link gaussTransposeOperator	Operator
    hi def link gaussLogicalOperator          Operator
    hi def link gaussOperator          Operator
    hi def link gaussNumber            Number
    hi def link gaussFloat     Float
    hi def link gaussString           String
    hi def link gaussSlashComment	Comment
    hi def link gaussBlockComment	Comment
    hi def link gaussAltComment	Comment
    hi def link gaussAltBlockComment	Comment
    hi def link gaussStatement         Statement
    hi def link gaussSemicolon		SpecialChar
    hi def link gaussError       Error
    hi def link gaussCurlyError  Error
    hi def link gaussBraceError  Error
    hi def link gaussParenError  Error
    hi def link gaussPreProc         PreProc
    hi def link gaussFunc         Function
    " hi def link GAUkType              Type
    " hi def link GAUBoolean           Boolean
    " hi def link CommentStart          Special
endif

let b:current_syntax = 'gauss'

" vim: ts=8 sw=2
