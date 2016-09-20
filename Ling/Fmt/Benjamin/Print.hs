{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-name-shadowing #-}
module Ling.Fmt.Benjamin.Print where

-- pretty-printer generated by the BNF converter

import Ling.Fmt.Benjamin.Abs
import Data.Char


-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)



instance Print Name where
  prt _ (Name i) = doc (showString ( i))


instance Print OpName where
  prt _ (OpName i) = doc (showString ( i))



instance Print Program where
  prt i e = case e of
    Prg decs -> prPrec i 0 (concatD [prt 0 decs])

instance Print Dec where
  prt i e = case e of
    DDef name optsig term -> prPrec i 0 (concatD [prt 0 name, prt 0 optsig, doc (showString "="), prt 0 term])
    DSig name term -> prPrec i 0 (concatD [prt 0 name, doc (showString ":"), prt 0 term])
    DDat name connames -> prPrec i 0 (concatD [doc (showString "data"), prt 0 name, doc (showString "="), prt 0 connames])
    DAsr assertion -> prPrec i 0 (concatD [doc (showString "assert"), prt 0 assertion])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print Assertion where
  prt i e = case e of
    AEq term1 term2 optsig -> prPrec i 0 (concatD [prt 0 term1, doc (showString "="), prt 0 term2, prt 0 optsig])

instance Print ConName where
  prt i e = case e of
    CN name -> prPrec i 0 (concatD [doc (showString "`"), prt 0 name])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString "|"), prt 0 xs])
instance Print OptSig where
  prt i e = case e of
    NoSig -> prPrec i 0 (concatD [])
    SoSig term -> prPrec i 0 (concatD [doc (showString ":"), prt 0 term])

instance Print VarDec where
  prt i e = case e of
    VD name optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 name, prt 0 optsig, doc (showString ")")])

instance Print ChanDec where
  prt i e = case e of
    CD name optrepl optsession -> prPrec i 0 (concatD [prt 0 name, prt 0 optrepl, prt 0 optsession])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print Branch where
  prt i e = case e of
    Br conname term -> prPrec i 0 (concatD [prt 0 conname, doc (showString "->"), prt 0 term])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print Literal where
  prt i e = case e of
    LInteger n -> prPrec i 0 (concatD [prt 0 n])
    LDouble d -> prPrec i 0 (concatD [prt 0 d])
    LString str -> prPrec i 0 (concatD [prt 0 str])
    LChar c -> prPrec i 0 (concatD [prt 0 c])

instance Print ATerm where
  prt i e = case e of
    Var name -> prPrec i 0 (concatD [prt 0 name])
    Op opname -> prPrec i 0 (concatD [prt 0 opname])
    Lit literal -> prPrec i 0 (concatD [prt 0 literal])
    Con conname -> prPrec i 0 (concatD [prt 0 conname])
    TTyp -> prPrec i 0 (concatD [doc (showString "Type")])
    TProto rsessions -> prPrec i 0 (concatD [doc (showString "<"), prt 0 rsessions, doc (showString ">")])
    Paren term optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")")])
    End -> prPrec i 0 (concatD [doc (showString "end")])
    Par rsessions -> prPrec i 0 (concatD [doc (showString "{"), prt 0 rsessions, doc (showString "}")])
    Ten rsessions -> prPrec i 0 (concatD [doc (showString "["), prt 0 rsessions, doc (showString "]")])
    Seq rsessions -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 rsessions, doc (showString ":]")])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print Term where
  prt i e = case e of
    RawApp aterm aterms -> prPrec i 3 (concatD [prt 0 aterm, prt 0 aterms])
    Case term branchs -> prPrec i 2 (concatD [doc (showString "case"), prt 0 term, doc (showString "of"), doc (showString "{"), prt 0 branchs, doc (showString "}")])
    Snd term csession -> prPrec i 2 (concatD [doc (showString "!"), prt 3 term, prt 0 csession])
    Rcv term csession -> prPrec i 2 (concatD [doc (showString "?"), prt 3 term, prt 0 csession])
    Dual term -> prPrec i 2 (concatD [doc (showString "~"), prt 2 term])
    TRecv name -> prPrec i 2 (concatD [doc (showString "<-"), prt 0 name])
    Loli term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "-o"), prt 1 term2])
    TFun term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "->"), prt 1 term2])
    TSig term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "**"), prt 1 term2])
    Let name optsig term1 term2 -> prPrec i 1 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "="), prt 0 term1, doc (showString "in"), prt 0 term2])
    Lam term1 term2 -> prPrec i 0 (concatD [doc (showString "\\"), prt 2 term1, doc (showString "->"), prt 0 term2])
    TProc chandecs proc -> prPrec i 0 (concatD [doc (showString "proc"), doc (showString "("), prt 0 chandecs, doc (showString ")"), prt 0 proc])

