-- -*- haskell -*- File generated by the BNF Converter (bnfc 2.9.4.1).

-- Parser definition for use with Happy
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
{-# LANGUAGE PatternSynonyms #-}

module Ling.Fmt.Albert.Par
  ( happyError
  , myLexer
  , pProgram
  , pDec
  , pAssertion
  , pConName
  , pOptDot
  , pTermProc
  , pListConName
  , pOptSig
  , pListDec
  , pVarDec
  , pChanDec
  , pListChanDec
  , pBranch
  , pListBranch
  , pLiteral
  , pATerm
  , pListATerm
  , pTerm3
  , pTerm2
  , pTerm1
  , pTerm
  , pProc1
  , pProc
  , pListProc
  , pAct
  , pASession
  , pTopCPatt
  , pCPatt
  , pListCPatt
  , pOptSession
  , pRSession
  , pListRSession
  , pOptRepl
  , pCSession
  , pAllocTerm
  , pListAllocTerm
  , pNewPatt
  , pNewAlloc
  ) where

import Prelude

import qualified Ling.Fmt.Albert.Abs
import Ling.Fmt.Albert.Lex

}

%name pProgram Program
%name pDec Dec
%name pAssertion Assertion
%name pConName ConName
%name pOptDot OptDot
%name pTermProc TermProc
%name pListConName ListConName
%name pOptSig OptSig
%name pListDec ListDec
%name pVarDec VarDec
%name pChanDec ChanDec
%name pListChanDec ListChanDec
%name pBranch Branch
%name pListBranch ListBranch
%name pLiteral Literal
%name pATerm ATerm
%name pListATerm ListATerm
%name pTerm3 Term3
%name pTerm2 Term2
%name pTerm1 Term1
%name pTerm Term
%name pProc1 Proc1
%name pProc Proc
%name pListProc ListProc
%name pAct Act
%name pASession ASession
%name pTopCPatt TopCPatt
%name pCPatt CPatt
%name pListCPatt ListCPatt
%name pOptSession OptSession
%name pRSession RSession
%name pListRSession ListRSession
%name pOptRepl OptRepl
%name pCSession CSession
%name pAllocTerm AllocTerm
%name pListAllocTerm ListAllocTerm
%name pNewPatt NewPatt
%name pNewAlloc NewAlloc
-- no lexer declaration
%monad { Err } { (>>=) } { return }
%tokentype {Token}
%token
  '!'      { PT _ (TS _ 1)      }
  '('      { PT _ (TS _ 2)      }
  ')'      { PT _ (TS _ 3)      }
  '**'     { PT _ (TS _ 4)      }
  ','      { PT _ (TS _ 5)      }
  '->'     { PT _ (TS _ 6)      }
  '-o'     { PT _ (TS _ 7)      }
  '.'      { PT _ (TS _ 8)      }
  ':'      { PT _ (TS _ 9)      }
  ':]'     { PT _ (TS _ 10)     }
  ';'      { PT _ (TS _ 11)     }
  '<'      { PT _ (TS _ 12)     }
  '<-'     { PT _ (TS _ 13)     }
  '<='     { PT _ (TS _ 14)     }
  '='      { PT _ (TS _ 15)     }
  '>'      { PT _ (TS _ 16)     }
  '?'      { PT _ (TS _ 17)     }
  '@'      { PT _ (TS _ 18)     }
  'Type'   { PT _ (TS _ 19)     }
  '['      { PT _ (TS _ 20)     }
  '[:'     { PT _ (TS _ 21)     }
  '\\'     { PT _ (TS _ 22)     }
  ']'      { PT _ (TS _ 23)     }
  '^'      { PT _ (TS _ 24)     }
  '`'      { PT _ (TS _ 25)     }
  'as'     { PT _ (TS _ 26)     }
  'assert' { PT _ (TS _ 27)     }
  'case'   { PT _ (TS _ 28)     }
  'data'   { PT _ (TS _ 29)     }
  'end'    { PT _ (TS _ 30)     }
  'fwd'    { PT _ (TS _ 31)     }
  'in'     { PT _ (TS _ 32)     }
  'let'    { PT _ (TS _ 33)     }
  'new'    { PT _ (TS _ 34)     }
  'new/'   { PT _ (TS _ 35)     }
  'of'     { PT _ (TS _ 36)     }
  'proc'   { PT _ (TS _ 37)     }
  'recv'   { PT _ (TS _ 38)     }
  'send'   { PT _ (TS _ 39)     }
  'slice'  { PT _ (TS _ 40)     }
  '{'      { PT _ (TS _ 41)     }
  '|'      { PT _ (TS _ 42)     }
  '}'      { PT _ (TS _ 43)     }
  '~'      { PT _ (TS _ 44)     }
  L_charac { PT _ (TC $$)       }
  L_doubl  { PT _ (TD $$)       }
  L_integ  { PT _ (TI $$)       }
  L_quoted { PT _ (TL $$)       }
  L_Name   { PT _ (T_Name $$)   }
  L_OpName { PT _ (T_OpName $$) }

