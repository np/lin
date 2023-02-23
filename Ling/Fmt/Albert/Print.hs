-- File generated by the BNF Converter (bnfc 2.9.4.1).

{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
#if __GLASGOW_HASKELL__ <= 708
{-# LANGUAGE OverlappingInstances #-}
#endif

-- | Pretty-printer for Ling.

{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-name-shadowing #-}
module Ling.Fmt.Albert.Print where

import Prelude
  ( ($), (.)
  , Bool(..), (==), (<)
  , Int, Integer, Double, (+), (-), (*)
  , String, (++)
  , ShowS, showChar, showString
  , all, elem, foldr, id, map, null, replicate, shows, span
  )
import Data.Char ( Char, isSpace )
import qualified Ling.Fmt.Albert.Abs

-- | The top-level printing method.

printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 False (map ($ "") $ d []) ""
  where
  rend
    :: Int        -- ^ Indentation level.
    -> Bool       -- ^ Pending indentation to be output before next character?
    -> [String]
    -> ShowS
  rend i p = \case
      "["      :ts -> char '[' . rend i False ts
      "("      :ts -> char '(' . rend i False ts
      "{"      :ts -> onNewLine i     p . showChar   '{'  . new (i+1) ts
      "}" : ";":ts -> onNewLine (i-1) p . showString "};" . new (i-1) ts
      "}"      :ts -> onNewLine (i-1) p . showChar   '}'  . new (i-1) ts
      [";"]        -> char ';'
      ";"      :ts -> char ';' . new i ts
      t  : ts@(s:_) | closingOrPunctuation s
                   -> pending . showString t . rend i False ts
      t        :ts -> pending . space t      . rend i False ts
      []           -> id
    where
    -- Output character after pending indentation.
    char :: Char -> ShowS
    char c = pending . showChar c

    -- Output pending indentation.
    pending :: ShowS
    pending = if p then indent i else id

  -- Indentation (spaces) for given indentation level.
  indent :: Int -> ShowS
  indent i = replicateS (2*i) (showChar ' ')

  -- Continue rendering in new line with new indentation.
  new :: Int -> [String] -> ShowS
  new j ts = showChar '\n' . rend j True ts

  -- Make sure we are on a fresh line.
  onNewLine :: Int -> Bool -> ShowS
  onNewLine i p = (if p then id else showChar '\n') . indent i

  -- Separate given string from following text by a space (if needed).
  space :: String -> ShowS
  space t s =
    case (all isSpace t', null spc, null rest) of
      (True , _   , True ) -> []              -- remove trailing space
      (False, _   , True ) -> t'              -- remove trailing space
      (False, True, False) -> t' ++ ' ' : s   -- add space if none
      _                    -> t' ++ s
    where
      t'          = showString t []
      (spc, rest) = span isSpace s

  closingOrPunctuation :: String -> Bool
  closingOrPunctuation [c] = c `elem` closerOrPunct
  closingOrPunctuation _   = False

  closerOrPunct :: String
  closerOrPunct = ")],;"

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- | The printer class does the job.

class Print a where
  prt :: Int -> a -> Doc

instance {-# OVERLAPPABLE #-} Print a => Print [a] where
  prt i = concatD . map (prt i)

instance Print Char where
  prt _ c = doc (showChar '\'' . mkEsc '\'' c . showChar '\'')

instance Print String where
  prt _ = printString

printString :: String -> Doc
printString s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q = \case
  s | s == q -> showChar '\\' . showChar s
  '\\' -> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  s -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j < i then parenth else id

instance Print Integer where
  prt _ x = doc (shows x)

instance Print Double where
  prt _ x = doc (shows x)

instance Print Ling.Fmt.Albert.Abs.Name where
  prt _ (Ling.Fmt.Albert.Abs.Name i) = doc $ showString i
instance Print Ling.Fmt.Albert.Abs.OpName where
  prt _ (Ling.Fmt.Albert.Abs.OpName i) = doc $ showString i
instance Print Ling.Fmt.Albert.Abs.Program where
  prt i = \case
    Ling.Fmt.Albert.Abs.Prg decs -> prPrec i 0 (concatD [prt 0 decs])

instance Print Ling.Fmt.Albert.Abs.Dec where
  prt i = \case
    Ling.Fmt.Albert.Abs.DPrc name chandecs proc_ optdot -> prPrec i 0 (concatD [prt 0 name, doc (showString "("), prt 0 chandecs, doc (showString ")"), doc (showString "="), prt 0 proc_, prt 0 optdot])
    Ling.Fmt.Albert.Abs.DDef name optsig termproc optdot -> prPrec i 0 (concatD [prt 0 name, prt 0 optsig, doc (showString "="), prt 0 termproc, prt 0 optdot])
    Ling.Fmt.Albert.Abs.DSig name term optdot -> prPrec i 0 (concatD [prt 0 name, doc (showString ":"), prt 0 term, prt 0 optdot])
    Ling.Fmt.Albert.Abs.DDat name connames optdot -> prPrec i 0 (concatD [doc (showString "data"), prt 0 name, doc (showString "="), prt 0 connames, prt 0 optdot])
    Ling.Fmt.Albert.Abs.DAsr assertion -> prPrec i 0 (concatD [doc (showString "assert"), prt 0 assertion])

instance Print Ling.Fmt.Albert.Abs.Assertion where
  prt i = \case
    Ling.Fmt.Albert.Abs.AEq term1 term2 optsig -> prPrec i 0 (concatD [prt 0 term1, doc (showString "="), prt 0 term2, prt 0 optsig])

instance Print Ling.Fmt.Albert.Abs.ConName where
  prt i = \case
    Ling.Fmt.Albert.Abs.CN name -> prPrec i 0 (concatD [doc (showString "`"), prt 0 name])

instance Print Ling.Fmt.Albert.Abs.OptDot where
  prt i = \case
    Ling.Fmt.Albert.Abs.NoDot -> prPrec i 0 (concatD [])
    Ling.Fmt.Albert.Abs.SoDot -> prPrec i 0 (concatD [doc (showString ".")])

instance Print Ling.Fmt.Albert.Abs.TermProc where
  prt i = \case
    Ling.Fmt.Albert.Abs.SoTerm term -> prPrec i 0 (concatD [prt 0 term])
    Ling.Fmt.Albert.Abs.SoProc proc_ -> prPrec i 0 (concatD [prt 0 proc_])

instance Print [Ling.Fmt.Albert.Abs.ConName] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString "|"), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.OptSig where
  prt i = \case
    Ling.Fmt.Albert.Abs.NoSig -> prPrec i 0 (concatD [])
    Ling.Fmt.Albert.Abs.SoSig term -> prPrec i 0 (concatD [doc (showString ":"), prt 0 term])

instance Print [Ling.Fmt.Albert.Abs.Dec] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.VarDec where
  prt i = \case
    Ling.Fmt.Albert.Abs.VD name optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 name, prt 0 optsig, doc (showString ")")])

instance Print Ling.Fmt.Albert.Abs.ChanDec where
  prt i = \case
    Ling.Fmt.Albert.Abs.CD name optrepl optsession -> prPrec i 0 (concatD [prt 0 name, prt 0 optrepl, prt 0 optsession])

instance Print [Ling.Fmt.Albert.Abs.ChanDec] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.Branch where
  prt i = \case
    Ling.Fmt.Albert.Abs.Br conname term -> prPrec i 0 (concatD [prt 0 conname, doc (showString "->"), prt 0 term])

instance Print [Ling.Fmt.Albert.Abs.Branch] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.Literal where
  prt i = \case
    Ling.Fmt.Albert.Abs.LInteger n -> prPrec i 0 (concatD [prt 0 n])
    Ling.Fmt.Albert.Abs.LDouble d -> prPrec i 0 (concatD [prt 0 d])
    Ling.Fmt.Albert.Abs.LString str -> prPrec i 0 (concatD [printString str])
    Ling.Fmt.Albert.Abs.LChar c -> prPrec i 0 (concatD [prt 0 c])

instance Print Ling.Fmt.Albert.Abs.ATerm where
  prt i = \case
    Ling.Fmt.Albert.Abs.Var name -> prPrec i 0 (concatD [prt 0 name])
    Ling.Fmt.Albert.Abs.Op opname -> prPrec i 0 (concatD [prt 0 opname])
    Ling.Fmt.Albert.Abs.Lit literal -> prPrec i 0 (concatD [prt 0 literal])
    Ling.Fmt.Albert.Abs.Con conname -> prPrec i 0 (concatD [prt 0 conname])
    Ling.Fmt.Albert.Abs.TTyp -> prPrec i 0 (concatD [doc (showString "Type")])
    Ling.Fmt.Albert.Abs.TProto rsessions -> prPrec i 0 (concatD [doc (showString "<"), prt 0 rsessions, doc (showString ">")])
    Ling.Fmt.Albert.Abs.Paren term optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")")])
    Ling.Fmt.Albert.Abs.End -> prPrec i 0 (concatD [doc (showString "end")])
    Ling.Fmt.Albert.Abs.Par rsessions -> prPrec i 0 (concatD [doc (showString "{"), prt 0 rsessions, doc (showString "}")])
    Ling.Fmt.Albert.Abs.Ten rsessions -> prPrec i 0 (concatD [doc (showString "["), prt 0 rsessions, doc (showString "]")])
    Ling.Fmt.Albert.Abs.Seq rsessions -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 rsessions, doc (showString ":]")])

