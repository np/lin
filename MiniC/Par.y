-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module MiniC.Par where
import MiniC.Abs
import MiniC.Lex
import MiniC.ErrM

}

%name pPrg Prg
%name pDec Dec
%name pListDec ListDec
%name pDef Def
%name pListDef ListDef
%name pTyp Typ
%name pListTyp ListTyp
%name pEnm Enm
%name pListEnm ListEnm
%name pFld Fld
%name pListFld ListFld
%name pArr Arr
%name pListArr ListArr
%name pQTyp QTyp
%name pQual Qual
%name pStm Stm
%name pBranch Branch
%name pListBranch ListBranch
%name pInit Init
%name pListStm ListStm
%name pLiteral Literal
%name pExp16 Exp16
%name pExp15 Exp15
%name pUOp UOp
%name pExp14 Exp14
%name pExp13 Exp13
%name pExp12 Exp12
%name pExp11 Exp11
%name pExp10 Exp10
%name pExp9 Exp9
%name pExp8 Exp8
%name pExp7 Exp7
%name pExp6 Exp6
%name pExp5 Exp5
%name pExp4 Exp4
%name pExp3 Exp3
%name pExp2 Exp2
%name pExp1 Exp1
%name pExp Exp
%name pListExp ListExp
%name pLVal3 LVal3
%name pLVal2 LVal2
%name pLVal LVal
-- no lexer declaration
%monad { Err } { thenM } { returnM }
%tokentype {Token}
%token
  '!' { PT _ (TS _ 1) }
  '!=' { PT _ (TS _ 2) }
  '%' { PT _ (TS _ 3) }
  '&' { PT _ (TS _ 4) }
  '&&' { PT _ (TS _ 5) }
  '(' { PT _ (TS _ 6) }
  ')' { PT _ (TS _ 7) }
  '*' { PT _ (TS _ 8) }
  '+' { PT _ (TS _ 9) }
  ',' { PT _ (TS _ 10) }
  '-' { PT _ (TS _ 11) }
  '->' { PT _ (TS _ 12) }
  '.' { PT _ (TS _ 13) }
  '/' { PT _ (TS _ 14) }
  ':' { PT _ (TS _ 15) }
  ';' { PT _ (TS _ 16) }
  '<' { PT _ (TS _ 17) }
  '<<' { PT _ (TS _ 18) }
  '<=' { PT _ (TS _ 19) }
  '=' { PT _ (TS _ 20) }
  '==' { PT _ (TS _ 21) }
  '>' { PT _ (TS _ 22) }
  '>=' { PT _ (TS _ 23) }
  '>>' { PT _ (TS _ 24) }
  '?' { PT _ (TS _ 25) }
  '[' { PT _ (TS _ 26) }
  ']' { PT _ (TS _ 27) }
  '^' { PT _ (TS _ 28) }
  'break' { PT _ (TS _ 29) }
  'case' { PT _ (TS _ 30) }
  'char' { PT _ (TS _ 31) }
  'const' { PT _ (TS _ 32) }
  'double' { PT _ (TS _ 33) }
  'enum' { PT _ (TS _ 34) }
  'for' { PT _ (TS _ 35) }
  'int' { PT _ (TS _ 36) }
  'struct' { PT _ (TS _ 37) }
  'switch' { PT _ (TS _ 38) }
  'union' { PT _ (TS _ 39) }
  'void' { PT _ (TS _ 40) }
  '{' { PT _ (TS _ 41) }
  '|' { PT _ (TS _ 42) }
  '||' { PT _ (TS _ 43) }
  '}' { PT _ (TS _ 44) }
  '~' { PT _ (TS _ 45) }

L_ident  { PT _ (TV $$) }
L_integ  { PT _ (TI $$) }
L_doubl  { PT _ (TD $$) }
L_quoted { PT _ (TL $$) }
L_charac { PT _ (TC $$) }


%%

Ident   :: { Ident }   : L_ident  { Ident $1 }
Integer :: { Integer } : L_integ  { (read ( $1)) :: Integer }
Double  :: { Double }  : L_doubl  { (read ( $1)) :: Double }
String  :: { String }  : L_quoted {  $1 }
Char    :: { Char }    : L_charac { (read ( $1)) :: Char }

Prg :: { Prg }
Prg : ListDef { MiniC.Abs.PPrg (reverse $1) }
Dec :: { Dec }
Dec : QTyp Ident ListArr { MiniC.Abs.Dec $1 $2 (reverse $3) }
ListDec :: { [Dec] }
ListDec : {- empty -} { [] }
        | Dec { (:[]) $1 }
        | Dec ',' ListDec { (:) $1 $3 }