%%

Char    :: { Char }
Char     : L_charac { (read $1) :: Char }

Double  :: { Double }
Double   : L_doubl  { (read $1) :: Double }

Integer :: { Integer }
Integer  : L_integ  { (read $1) :: Integer }

String  :: { String }
String   : L_quoted { $1 }

Name :: { Ling.Fmt.Albert.Abs.Name }
Name  : L_Name { Ling.Fmt.Albert.Abs.Name $1 }

OpName :: { Ling.Fmt.Albert.Abs.OpName }
OpName  : L_OpName { Ling.Fmt.Albert.Abs.OpName $1 }

Program :: { Ling.Fmt.Albert.Abs.Program }
Program : ListDec { Ling.Fmt.Albert.Abs.Prg $1 }

Dec :: { Ling.Fmt.Albert.Abs.Dec }
Dec
  : Name '(' ListChanDec ')' '=' Proc OptDot { Ling.Fmt.Albert.Abs.DPrc $1 $3 $6 $7 }
  | Name OptSig '=' TermProc OptDot { Ling.Fmt.Albert.Abs.DDef $1 $2 $4 $5 }
  | Name ':' Term OptDot { Ling.Fmt.Albert.Abs.DSig $1 $3 $4 }
  | 'data' Name '=' ListConName OptDot { Ling.Fmt.Albert.Abs.DDat $2 $4 $5 }
  | 'assert' Assertion { Ling.Fmt.Albert.Abs.DAsr $2 }

Assertion :: { Ling.Fmt.Albert.Abs.Assertion }
Assertion
  : Term '=' Term OptSig { Ling.Fmt.Albert.Abs.AEq $1 $3 $4 }

ConName :: { Ling.Fmt.Albert.Abs.ConName }
ConName : '`' Name { Ling.Fmt.Albert.Abs.CN $2 }

OptDot :: { Ling.Fmt.Albert.Abs.OptDot }
OptDot
  : {- empty -} { Ling.Fmt.Albert.Abs.NoDot }
  | '.' { Ling.Fmt.Albert.Abs.SoDot }

TermProc :: { Ling.Fmt.Albert.Abs.TermProc }
TermProc
  : Term { Ling.Fmt.Albert.Abs.SoTerm $1 }
  | Proc { Ling.Fmt.Albert.Abs.SoProc $1 }

ListConName :: { [Ling.Fmt.Albert.Abs.ConName] }
ListConName
  : {- empty -} { [] }
  | ConName { (:[]) $1 }
  | ConName '|' ListConName { (:) $1 $3 }

OptSig :: { Ling.Fmt.Albert.Abs.OptSig }
OptSig
  : {- empty -} { Ling.Fmt.Albert.Abs.NoSig }
  | ':' Term { Ling.Fmt.Albert.Abs.SoSig $2 }

