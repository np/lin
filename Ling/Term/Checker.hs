{-# LANGUAGE TemplateHaskell, GeneralizedNewtypeDeriving,
             FlexibleInstances, MultiParamTypeClasses #-}
module Ling.Term.Checker where

import Ling.Abs (Name)
import Ling.Utils
import Ling.Print
import Ling.Proto
import Ling.Norm
import Ling.Subst
import Ling.Equiv
import Ling.ErrM

import qualified Data.Map as Map
import Data.Map (Map)
import Control.Monad.Reader
import Control.Monad.Error.Class
import Control.Applicative
import Control.Lens
import Debug.Trace

type Msg = String

data ProcDef = ProcDef Name [ChanDec] Proc Proto

data TCEnv = TCEnv
  { _verbosity :: Bool
  , _evars     :: Map Name Typ
  , _edefs     :: Map Name Term
  , _pdefs     :: Map Name ProcDef
  }

$(makeLenses ''TCEnv)

emptyTCEnv :: TCEnv
emptyTCEnv = TCEnv False Map.empty Map.empty Map.empty

newtype TC a = MkTC { unTC :: ReaderT TCEnv Err a }
  deriving (Functor, Applicative, Monad, MonadReader TCEnv)

instance MonadError String TC where
  throwError = MkTC . lift . Bad
  catchError = error "catchError: not implemented for TC"

{-
checkEquality :: (Print a, Eq a) => String -> a -> a -> TC ()
checkEquality msg t0 t1 = assertEqual t0 t1
  [msg
  ,"Expected:"
  ,"  " ++ pretty t0
  ,"Inferred:"
  ,"  " ++ pretty t1
  ]
-}

tcEqEnv :: TC EqEnv
tcEqEnv = emptyEqEnv <$> view edefs

checkEquivalence :: (Print a, Eq a, Equiv a) => String -> a -> a -> TC ()
checkEquivalence msg t0 t1 = do
  when (t0 /= t1) $ debug
    ["checkEquivalence:"
    ,"  " ++ pretty t0
    ,"against"
    ,"  " ++ pretty t1
    ]
  env <- tcEqEnv
  assert (equiv env t0 t1)
    [msg
    ,"Expected:"
    ,"  " ++ pretty t0
    ,"Inferred:"
    ,"  " ++ pretty t1
    ]

checkTypeEquivalence :: Typ -> Typ -> TC ()
checkTypeEquivalence = checkEquivalence "Types are not equivalent."

checkTyp :: Typ -> TC ()
checkTyp = checkTerm TTyp

checkVarDef :: Name -> Typ -> Maybe Term -> TC a -> TC a
checkVarDef x typ mt kont = do
  checkTyp typ
  checkMaybeTerm typ mt
  local ((evars %~ Map.insert x typ)
       . (edefs %~ maybe id (Map.insert x) mt)) kont

checkVarDec :: VarDec -> TC a -> TC a
checkVarDec (Arg x typ) = checkVarDef x typ Nothing

-- TODO: Here I assume that sessions are well formed
checkSessions :: [RSession] -> TC ()
checkSessions = mapM_ checkRSession

checkRSession :: RSession -> TC ()
checkRSession (Repl s t) = checkSession s >> checkTerm int t

checkSession :: Session -> TC ()
checkSession s0 = case s0 of
  Atm _ n -> checkTerm tSession (Def n [])
  End -> return ()
  Snd t s -> checkTyp t >> checkSession s
  Rcv t s -> checkTyp t >> checkSession s
  Par ss -> checkSessions ss
  Ten ss -> checkSessions ss
  Seq ss -> checkSessions ss

inferTerm :: Term -> TC Typ
inferTerm e0 = case e0 of
  Lit _           -> return int
  TTyp            -> return TTyp -- type-in-type
  Def x es        -> inferDef x es
  Lam arg t       -> TFun arg <$> checkVarDec arg (inferTerm t)
  Proc{}          -> throwError "inferTerm: NProc"
  TFun arg s      -> checkVarDec arg (checkTyp s) >> return TTyp
  TSig arg s      -> checkVarDec arg (checkTyp s) >> return TTyp
  TProto sessions -> checkSessions sessions       >> return TTyp

checkTerm :: Typ -> Term -> TC ()
checkTerm typ e = inferTerm e >>= checkTypeEquivalence typ

checkMaybeTerm :: Typ -> Maybe Term -> TC ()
checkMaybeTerm _   Nothing   = return ()
checkMaybeTerm typ (Just tm) = checkTerm typ tm

inferDef :: Name -> [Term] -> TC Typ
inferDef f es = do
  mtyp <- view $ evars . at f
  case mtyp of
    Just typ -> checkApp typ es
    Nothing  -> throwError $ "unknown definition " ++ unName f

unDefTC :: Term -> TC Term
unDefTC tm = unDef <$> view edefs <*> return tm

checkApp :: Typ -> [Term] -> TC Typ
checkApp typ []     = return typ
checkApp typ (e:es) = do
  typ' <- unDefTC typ
  case typ' of
    TFun (Arg x t) s -> do
      checkTerm t e
      checkApp (subst1 (x,e) s) es
    _ -> throwError "checkApp: impossible"

debug :: [Msg] -> TC ()
debug xs = do
  v <- view verbosity
  when v $ trace (unlines (map ("[DEBUG]  "++) xs)) (return ())

assert :: Bool -> [Msg] -> TC ()
assert True  _    = return ()
assert False msgs = throwError (unlines msgs)

assertEqual :: Eq a => a -> a -> [Msg] -> TC ()
assertEqual x y = assert (x == y)

data CheckOpts = CheckOpts { _debugChecker :: Bool }

$(makeLenses ''CheckOpts)

defaultCheckOpts :: CheckOpts
defaultCheckOpts = CheckOpts False

runTC :: CheckOpts -> TC a -> Err a
runTC opts tc = runReaderT (unTC tc) (emptyTCEnv & verbosity .~ (opts ^. debugChecker))