Def :: { Def }
Def : Dec '(' ListDec ')' '{' ListStm '}' { MiniC.Abs.DDef $1 $3 (reverse $6) }
    | Dec '(' ListDec ')' ';' { MiniC.Abs.DSig $1 $3 }
    | Dec ';' { MiniC.Abs.DDec $1 }
ListDef :: { [Def] }
ListDef : {- empty -} { [] } | ListDef Def { flip (:) $1 $2 }
Typ :: { Typ }
Typ : 'int' { MiniC.Abs.TInt }
    | 'double' { MiniC.Abs.TDouble }
    | 'char' { MiniC.Abs.TChar }
    | 'struct' '{' ListFld '}' { MiniC.Abs.TStr (reverse $3) }
    | 'union' '{' ListFld '}' { MiniC.Abs.TUni (reverse $3) }
    | 'enum' '{' ListEnm '}' { MiniC.Abs.TEnum $3 }
    | 'void' { MiniC.Abs.TVoid }
    | Typ '*' { MiniC.Abs.TPtr $1 }
ListTyp :: { [Typ] }
ListTyp : {- empty -} { [] }
        | Typ { (:[]) $1 }
        | Typ ',' ListTyp { (:) $1 $3 }
Enm :: { Enm }
Enm : Ident { MiniC.Abs.EEnm $1 }
    | Ident '=' Exp2 { MiniC.Abs.ECst $1 $3 }
ListEnm :: { [Enm] }
ListEnm : {- empty -} { [] }
        | Enm { (:[]) $1 }
        | Enm ',' ListEnm { (:) $1 $3 }
Fld :: { Fld }
Fld : Typ Ident ListArr { MiniC.Abs.FFld $1 $2 (reverse $3) }
ListFld :: { [Fld] }
ListFld : {- empty -} { [] } | ListFld Fld ';' { flip (:) $1 $2 }
Arr :: { Arr }
Arr : '[' Exp ']' { MiniC.Abs.AArr $2 }
ListArr :: { [Arr] }
ListArr : {- empty -} { [] } | ListArr Arr { flip (:) $1 $2 }
QTyp :: { QTyp }
QTyp : Qual Typ { MiniC.Abs.QTyp $1 $2 }
Qual :: { Qual }
Qual : {- empty -} { MiniC.Abs.NoQual }
     | 'const' { MiniC.Abs.QConst }
Stm :: { Stm }
Stm : Dec Init { MiniC.Abs.SDec $1 $2 }
    | LVal '=' Exp { MiniC.Abs.SPut $1 $3 }
    | 'for' '(' Stm ';' Exp ';' Stm ')' '{' ListStm '}' { MiniC.Abs.SFor $3 $5 $7 (reverse $10) }
    | 'switch' '(' Exp ')' '{' ListBranch '}' { MiniC.Abs.SSwi $3 (reverse $6) }
Branch :: { Branch }
Branch : 'case' Exp2 ':' ListStm 'break' ';' { MiniC.Abs.Case $2 (reverse $4) }
ListBranch :: { [Branch] }
ListBranch : {- empty -} { [] }
           | ListBranch Branch { flip (:) $1 $2 }
Init :: { Init }
Init : {- empty -} { MiniC.Abs.NoInit }
     | '=' Exp { MiniC.Abs.SoInit $2 }
ListStm :: { [Stm] }
ListStm : {- empty -} { [] } | ListStm Stm ';' { flip (:) $1 $2 }
Literal :: { Literal }
Literal : Integer { MiniC.Abs.LInteger $1 }
        | Double { MiniC.Abs.LDouble $1 }
        | String { MiniC.Abs.LString $1 }
        | Char { MiniC.Abs.LChar $1 }
Exp16 :: { Exp }
Exp16 : Ident { MiniC.Abs.EVar $1 }
      | Literal { MiniC.Abs.ELit $1 }
      | '(' Exp ')' { MiniC.Abs.EParen $2 }
Exp15 :: { Exp }
Exp15 : Exp15 '->' Ident { MiniC.Abs.EArw $1 $3 }
      | Exp15 '.' Ident { MiniC.Abs.EFld $1 $3 }
      | Exp15 '[' Exp ']' { MiniC.Abs.EArr $1 $3 }
      | Exp15 '(' ListExp ')' { MiniC.Abs.EApp $1 $3 }
      | Exp16 { $1 }