ListDec :: { [Ling.Fmt.Albert.Abs.Dec] }
ListDec
  : {- empty -} { [] }
  | Dec { (:[]) $1 }
  | Dec ',' ListDec { (:) $1 $3 }

VarDec :: { Ling.Fmt.Albert.Abs.VarDec }
VarDec : '(' Name OptSig ')' { Ling.Fmt.Albert.Abs.VD $2 $3 }

ChanDec :: { Ling.Fmt.Albert.Abs.ChanDec }
ChanDec
  : Name OptRepl OptSession { Ling.Fmt.Albert.Abs.CD $1 $2 $3 }

ListChanDec :: { [Ling.Fmt.Albert.Abs.ChanDec] }
ListChanDec
  : {- empty -} { [] }
  | ChanDec { (:[]) $1 }
  | ChanDec ',' ListChanDec { (:) $1 $3 }

Branch :: { Ling.Fmt.Albert.Abs.Branch }
Branch : ConName '->' Term { Ling.Fmt.Albert.Abs.Br $1 $3 }

ListBranch :: { [Ling.Fmt.Albert.Abs.Branch] }
ListBranch
  : {- empty -} { [] }
  | Branch { (:[]) $1 }
  | Branch ',' ListBranch { (:) $1 $3 }

Literal :: { Ling.Fmt.Albert.Abs.Literal }
Literal
  : Integer { Ling.Fmt.Albert.Abs.LInteger $1 }
  | Double { Ling.Fmt.Albert.Abs.LDouble $1 }
  | String { Ling.Fmt.Albert.Abs.LString $1 }
  | Char { Ling.Fmt.Albert.Abs.LChar $1 }

ATerm :: { Ling.Fmt.Albert.Abs.ATerm }
ATerm
  : Name { Ling.Fmt.Albert.Abs.Var $1 }
  | OpName { Ling.Fmt.Albert.Abs.Op $1 }
  | Literal { Ling.Fmt.Albert.Abs.Lit $1 }
  | ConName { Ling.Fmt.Albert.Abs.Con $1 }
  | 'Type' { Ling.Fmt.Albert.Abs.TTyp }
  | '<' ListRSession '>' { Ling.Fmt.Albert.Abs.TProto $2 }
  | '(' Term OptSig ')' { Ling.Fmt.Albert.Abs.Paren $2 $3 }
  | 'end' { Ling.Fmt.Albert.Abs.End }
  | '{' ListRSession '}' { Ling.Fmt.Albert.Abs.Par $2 }
  | '[' ListRSession ']' { Ling.Fmt.Albert.Abs.Ten $2 }
  | '[:' ListRSession ':]' { Ling.Fmt.Albert.Abs.Seq $2 }

ListATerm :: { [Ling.Fmt.Albert.Abs.ATerm] }
ListATerm : {- empty -} { [] } | ATerm ListATerm { (:) $1 $2 }

Term3 :: { Ling.Fmt.Albert.Abs.Term }
Term3 : ATerm ListATerm { Ling.Fmt.Albert.Abs.RawApp $1 $2 }

Term2 :: { Ling.Fmt.Albert.Abs.Term }
Term2
  : 'case' Term 'of' '{' ListBranch '}' { Ling.Fmt.Albert.Abs.Case $2 $5 }
  | '!' Term3 CSession { Ling.Fmt.Albert.Abs.Snd $2 $3 }
  | '?' Term3 CSession { Ling.Fmt.Albert.Abs.Rcv $2 $3 }
  | '~' Term2 { Ling.Fmt.Albert.Abs.Dual $2 }
  | '<-' Name { Ling.Fmt.Albert.Abs.TRecv $2 }
  | Term3 { $1 }