instance Print [Ling.Fmt.Albert.Abs.ATerm] where
  prt _ [] = concatD []
  prt _ (x:xs) = concatD [prt 0 x, prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.Term where
  prt i = \case
    Ling.Fmt.Albert.Abs.RawApp aterm aterms -> prPrec i 3 (concatD [prt 0 aterm, prt 0 aterms])
    Ling.Fmt.Albert.Abs.Case term branchs -> prPrec i 2 (concatD [doc (showString "case"), prt 0 term, doc (showString "of"), doc (showString "{"), prt 0 branchs, doc (showString "}")])
    Ling.Fmt.Albert.Abs.Snd term csession -> prPrec i 2 (concatD [doc (showString "!"), prt 3 term, prt 0 csession])
    Ling.Fmt.Albert.Abs.Rcv term csession -> prPrec i 2 (concatD [doc (showString "?"), prt 3 term, prt 0 csession])
    Ling.Fmt.Albert.Abs.Dual term -> prPrec i 2 (concatD [doc (showString "~"), prt 2 term])
    Ling.Fmt.Albert.Abs.TRecv name -> prPrec i 2 (concatD [doc (showString "<-"), prt 0 name])
    Ling.Fmt.Albert.Abs.Loli term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "-o"), prt 1 term2])
    Ling.Fmt.Albert.Abs.TFun term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "->"), prt 1 term2])
    Ling.Fmt.Albert.Abs.TSig term1 term2 -> prPrec i 1 (concatD [prt 2 term1, doc (showString "**"), prt 1 term2])
    Ling.Fmt.Albert.Abs.Let name optsig term1 term2 -> prPrec i 1 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "="), prt 0 term1, doc (showString "in"), prt 0 term2])
    Ling.Fmt.Albert.Abs.Lam term1 term2 -> prPrec i 0 (concatD [doc (showString "\\"), prt 2 term1, doc (showString "->"), prt 0 term2])
    Ling.Fmt.Albert.Abs.TProc chandecs proc_ -> prPrec i 0 (concatD [doc (showString "proc"), doc (showString "("), prt 0 chandecs, doc (showString ")"), prt 0 proc_])