UOp :: { UOp }
UOp : '&' { MiniC.Abs.UAmp }
    | '*' { MiniC.Abs.UPtr }
    | '+' { MiniC.Abs.UPlus }
    | '-' { MiniC.Abs.UMinus }
    | '~' { MiniC.Abs.UTilde }
    | '!' { MiniC.Abs.UBang }
Exp14 :: { Exp }
Exp14 : Exp15 { $1 } | UOp Exp13 { MiniC.Abs.UOp $1 $2 }
Exp13 :: { Exp }
Exp13 : Exp14 { $1 }
Exp12 :: { Exp }
Exp12 : Exp13 { $1 }
      | Exp12 '*' Exp13 { MiniC.Abs.Mul $1 $3 }
      | Exp12 '/' Exp13 { MiniC.Abs.Div $1 $3 }
      | Exp12 '%' Exp13 { MiniC.Abs.Mod $1 $3 }
Exp11 :: { Exp }
Exp11 : Exp12 { $1 }
      | Exp11 '+' Exp12 { MiniC.Abs.Add $1 $3 }
      | Exp11 '-' Exp12 { MiniC.Abs.Sub $1 $3 }
Exp10 :: { Exp }
Exp10 : Exp11 { $1 }
      | Exp10 '<<' Exp11 { MiniC.Abs.Lsl $1 $3 }
      | Exp10 '>>' Exp11 { MiniC.Abs.Lsr $1 $3 }
Exp9 :: { Exp }
Exp9 : Exp10 { $1 }
     | Exp9 '<' Exp10 { MiniC.Abs.Lt $1 $3 }
     | Exp9 '>' Exp10 { MiniC.Abs.Gt $1 $3 }
     | Exp9 '<=' Exp10 { MiniC.Abs.Le $1 $3 }
     | Exp9 '>=' Exp10 { MiniC.Abs.Ge $1 $3 }
Exp8 :: { Exp }
Exp8 : Exp9 { $1 }
     | Exp8 '==' Exp9 { MiniC.Abs.Eq $1 $3 }
     | Exp8 '!=' Exp9 { MiniC.Abs.NEq $1 $3 }
Exp7 :: { Exp }
Exp7 : Exp8 { $1 } | Exp7 '&' Exp8 { MiniC.Abs.And $1 $3 }
Exp6 :: { Exp }
Exp6 : Exp7 { $1 } | Exp6 '^' Exp7 { MiniC.Abs.Xor $1 $3 }
Exp5 :: { Exp }
Exp5 : Exp6 { $1 } | Exp5 '|' Exp6 { MiniC.Abs.Ior $1 $3 }
Exp4 :: { Exp }
Exp4 : Exp5 { $1 } | Exp4 '&&' Exp5 { MiniC.Abs.Land $1 $3 }
Exp3 :: { Exp }
Exp3 : Exp4 { $1 } | Exp3 '||' Exp4 { MiniC.Abs.Lor $1 $3 }
Exp2 :: { Exp }
Exp2 : Exp3 { $1 }
     | Exp3 '?' Exp ':' Exp2 { MiniC.Abs.Cond $1 $3 $5 }
Exp1 :: { Exp }
Exp1 : Exp2 { $1 }
Exp :: { Exp }
Exp : Exp1 { $1 }
ListExp :: { [Exp] }
ListExp : {- empty -} { [] }
        | Exp { (:[]) $1 }
        | Exp ',' ListExp { (:) $1 $3 }
LVal3 :: { LVal }
LVal3 : Ident { MiniC.Abs.LVar $1 } | '(' LVal ')' { $2 }
LVal2 :: { LVal }
LVal2 : LVal2 '->' Ident { MiniC.Abs.LArw $1 $3 }
      | LVal2 '.' Ident { MiniC.Abs.LFld $1 $3 }
      | LVal2 '[' Exp ']' { MiniC.Abs.LArr $1 $3 }
      | LVal3 { $1 }
LVal :: { LVal }
LVal : '*' LVal2 { MiniC.Abs.LPtr $2 } | LVal2 { $1 }
{

returnM :: a -> Err a
returnM = return

thenM :: Err a -> (a -> Err b) -> Err b
thenM = (>>=)

happyError :: [Token] -> Err a
happyError ts =
  Bad $ "syntax error at " ++ tokenPos ts ++
  case ts of
    [] -> []
    [Err _] -> " due to lexer error"
    _ -> " before " ++ unwords (map (id . prToken) (take 4 ts))

myLexer = tokens
}