Term1 :: { Ling.Fmt.Albert.Abs.Term }
Term1
  : Term2 '-o' Term1 { Ling.Fmt.Albert.Abs.Loli $1 $3 }
  | Term2 '->' Term1 { Ling.Fmt.Albert.Abs.TFun $1 $3 }
  | Term2 '**' Term1 { Ling.Fmt.Albert.Abs.TSig $1 $3 }
  | 'let' Name OptSig '=' Term 'in' Term { Ling.Fmt.Albert.Abs.Let $2 $3 $5 $7 }
  | Term2 { $1 }

Term :: { Ling.Fmt.Albert.Abs.Term }
Term
  : '\\' Term2 '->' Term { Ling.Fmt.Albert.Abs.Lam $2 $4 }
  | 'proc' '(' ListChanDec ')' Proc { Ling.Fmt.Albert.Abs.TProc $3 $5 }
  | Term1 { $1 }

Proc1 :: { Ling.Fmt.Albert.Abs.Proc }
Proc1
  : Act { Ling.Fmt.Albert.Abs.PAct $1 }
  | '(' ListProc ')' { Ling.Fmt.Albert.Abs.PPrll $2 }

Proc :: { Ling.Fmt.Albert.Abs.Proc }
Proc
  : Proc1 Proc { Ling.Fmt.Albert.Abs.PNxt $1 $2 }
  | Proc1 '.' Proc { Ling.Fmt.Albert.Abs.PDot $1 $3 }
  | Proc1 ';' Proc { Ling.Fmt.Albert.Abs.PSem $1 $3 }
  | 'slice' '(' ListChanDec ')' ATerm 'as' Name Proc { Ling.Fmt.Albert.Abs.NewSlice $3 $5 $7 $8 }
  | Proc1 { $1 }

ListProc :: { [Ling.Fmt.Albert.Abs.Proc] }
ListProc
  : {- empty -} { [] }
  | Proc { (:[]) $1 }
  | Proc '|' ListProc { (:) $1 $3 }

Act :: { Ling.Fmt.Albert.Abs.Act }
Act
  : NewAlloc { Ling.Fmt.Albert.Abs.Nu $1 }
  | Name '{' ListChanDec '}' { Ling.Fmt.Albert.Abs.ParSplit $1 $3 }
  | Name '[' ListChanDec ']' { Ling.Fmt.Albert.Abs.TenSplit $1 $3 }
  | Name '[:' ListChanDec ':]' { Ling.Fmt.Albert.Abs.SeqSplit $1 $3 }
  | 'send' Name ATerm { Ling.Fmt.Albert.Abs.Send $2 $3 }
  | Name '<-' ATerm { Ling.Fmt.Albert.Abs.NewSend $1 $3 }
  | 'recv' Name VarDec { Ling.Fmt.Albert.Abs.Recv $2 $3 }
  | 'let' Name OptSig '<-' Name { Ling.Fmt.Albert.Abs.NewRecv $2 $3 $5 }
  | 'let' Name OptSig '<=' ATerm { Ling.Fmt.Albert.Abs.LetRecv $2 $3 $5 }
  | 'fwd' ASession '(' ListChanDec ')' { Ling.Fmt.Albert.Abs.Ax $2 $4 }
  | 'fwd' Integer ASession Name { Ling.Fmt.Albert.Abs.SplitAx $2 $3 $4 }
  | '@' ATerm TopCPatt { Ling.Fmt.Albert.Abs.At $2 $3 }
  | 'let' Name OptSig '=' ATerm { Ling.Fmt.Albert.Abs.LetA $2 $3 $5 }

ASession :: { Ling.Fmt.Albert.Abs.ASession }
ASession : ATerm { Ling.Fmt.Albert.Abs.AS $1 }

TopCPatt :: { Ling.Fmt.Albert.Abs.TopCPatt }
TopCPatt
  : '(' ListChanDec ')' { Ling.Fmt.Albert.Abs.OldTopPatt $2 }
  | '{' ListCPatt '}' { Ling.Fmt.Albert.Abs.ParTopPatt $2 }
  | '[' ListCPatt ']' { Ling.Fmt.Albert.Abs.TenTopPatt $2 }
  | '[:' ListCPatt ':]' { Ling.Fmt.Albert.Abs.SeqTopPatt $2 }