instance Print Ling.Fmt.Albert.Abs.Proc where
  prt i = \case
    Ling.Fmt.Albert.Abs.PAct act -> prPrec i 1 (concatD [prt 0 act])
    Ling.Fmt.Albert.Abs.PPrll procs -> prPrec i 1 (concatD [doc (showString "("), prt 0 procs, doc (showString ")")])
    Ling.Fmt.Albert.Abs.PNxt proc_1 proc_2 -> prPrec i 0 (concatD [prt 1 proc_1, prt 0 proc_2])
    Ling.Fmt.Albert.Abs.PDot proc_1 proc_2 -> prPrec i 0 (concatD [prt 1 proc_1, doc (showString "."), prt 0 proc_2])
    Ling.Fmt.Albert.Abs.PSem proc_1 proc_2 -> prPrec i 0 (concatD [prt 1 proc_1, doc (showString ";"), prt 0 proc_2])
    Ling.Fmt.Albert.Abs.NewSlice chandecs aterm name proc_ -> prPrec i 0 (concatD [doc (showString "slice"), doc (showString "("), prt 0 chandecs, doc (showString ")"), prt 0 aterm, doc (showString "as"), prt 0 name, prt 0 proc_])

instance Print [Ling.Fmt.Albert.Abs.Proc] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString "|"), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.Act where
  prt i = \case
    Ling.Fmt.Albert.Abs.Nu newalloc -> prPrec i 0 (concatD [prt 0 newalloc])
    Ling.Fmt.Albert.Abs.ParSplit name chandecs -> prPrec i 0 (concatD [prt 0 name, doc (showString "{"), prt 0 chandecs, doc (showString "}")])
    Ling.Fmt.Albert.Abs.TenSplit name chandecs -> prPrec i 0 (concatD [prt 0 name, doc (showString "["), prt 0 chandecs, doc (showString "]")])
    Ling.Fmt.Albert.Abs.SeqSplit name chandecs -> prPrec i 0 (concatD [prt 0 name, doc (showString "[:"), prt 0 chandecs, doc (showString ":]")])
    Ling.Fmt.Albert.Abs.Send name aterm -> prPrec i 0 (concatD [doc (showString "send"), prt 0 name, prt 0 aterm])
    Ling.Fmt.Albert.Abs.NewSend name aterm -> prPrec i 0 (concatD [prt 0 name, doc (showString "<-"), prt 0 aterm])
    Ling.Fmt.Albert.Abs.Recv name vardec -> prPrec i 0 (concatD [doc (showString "recv"), prt 0 name, prt 0 vardec])
    Ling.Fmt.Albert.Abs.NewRecv name1 optsig name2 -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name1, prt 0 optsig, doc (showString "<-"), prt 0 name2])
    Ling.Fmt.Albert.Abs.LetRecv name optsig aterm -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "<="), prt 0 aterm])
    Ling.Fmt.Albert.Abs.Ax asession chandecs -> prPrec i 0 (concatD [doc (showString "fwd"), prt 0 asession, doc (showString "("), prt 0 chandecs, doc (showString ")")])
    Ling.Fmt.Albert.Abs.SplitAx n asession name -> prPrec i 0 (concatD [doc (showString "fwd"), prt 0 n, prt 0 asession, prt 0 name])
    Ling.Fmt.Albert.Abs.At aterm topcpatt -> prPrec i 0 (concatD [doc (showString "@"), prt 0 aterm, prt 0 topcpatt])
    Ling.Fmt.Albert.Abs.LetA name optsig aterm -> prPrec i 0 (concatD [doc (showString "let"), prt 0 name, prt 0 optsig, doc (showString "="), prt 0 aterm])

