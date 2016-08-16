{-# LANGUAGE ConstraintKinds            #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE Rank2Types                 #-}
{-# LANGUAGE TemplateHaskell            #-}

module Ling.Check.Base where

import           Ling.Equiv
import           Ling.ErrM
import           Ling.Free
import           Ling.Norm
import           Ling.Prelude hiding (subst1)
import           Ling.Print
import           Ling.Reduce
import           Ling.Scoped
import           Ling.Session
import           Ling.Subst   (Subst, substScoped)

import qualified Data.Set     as Set

{----------}
{- TCOpts -}
{----------}

data TCOpts = TCOpts
  { _debugChecker
  , _strictPar :: !Bool
  {- ^ No mix rule, {c,d} means that one can use c before d or
       d before c but not in parallel -}
  }

$(makeLenses ''TCOpts)

defaultTCOpts :: TCOpts
defaultTCOpts = TCOpts False False

{---------}
{- TCEnv -}
{---------}

data TCEnv = TCEnv
  { _tcOpts    :: !TCOpts
  , _evars     :: Map Name Typ
  -- ^ The type of term variables
  -- This includes the types for the defined:
  -- * terms
  -- * data types
  -- * data constructors
  , _edefs     :: Defs
  -- ^ Term definitions
  -- This holds not only the global definitions but also the local
  -- definitions (using `let`). However `local` (from MonadState) is
  -- used to keep the local definitions local.
  -- Type checking should return well-scoped terms. Namely the local
  -- definitions should be part of the definitions within 'Scoped'.
  , _ddefs     :: Map DataTypeName [Name]
  -- ^ Datatypes definitions
  , _ctyps     :: Map ConName DataTypeName
  -- ^ Data constructor ↦ type name
  , _cses      :: Map Channel RSession
  }

makeLenses ''TCEnv

emptyTCEnv :: TCEnv
emptyTCEnv = TCEnv defaultTCOpts ø ø ø ø ø

tcEqEnv :: MonadReader TCEnv m => m EqEnv
tcEqEnv = eqEnv edefs

verbosity :: Lens' TCEnv Verbosity
verbosity = tcOpts . debugChecker

whenDebug :: MonadReader TCEnv m => m () -> m ()
whenDebug f = do
  v <- view verbosity
  when v f

debug :: MonadReader TCEnv m => Msg -> m ()
debug s = do
  v <- view verbosity
  debugTraceWhen v s (return ())

{---------}
{- TCErr -}
{---------}

type TCErr = String

tcError :: MonadError TCErr m => String -> m a
tcError = throwError -- . TCErr

assert :: MonadError TCErr m => Bool -> [Msg] -> m ()
assert True  _    = return ()
assert False msgs = tcError (unlines msgs)

assertDoc :: MonadError TCErr m => Bool -> Doc -> m ()
assertDoc True  _ = return ()
assertDoc False d = tcError (render d)

checkNoDups :: (Print a, Eq a, MonadError TCErr m) => String -> [a] -> m ()
checkNoDups _   [] = return ()
checkNoDups msg (x:xs)
  | x `elem` xs = tcError $ pretty x ++ " appears twice " ++ msg
  | otherwise   = checkNoDups msg xs

checkDisjointness :: (MonadError TCErr m, Ord a) => String -> [Set a] -> m ()
checkDisjointness k ss =
  assert (Set.null rs) ["These " ++ k ++ " should not be used in different parallel parts"]
  where
    rs = redundant ss

checkPrefWellFormness :: MonadError TCErr m => Pref -> m ()
checkPrefWellFormness (Prll pref) = do
  checkDisjointness "free channels"  $ fcAct <$> pref
  checkDisjointness "bound channels" $ bcAct <$> pref
  checkDisjointness "bound names"    $ bvAct <$> pref

-- IsSession could be a type synonym of kind Constraint
class (Eq s, Subst s, Print s, Equiv s, Dual s) => IsSession s
instance IsSession Session
instance IsSession RSession

checkEqSessions :: (IsSession s, MonadTC m, Print channel)
                => channel -> Scoped s -> Scoped s -> m ()
checkEqSessions c s0 s1 =
  checkEquivalence
    ("On channel " ++ pretty c ++ " sessions are not equivalent.")
    "Given session (expanded):" s0
    "Inferred session:"         s1

checkOneR :: MonadError TCErr m => RFactor -> m ()
checkOneR r = assert (r == ø) ["Unexpected replication:", pretty r]

-- Prop: isSource . log = const True
-- A source is only made of sends but can be combined with any form of
-- array: Seq, Par, Ten.
isSource :: (MonadTC m, Print a, Subst a, Eq a, Equiv a, Dual a) => a -> m Bool
isSource x = view _1 <$> isEquiv (pure (sessionOp (constRWOp Write) s)) (pure s)
  where s = sessionOp (constArrOp SeqK) x

isSink :: (MonadTC m, Print a, Subst a, Eq a, Equiv a, Dual a) => a -> m Bool
isSink = isSource . dual

validAx :: (MonadTC m, Print a, Subst a, Eq a, Equiv a, Dual a) => a -> [channel] -> m Bool
-- Forwarding anything between no channels is always possible
validAx _ []          = pure True
-- At least two for the general case
validAx _ (_ : _ : _) = pure True
-- One is enough if the session is a Sink. A sink can be derived
-- alone. Another way to think of it is that in the case of a sink,
-- the other side is a Log and there can be any number of Logs.
validAx s (_ : _)     = isSink s

checkDual :: MonadTC m => [RSession] -> m ()
checkDual [] = pure ()
checkDual [Repl s0 r0, Repl s1 r1] = do
  checkOneR r0
  checkOneR r1
  (b, us0, us1) <- isEquiv (pure s0) (pure (dual s1))
  assertDiff
    "Sessions are not dual." (\_ _ -> b)
    "Given session (expanded):" us0
    "Inferred dual session:"    (dual us1)
checkDual _ = error "checkDual: too many channels"

checkCompat :: MonadTC m => [RSession] -> m ()
checkCompat = checkDual . sessionOp (constArrOp SeqK)

checkSlice :: (Print channel, MonadError TCErr m) => (channel -> Bool) -> channel -> RSession -> m ()
checkSlice cond c (s `Repl` r) = when (cond c) $ do
  checkOneR r
  assert (allSndRcv s) ["checkSlice: non send/recv session on channel " ++ pretty c]

{-----------}
{- MonadTC -}
{-----------}

type MonadTC m = (MonadReader TCEnv m, MonadError TCErr m)

isEquiv :: (Print a, Eq a, Equiv a, Subst a, MonadTC m)
        => Scoped a -> Scoped a -> m (Bool, a, a)
isEquiv t0 t1 = do
  env <- tcEqEnv
  whenDebug $
    when (t0 /= t1) $ do
      debug . unlines $
        ["checkEquivalence:", "  " ++ pretty t0, "against", "  " ++ pretty t1]
      when (ut0 == ut1) . debug . unlines $
        ["Once expanded they are equal:", pretty ut0]
  return (equiv env t0 t1, ut0, ut1)

  where
    ut0 = substScoped t0
    ut1 = substScoped t1

checkEquivalence :: (Print a, Eq a, Equiv a, Subst a, MonadTC m)
                 => String -> String -> Scoped a -> String -> Scoped a -> m ()
checkEquivalence msg expected t0 inferred t1 = do
  (b, ut0, ut1) <- isEquiv t0 t1
  assertDiff msg (\_ _ -> b) expected ut0 inferred ut1

assertDiff :: (MonadError TCErr m, Print a)
           => String -> Rel a
           -> String -> a
           -> String -> a
           -> m ()
assertDiff msg cond expected x0 inferred x1 =
  assert (cond x0 x1) [msg, expected, "  " ++ pretty x0, inferred, "  " ++ pretty x1]

checkTypeEquivalence :: MonadTC m => Typ -> Typ -> m ()
checkTypeEquivalence t0 t1 =
   checkEquivalence "Types are not equivalent."
                    "Expected:" (pure t0)
                    "Inferred:" (pure t1)

checkNotIn :: (Ord name, Print name, MonadTC m) => Getter TCEnv (Map name v) -> String -> name -> m ()
checkNotIn l msg c = do
  b <- view $ l . hasKey c
  assert (not b) ["Already defined " ++ msg ++ ": ", pretty c]

conTypeName :: MonadTC m => Name -> m Name
conTypeName c =
  maybe (tcError $ "No such constructor " ++ pretty c) return =<< view (ctyps . at c)

debugCheck :: MonadTC m => (Err a -> String) -> Endom (m a)
{-debugCheck fmt k =
  (do x <- k
      debug (fmt (Ok x))
      return x
  ) `catchError` \err ->
   do debug (fmt (Bad err))
      throwError err-}
debugCheck fmt = debugCheckM (pure . fmt)

debugCheckM :: MonadTC m => (Err a -> m String) -> Endom (m a)
debugCheckM fmt k =
  (do x <- k
      debug =<< fmt (Ok x)
      return x
  ) `catchError` \err ->
   do debug =<< fmt (Bad err)
      throwError err

errorScope :: (Print name, MonadError TCErr m) => name -> Endom (m a)
errorScope name ma =
  ma `catchError` \err -> throwError (unlines (("While checking `" ++ pretty name ++ "`") : err ^.. indented 2))

{-----------------------}
{- Basic type checking -}
{-----------------------}

literalType :: Literal -> Typ
literalType = \case
  LInteger{} -> intTyp
  LDouble{}  -> doubleTyp
  LChar{}    -> charTyp
  LString{}  -> stringTyp

tcScope :: MonadReader TCEnv m => a -> m (Scoped a)
tcScope a = (\x -> Scoped x ø a) <$> view edefs

caseType :: MonadTC m => Term -> Typ -> [(Name, Typ)] -> m Typ
caseType t ty brs = do
  sty <- reduceTerm <$> tcScope ty
  case sty ^. reduced . scoped of
    Def d [] -> do
      def <- view $ ddefs . at d
      case def of
        Just cs -> do
          assertDiff "Labels are not equal." (==)
                     "Expected:" (Comma (sort cs))
                     "Inferred:" (Comma (fst <$> brs))

          env <- tcEqEnv
          return $ mkCaseBy (equiv env) t brs
        _ -> tcError $ "Case on a non data type: " ++ pretty d
    _ -> tcError $ "Case on a non data type: " ++ pretty ty

def0 :: Name -> Term
def0 x = Def x []

conType :: MonadTC m => Name -> m Typ
conType = fmap def0 . conTypeName



{------}
{- TC -}
{------}

newtype TC a = MkTC { unTC :: ReaderT TCEnv (Except TCErr) a }
  deriving (Functor, Applicative, Alternative, Monad, MonadReader TCEnv, MonadError TCErr)

instance Monoid a => Monoid (TC a) where
  mempty = pure mempty
  mappend = liftM2 mappend

runTC :: TCOpts -> TC a -> Err a
runTC opts tc = either Bad Ok
              . runExcept
              . runReaderT (unTC tc)
              $ emptyTCEnv & tcOpts .~ opts
-- -}