instance Print Proc where
  prt i e = case e of
    PAct act -> prPrec i 1 (concatD [prt 0 act])
    PPrll procs -> prPrec i 1 (concatD [doc (showString "("), prt 0 procs, doc (showString ")")])
    PRepl replkind aterm withindex proc -> prPrec i 1 (concatD [prt 0 replkind, doc (showString "^"), prt 0 aterm, prt 0 withindex, prt 1 proc])
    PNxt proc1 proc2 -> prPrec i 0 (concatD [prt 1 proc1, prt 0 proc2])
    PDot proc1 proc2 -> prPrec i 0 (concatD [prt 1 proc1, doc (showString "."), prt 0 proc2])
    PSem proc1 proc2 -> prPrec i 0 (concatD [prt 1 proc1, doc (showString ";"), prt 0 proc2])
    NewSlice chandecs aterm name proc -> prPrec i 0 (concatD [doc (showString "slice"), doc (showString "("), prt 0 chandecs, doc (showString ")"), prt 0 aterm, doc (showString "as"), prt 0 name, prt 0 proc])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString "|"), prt 0 xs])
instance Print ReplKind where
  prt i e = case e of
    ReplSeq -> prPrec i 0 (concatD [doc (showString "sequence")])
    ReplPar -> prPrec i 0 (concatD [doc (showString "parallel")])

instance Print WithIndex where
  prt i e = case e of
    NoIndex -> prPrec i 0 (concatD [])
    SoIndex name -> prPrec i 0 (concatD [doc (showString "with"), prt 0 name])

instance Print Act where
  prt i e = case e of
    Nu newalloc -> prPrec i 0 (concatD [prt 0 newalloc])
    ParSplit optsplit chandecs -> prPrec i 0 (concatD [prt 0 optsplit, doc (showString "{"), prt 0 chandecs, doc (showString "}")])
    TenSplit optsplit chandecs -> prPrec i 0 (concatD [prt 0 optsplit, doc (showString "["), prt 0 chandecs, doc (showString "]")])
    SeqSplit optsplit chandecs -> prPrec i 0 (concatD [prt 0 optsplit, doc (showString "[:"), prt 0 chandecs, doc (showString ":]")])
    Send name aterm -> prPrec i 0 (concatD [doc (showString "send"), prt 0 name, prt 0 aterm])
    NewSend name optsession aterm -> prPrec i 0 (concatD [prt 0 name, prt 0 optsession, doc (showString "<-"), prt 0 aterm])
    Recv name vardec -> prPrec i 0 (concatD [doc (showString "recv"), prt 0 name, prt 0 vardec])
    NewRecv name1 optsig name2 -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name1, prt 0 optsig, doc (showString "<-"), prt 0 name2])
    LetRecv name optsig aterm -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "<="), prt 0 aterm])
    Ax asession chandecs -> prPrec i 0 (concatD [doc (showString "fwd"), prt 0 asession, doc (showString "("), prt 0 chandecs, doc (showString ")")])
    SplitAx n asession name -> prPrec i 0 (concatD [doc (showString "fwd"), prt 0 n, prt 0 asession, prt 0 name])
    At aterm topcpatt -> prPrec i 0 (concatD [doc (showString "@"), prt 0 aterm, prt 0 topcpatt])
    LetA name optsig aterm -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "="), prt 0 aterm])