instance Print Ling.Fmt.Albert.Abs.ASession where
  prt i = \case
    Ling.Fmt.Albert.Abs.AS aterm -> prPrec i 0 (concatD [prt 0 aterm])

instance Print Ling.Fmt.Albert.Abs.TopCPatt where
  prt i = \case
    Ling.Fmt.Albert.Abs.OldTopPatt chandecs -> prPrec i 0 (concatD [doc (showString "("), prt 0 chandecs, doc (showString ")")])
    Ling.Fmt.Albert.Abs.ParTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "{"), prt 0 cpatts, doc (showString "}")])
    Ling.Fmt.Albert.Abs.TenTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "["), prt 0 cpatts, doc (showString "]")])
    Ling.Fmt.Albert.Abs.SeqTopPatt cpatts -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 cpatts, doc (showString ":]")])

instance Print Ling.Fmt.Albert.Abs.CPatt where
  prt i = \case
    Ling.Fmt.Albert.Abs.ChaPatt chandec -> prPrec i 0 (concatD [prt 0 chandec])
    Ling.Fmt.Albert.Abs.ParPatt cpatts -> prPrec i 0 (concatD [doc (showString "{"), prt 0 cpatts, doc (showString "}")])
    Ling.Fmt.Albert.Abs.TenPatt cpatts -> prPrec i 0 (concatD [doc (showString "["), prt 0 cpatts, doc (showString "]")])
    Ling.Fmt.Albert.Abs.SeqPatt cpatts -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 cpatts, doc (showString ":]")])