CPatt :: { Ling.Fmt.Albert.Abs.CPatt }
CPatt
  : ChanDec { Ling.Fmt.Albert.Abs.ChaPatt $1 }
  | '{' ListCPatt '}' { Ling.Fmt.Albert.Abs.ParPatt $2 }
  | '[' ListCPatt ']' { Ling.Fmt.Albert.Abs.TenPatt $2 }
  | '[:' ListCPatt ':]' { Ling.Fmt.Albert.Abs.SeqPatt $2 }

ListCPatt :: { [Ling.Fmt.Albert.Abs.CPatt] }
ListCPatt
  : {- empty -} { [] }
  | CPatt { (:[]) $1 }
  | CPatt ',' ListCPatt { (:) $1 $3 }

OptSession :: { Ling.Fmt.Albert.Abs.OptSession }
OptSession
  : {- empty -} { Ling.Fmt.Albert.Abs.NoSession }
  | ':' RSession { Ling.Fmt.Albert.Abs.SoSession $2 }

RSession :: { Ling.Fmt.Albert.Abs.RSession }
RSession : Term OptRepl { Ling.Fmt.Albert.Abs.Repl $1 $2 }

ListRSession :: { [Ling.Fmt.Albert.Abs.RSession] }
ListRSession
  : {- empty -} { [] }
  | RSession { (:[]) $1 }
  | RSession ',' ListRSession { (:) $1 $3 }

OptRepl :: { Ling.Fmt.Albert.Abs.OptRepl }
OptRepl
  : {- empty -} { Ling.Fmt.Albert.Abs.One }
  | '^' ATerm { Ling.Fmt.Albert.Abs.Some $2 }

CSession :: { Ling.Fmt.Albert.Abs.CSession }
CSession
  : '.' Term1 { Ling.Fmt.Albert.Abs.Cont $2 }
  | {- empty -} { Ling.Fmt.Albert.Abs.Done }

AllocTerm :: { Ling.Fmt.Albert.Abs.AllocTerm }
AllocTerm
  : Name { Ling.Fmt.Albert.Abs.AVar $1 }
  | Literal { Ling.Fmt.Albert.Abs.ALit $1 }
  | '(' Term OptSig ')' { Ling.Fmt.Albert.Abs.AParen $2 $3 }

ListAllocTerm :: { [Ling.Fmt.Albert.Abs.AllocTerm] }
ListAllocTerm
  : {- empty -} { [] } | AllocTerm ListAllocTerm { (:) $1 $2 }

NewPatt :: { Ling.Fmt.Albert.Abs.NewPatt }
NewPatt
  : '[' ListChanDec ']' { Ling.Fmt.Albert.Abs.TenNewPatt $2 }
  | '[:' ListChanDec ':]' { Ling.Fmt.Albert.Abs.SeqNewPatt $2 }

NewAlloc :: { Ling.Fmt.Albert.Abs.NewAlloc }
NewAlloc
  : 'new' '(' ListChanDec ')' { Ling.Fmt.Albert.Abs.OldNew $3 }
  | 'new' NewPatt { Ling.Fmt.Albert.Abs.New $2 }
  | 'new/' '(' Term OptSig ')' NewPatt { Ling.Fmt.Albert.Abs.NewSAnn $3 $4 $6 }
  | OpName ListAllocTerm NewPatt { Ling.Fmt.Albert.Abs.NewNAnn $1 $2 $3 }

{

type Err = Either String

happyError :: [Token] -> Err a
happyError ts = Left $
  "syntax error at " ++ tokenPos ts ++
  case ts of
    []      -> []
    [Err _] -> " due to lexer error"
    t:_     -> " before `" ++ (prToken t) ++ "'"

myLexer :: String -> [Token]
myLexer = tokens

}