instance Print ASession where
  prt i e = case e of
    AS aterm -> prPrec i 0 (concatD [prt 0 aterm])

instance Print OptAs where
  prt i e = case e of
    NoAs -> prPrec i 0 (concatD [])
    SoAs -> prPrec i 0 (concatD [doc (showString "as")])

instance Print OptSplit where
  prt i e = case e of
    SoSplit name optas -> prPrec i 0 (concatD [doc (showString "split"), prt 0 name, prt 0 optas])
    NoSplit name -> prPrec i 0 (concatD [prt 0 name])

instance Print TopCPatt where
  prt i e = case e of
    OldTopPatt chandecs -> prPrec i 0 (concatD [doc (showString "("), prt 0 chandecs, doc (showString ")")])
    ParTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "{"), prt 0 cpatts, doc (showString "}")])
    TenTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "["), prt 0 cpatts, doc (showString "]")])
    SeqTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 cpatts, doc (showString ":]")])

instance Print CPatt where
  prt i e = case e of
    ChaPatt chandec -> prPrec i 0 (concatD [prt 0 chandec])
    ParPatt cpatts -> prPrec i 0 (concatD [doc (showString "{"), prt 0 cpatts, doc (showString "}")])
    TenPatt cpatts -> prPrec i 0 (concatD [doc (showString "["), prt 0 cpatts, doc (showString "]")])
    SeqPatt cpatts -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 cpatts, doc (showString ":]")])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print OptSession where
  prt i e = case e of
    NoSession -> prPrec i 0 (concatD [])
    SoSession rsession -> prPrec i 0 (concatD [doc (showString ":"), prt 0 rsession])

instance Print RSession where
  prt i e = case e of
    Repl term optrepl -> prPrec i 0 (concatD [prt 0 term, prt 0 optrepl])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print OptRepl where
  prt i e = case e of
    One -> prPrec i 0 (concatD [])
    Some aterm -> prPrec i 0 (concatD [doc (showString "^"), prt 0 aterm])

instance Print CSession where
  prt i e = case e of
    Cont term -> prPrec i 0 (concatD [doc (showString "."), prt 1 term])
    Done -> prPrec i 0 (concatD [])

instance Print AllocTerm where
  prt i e = case e of
    AVar name -> prPrec i 0 (concatD [prt 0 name])
    ALit literal -> prPrec i 0 (concatD [prt 0 literal])
    AParen term optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")")])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print NewSig where
  prt i e = case e of
    NoNewSig -> prPrec i 0 (concatD [])
    NewTypeSig term -> prPrec i 0 (concatD [doc (showString ":*"), prt 0 term])
    NewSessSig term -> prPrec i 0 (concatD [doc (showString ":"), prt 0 term])

instance Print NewPatt where
  prt i e = case e of
    TenNewPatt cpatts -> prPrec i 0 (concatD [doc (showString "["), prt 0 cpatts, doc (showString "]")])
    SeqNewPatt cpatts -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 cpatts, doc (showString ":]")])
    CntNewPatt name newsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 name, prt 0 newsig, doc (showString ")")])

instance Print NewAlloc where
  prt i e = case e of
    OldNew chandecs -> prPrec i 0 (concatD [doc (showString "new"), doc (showString "("), prt 0 chandecs, doc (showString ")")])
    New newpatt -> prPrec i 0 (concatD [doc (showString "new"), prt 0 newpatt])
    NewSAnn term optsig newpatt -> prPrec i 0 (concatD [doc (showString "new/"), doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")"), prt 0 newpatt])
    NewNAnn opname allocterms newpatt -> prPrec i 0 (concatD [prt 0 opname, prt 0 allocterms, prt 0 newpatt])