instance Print [Ling.Fmt.Albert.Abs.CPatt] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.OptSession where
  prt i = \case
    Ling.Fmt.Albert.Abs.NoSession -> prPrec i 0 (concatD [])
    Ling.Fmt.Albert.Abs.SoSession rsession -> prPrec i 0 (concatD [doc (showString ":"), prt 0 rsession])

instance Print Ling.Fmt.Albert.Abs.RSession where
  prt i = \case
    Ling.Fmt.Albert.Abs.Repl term optrepl -> prPrec i 0 (concatD [prt 0 term, prt 0 optrepl])

instance Print [Ling.Fmt.Albert.Abs.RSession] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.OptRepl where
  prt i = \case
    Ling.Fmt.Albert.Abs.One -> prPrec i 0 (concatD [])
    Ling.Fmt.Albert.Abs.Some aterm -> prPrec i 0 (concatD [doc (showString "^"), prt 0 aterm])

instance Print Ling.Fmt.Albert.Abs.CSession where
  prt i = \case
    Ling.Fmt.Albert.Abs.Cont term -> prPrec i 0 (concatD [doc (showString "."), prt 1 term])
    Ling.Fmt.Albert.Abs.Done -> prPrec i 0 (concatD [])

instance Print Ling.Fmt.Albert.Abs.AllocTerm where
  prt i = \case
    Ling.Fmt.Albert.Abs.AVar name -> prPrec i 0 (concatD [prt 0 name])
    Ling.Fmt.Albert.Abs.ALit literal -> prPrec i 0 (concatD [prt 0 literal])
    Ling.Fmt.Albert.Abs.AParen term optsig -> prPrec i 0 (concatD [doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")")])

instance Print [Ling.Fmt.Albert.Abs.AllocTerm] where
  prt _ [] = concatD []
  prt _ (x:xs) = concatD [prt 0 x, prt 0 xs]

instance Print Ling.Fmt.Albert.Abs.NewPatt where
  prt i = \case
    Ling.Fmt.Albert.Abs.TenNewPatt chandecs -> prPrec i 0 (concatD [doc (showString "["), prt 0 chandecs, doc (showString "]")])
    Ling.Fmt.Albert.Abs.SeqNewPatt chandecs -> prPrec i 0 (concatD [doc (showString "[:"), prt 0 chandecs, doc (showString ":]")])

instance Print Ling.Fmt.Albert.Abs.NewAlloc where
  prt i = \case
    Ling.Fmt.Albert.Abs.OldNew chandecs -> prPrec i 0 (concatD [doc (showString "new"), doc (showString "("), prt 0 chandecs, doc (showString ")")])
    Ling.Fmt.Albert.Abs.New newpatt -> prPrec i 0 (concatD [doc (showString "new"), prt 0 newpatt])
    Ling.Fmt.Albert.Abs.NewSAnn term optsig newpatt -> prPrec i 0 (concatD [doc (showString "new/"), doc (showString "("), prt 0 term, prt 0 optsig, doc (showString ")"), prt 0 newpatt])
    Ling.Fmt.Albert.Abs.NewNAnn opname allocterms newpatt -> prPrec i 0 (concatD [prt 0 opname, prt 0 allocterms, prt 0 newpatt])
